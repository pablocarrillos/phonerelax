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
          @pagy, @orders = pagy(orders)
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

    # Reenvía al cliente el aviso de pago pendiente (acción manual del admin).
    def payment_reminder
      order = Order.find(params[:id])
      if order.pago_pendiente?
        OrderMailer.payment_reminder(order).deliver_later
        redirect_to admin_order_path(order), notice: "Recordatorio de pago enviado a #{order.email}."
      else
        redirect_to admin_order_path(order), alert: "Este pedido ya está pagado."
      end
    end

    # Avanza el estado logístico: creado → enviado → recibido.
    # Al pasar a "enviado" acepta transportista y nº de seguimiento (opcionales).
    def advance
      order = Order.find(params[:id])
      if order.next_status
        order.advance_status!(tracking_number: params[:tracking_number],
                              tracking_carrier: params[:tracking_carrier])
        redirect_back fallback_location: admin_order_path(order), notice: "Pedido #{order.number} marcado como #{order.status}."
      else
        redirect_back fallback_location: admin_order_path(order), alert: "El pedido ya está recibido."
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
