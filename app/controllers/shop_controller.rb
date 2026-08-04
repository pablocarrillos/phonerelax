class ShopController < ApplicationController
  allow_unauthenticated_access

  def home
    @products = Product.active.ordered
    @posts = Post.recent_first.limit(3)
  end

  def product
    # Busca por slug (handle) y, para no romper enlaces antiguos, por id numérico.
    @product = Product.active.find_by_param!(params[:id])

    # Redirige 301 de la URL antigua (/producto/1) a la canónica con slug.
    if params[:id] != @product.to_param
      redirect_to product_page_path(@product), status: :moved_permanently
    end
  end

  # Desglose y totales de un pack para una cantidad de packs (JSON), usado para
  # recalcular la ficha en vivo al cambiar la cantidad.
  def pack_price
    product = Product.active.find_by_param!(params[:id])
    max = product.available_stock
    qty = params[:quantity].to_i.clamp(1, [ max, 1 ].max)
    rows = product.pack_breakdown_for(qty)
    base_total = rows.sum { |r| r[:base_total] }
    pack_total = rows.sum { |r| r[:line_total] }
    saving = rows.sum { |r| r[:saving] }
    pct = base_total.positive? ? (saving / base_total * 100) : 0

    render json: {
      quantity: qty,
      available: max,
      rows: rows.map { |r| {
        units: r[:units],
        base_total: fmt_eur(r[:base_total]),
        line_total: fmt_eur(r[:line_total]),
        saving: saving_text(r[:saving], r[:discount_pct])
      } },
      total_base: fmt_eur(base_total),
      total_pack: fmt_eur(pack_total),
      total_saving: saving_text(saving, pct),
      has_saving: saving.positive?,
      saving_note: saving.positive? ? t("product.pack_saving_total", amount: fmt_eur(saving)) : ""
    }
  end

  private

  def fmt_eur(amount)
    helpers.number_to_currency(amount, unit: "€", format: "%n %u")
  end

  def saving_text(amount, pct)
    amount.positive? ? "#{fmt_eur(amount)} (#{helpers.number_to_percentage(pct, precision: 1)})" : "—"
  end
end
