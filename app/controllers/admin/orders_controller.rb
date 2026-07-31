module Admin
  class OrdersController < BaseController
    def index
      @status = params[:status].presence_in(Order.statuses.keys)
      @payment = params[:payment].presence_in(Order.payment_statuses.keys)
      @query = params[:q].to_s.strip

      orders = Order.includes(order_lines: :product).recent_first
      orders = orders.where(status: @status) if @status
      orders = orders.where(payment_status: @payment) if @payment
      orders = orders.search(@query) if @query.present?

      @counts = Order.group(:status).count
      @pagy, @orders = pagy(orders)
    end

    def show
      @order = Order.includes(order_lines: :product).find(params[:id])
    end

    # Reenvía al cliente el aviso de pago pendiente (acción manual del admin).
    def payment_reminder
      order = Order.find(params[:id])
      if order.pago_pendiente?
        OrderMailer.payment_reminder(order).deliver_later
        redirect_to admin_order_path(order), notice: "Recordatorio de pago enviado a #{order.email}."
      else
        redirect_to admin_order_path(order), alert: 'Este pedido ya está pagado.'
      end
    end

    # Avanza el estado logístico: creado → enviado → recibido.
    def advance
      order = Order.find(params[:id])
      if order.next_status
        order.advance_status!
        redirect_back fallback_location: admin_order_path(order), notice: "Pedido #{order.number} marcado como #{order.status}."
      else
        redirect_back fallback_location: admin_order_path(order), alert: 'El pedido ya está recibido.'
      end
    end
  end
end
