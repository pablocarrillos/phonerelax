module Admin
  # Estadísticas de ventas: pedidos cobrados agrupados por día, semana y mes.
  class StatsController < BaseController
    DAYS = 14
    WEEKS = 12
    MONTHS = 12

    def show
      sales = paid_sales
      today = Date.current

      @totals = {
        today: totals_for(sales.select { |s| s[:on] == today }),
        week: totals_for(sales.select { |s| s[:on] >= today.beginning_of_week }),
        month: totals_for(sales.select { |s| s[:on] >= today.beginning_of_month }),
        all: totals_for(sales)
      }

      @daily   = series(sales, (DAYS - 1).downto(0).map { |n| today - n }) { |d| d }
      @weekly  = series(sales, (WEEKS - 1).downto(0).map { |n| (today - (n * 7)).beginning_of_week }) { |d| d.beginning_of_week }
      @monthly = series(sales, (MONTHS - 1).downto(0).map { |n| (today << n).beginning_of_month }) { |d| d.beginning_of_month }

      @top_products = top_products
    end

    private

    # Una venta por pedido cobrado: fecha del cobro (evento «pagado», o la de
    # creación si faltara), ingreso neto tras reembolsos y unidades.
    def paid_sales
      Order.where(payment_status: [ :pagado, :reembolsado ])
           .includes(:order_events, :order_lines)
           .map do |order|
        paid_at = order.order_events.find { |e| e.event.start_with?("pagado") }&.created_at || order.created_at
        { on: paid_at.to_date, net: order.total.to_d - order.refunded_amount, units: order.order_lines.sum(&:quantity) }
      end
    end

    def totals_for(sales)
      { orders: sales.size, units: sales.sum { |s| s[:units] }, revenue: sales.sum { |s| s[:net] } }
    end

    # Devuelve [etiqueta_del_periodo, totales] para cada periodo pedido, a cero
    # cuando no hubo ventas.
    def series(sales, buckets, &key)
      grouped = sales.group_by { |s| key.call(s[:on]) }
      buckets.map { |b| [ b, totals_for(grouped.fetch(b, [])) ] }
    end

    # Los 5 productos más vendidos (unidades e ingresos brutos por líneas).
    def top_products
      Order.where(payment_status: [ :pagado, :reembolsado ])
           .joins(order_lines: :product)
           .group("products.name")
           .order(Arel.sql("SUM(order_lines.quantity) DESC"))
           .limit(5)
           .pluck(Arel.sql("products.name, SUM(order_lines.quantity), SUM(order_lines.quantity * order_lines.unit_price)"))
    end
  end
end
