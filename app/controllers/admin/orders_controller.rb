module Admin
  class OrdersController < BaseController
    def index
      @status = params[:status].presence_in(Order.statuses.keys)
      @orders = Order.includes(order_lines: :product).recent_first
      @orders = @orders.where(status: @status) if @status
      @counts = Order.group(:status).count
    end

    def show
      @order = Order.includes(order_lines: :product).find(params[:id])
    end

    # Avanza el estado logístico: creado → enviado → recibido.
    def advance
      order = Order.find(params[:id])
      if order.next_status
        order.update!(status: order.next_status)
        redirect_back fallback_location: admin_order_path(order), notice: "Pedido #{order.number} marcado como #{order.status}."
      else
        redirect_back fallback_location: admin_order_path(order), alert: 'El pedido ya está recibido.'
      end
    end
  end
end
