module Admin
  class OrdersController < BaseController
    def index
      @status = params[:status].presence_in(Order.statuses.keys)
      @payment = params[:payment].presence_in(Order.payment_statuses.keys)
      @query = params[:q].to_s.strip
      @from = parse_date(params[:from])
      @to = parse_date(params[:to])
      @stale = params[:stale].present?

      orders = filtered_orders

      respond_to do |format|
        format.html do
          @counts = Order.group(:status).count
          @summary = {
            pending_payment: Order.pago_pendiente.count,
            to_ship: Order.pago_pagado.creado.count,
            stale_unpaid: Order.stale_unpaid.count,
            revenue: Order.pago_pagado.sum(:total)
          }
          # Tamaño de página a elegir (25/50/100; 25 por defecto).
          @per = params[:per].to_i.then { |n| [ 25, 50, 100 ].include?(n) ? n : 25 }
          @pagy, @orders = pagy(orders, limit: @per)
          @invoices_by_order = Invoice.where(order_id: @orders.map(&:id)).index_by(&:order_id)
        end
        format.csv do
          send_data orders_to_csv(orders), type: "text/csv; charset=utf-8",
                                           filename: "pedidos-#{Date.current.iso8601}.csv"
        end
      end
    end

    def show
      @order = Order.includes(order_lines: :product).find(params[:id])
    end

    # Albarán imprimible del pedido (página autónoma para imprimir/PDF).
    def packing_slip
      @order = Order.includes(order_lines: :product).find(params[:id])
      render layout: false
    end

    # Guarda las notas internas del pedido.
    def update
      order = Order.find(params[:id])
      order.update(admin_notes: params.require(:order).permit(:admin_notes)[:admin_notes])
      redirect_to admin_order_path(order), notice: "Notas guardadas."
    end

    # Envía al almacén el aviso de envío con la etiqueta A5 adjunta.
    def shipping_email
      order = Order.includes(order_lines: :product).find(params[:id])
      OrderMailer.shipping_request(order).deliver_later
      order.update_column(:shipping_email_sent_at, Time.current)
      order.order_events.create!(event: "aviso de envío al almacén")
      redirect_to admin_order_path(order),
                  notice: "Aviso de envío del pedido #{order.number} enviado a #{OrderMailer::SHIPPING_RECIPIENTS.join(' y ')} " \
                          "(copia a #{OrderMailer::SHIPPING_CC.join(' y ')})."
    end

    # Registra un cobro recibido fuera de Stripe (transferencia, efectivo…).
    def mark_paid
      order = Order.find(params[:id])
      if order.pago_pagado?
        redirect_to admin_order_path(order), alert: "Este pedido ya está pagado."
      else
        order.mark_paid!(manual: true)
        redirect_to admin_order_path(order), notice: "Pedido #{order.number} marcado como pagado (cobro manual)."
      end
    end

    # Emite la factura del pedido (simplificada por defecto; completa si el
    # cliente pidió factura con datos fiscales). Idempotente.
    def generate_invoice
      order = Order.find(params[:id])
      invoice = Invoice.issue_for_order!(order)
      redirect_to admin_order_path(order), notice: "Factura #{invoice.number} generada."
    rescue ArgumentError => e
      redirect_to admin_order_path(order), alert: e.message
    end

    # Emite en lote las facturas de los pedidos marcados (simplificada por
    # defecto; completa si el pedido lleva datos fiscales). Idempotente: los ya
    # facturados no se duplican y los no pagados se omiten.
    def generate_invoices
      ids = Array(params[:order_ids]).map(&:to_i).reject(&:zero?)
      return redirect_back(fallback_location: admin_orders_path, alert: "Marca al menos un pedido.") if ids.empty?

      generated = 0
      existing = 0
      skipped = 0
      Order.where(id: ids).find_each do |order|
        invoice = Invoice.issue_for_order!(order)
        invoice.previously_new_record? ? generated += 1 : existing += 1
      rescue ArgumentError
        skipped += 1
      end

      parts = [ "#{generated} factura(s) generada(s)" ]
      parts << "#{existing} ya estaban emitidas" if existing.positive?
      parts << "#{skipped} sin pagar, omitidos" if skipped.positive?
      redirect_back fallback_location: admin_orders_path, notice: "#{parts.join(' · ')}."
    end

    # Emite la rectificativa íntegra (en negativo) de la factura del pedido.
    def rectify_invoice
      order = Order.find(params[:id])
      invoice = Invoice.find_by(order: order)
      return redirect_to(admin_order_path(order), alert: "Este pedido no tiene factura que rectificar.") if invoice.nil?

      rectification = Invoice.issue_rectification!(invoice)
      redirect_to admin_order_path(order),
                  notice: "Rectificativa #{rectification.number} emitida sobre la factura #{invoice.number}."
    rescue ArgumentError => e
      redirect_to admin_order_path(order), alert: e.message
    end

    # Deshace el último avance de estado (p. ej. si se marcó enviado por error).
    def revert
      order = Order.find(params[:id])
      if order.previous_status
        order.revert_status!
        redirect_to admin_order_path(order), notice: "Pedido #{order.number} revertido a #{order.status}."
      else
        redirect_to admin_order_path(order), alert: "El pedido está en el primer estado."
      end
    end


    # Reembolsa el importe indicado (total o parcial). Los pagos de Stripe se
    # devuelven a la tarjeta; los cobros manuales solo se registran.
    def refund
      order = Order.find(params[:id])
      amount = params[:amount].to_s.tr(",", ".")
      order.refund!(amount)
      if order.pago_reembolsado?
        redirect_to admin_order_path(order), notice: "Pedido #{order.number} reembolsado por completo."
      else
        redirect_to admin_order_path(order), notice: "Reembolso parcial realizado; quedan #{format('%.2f', order.refundable_amount)} € cobrados."
      end
    rescue ArgumentError => e
      redirect_to admin_order_path(order), alert: e.message
    rescue Stripe::StripeError => e
      redirect_to admin_order_path(order), alert: "Stripe rechazó el reembolso: #{e.message}"
    end

    # Borra el pedido devolviendo el stock descontado. No reembolsa nada.
    def destroy
      order = Order.find(params[:id])
      number = order.number
      order.destroy_restoring_stock!
      redirect_to admin_orders_path, notice: "Pedido #{number} borrado."
    end

    # Envía al cliente el recordatorio de carrito/pago (acción manual del admin).
    # Solo uno por pedido: si ya lo recibió (a mano o por el cron) no se repite.
    def payment_reminder
      order = Order.find(params[:id])
      if !order.pago_pendiente?
        redirect_to admin_order_path(order), alert: "Este pedido ya está pagado."
      elsif order.payment_reminder_sent?
        sent_on = I18n.l(order.payment_reminder_sent_at, format: "%d/%m/%Y a las %H:%M")
        redirect_to admin_order_path(order), alert: "Este pedido ya recibió su recordatorio de carrito el #{sent_on}. Solo se envía uno."
      else
        order.send_payment_reminder!
        redirect_to admin_order_path(order), notice: "Recordatorio de pago enviado a #{order.email}."
      end
    end

    # Avanza el estado logístico: creado → enviado → entregado.
    # Al pasar a "enviado" acepta transportista y nº de seguimiento (opcionales).
    def advance
      order = Order.find(params[:id])
      if order.next_status
        order.advance_status!(tracking_number: params[:tracking_number],
                              tracking_carrier: params[:tracking_carrier])
        redirect_back fallback_location: admin_order_path(order), notice: "Pedido #{order.number} marcado como #{order.status}."
      else
        message = if order.pago_reembolsado? then "Un pedido reembolsado no se puede marcar como enviado."
        elsif order.pago_pendiente? then "Un pedido sin pagar no se puede marcar como enviado."
        else "El pedido ya está entregado."
        end
        redirect_back fallback_location: admin_order_path(order), alert: message
      end
    end

    private

    def filtered_orders
      orders = Order.includes(order_lines: :product).recent_first
      orders = orders.where(status: @status) if @status
      orders = orders.where(payment_status: @payment) if @payment
      orders = orders.search(@query) if @query.present?
      orders = orders.where(created_at: @from.beginning_of_day..) if @from
      orders = orders.where(created_at: ..@to.end_of_day) if @to
      orders = orders.stale_unpaid if @stale
      orders
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end

    def orders_to_csv(orders)
      CSV.generate(headers: true) do |csv|
        csv << [ "Número", "Fecha", "Cliente", "Email", "Teléfono", "Dirección", "CP", "Ciudad",
                "Provincia", "País", "Idioma", "Pago", "Cobro manual", "Estado", "Transportista",
                "Nº seguimiento", "Transporte", "Total" ]
        orders.each do |o|
          csv << [ o.number, o.created_at.strftime("%Y-%m-%d %H:%M"), o.customer_name, o.email, o.phone,
                  o.address, o.postal_code, o.city, o.province, o.country, o.locale, o.payment_status,
                  (o.paid_manually? ? "sí" : ""), o.status, o.tracking_carrier, o.tracking_number,
                  o.shipping_cost, o.total ]
        end
      end
    end
  end
end
