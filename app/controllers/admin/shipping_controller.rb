module Admin
  # Configuración del transporte: base por país de la UE y coste por unidad
  # de cada producto.
  class ShippingController < BaseController
    def show
      @rates = Order::EU_COUNTRIES.index_with { |country| ShippingRate.base_for(country) }
      @products = Product.ordered
    end

    def update
      if params[:rates].present?
        params[:rates].each do |country, base|
          next unless Order::EU_COUNTRIES.include?(country)

          ShippingRate.find_or_initialize_by(country: country).update!(base_cost: base.to_s.tr(",", "."))
        end
        redirect_to admin_shipping_path, notice: "Tarifas por país guardadas."
      elsif params[:product_costs].present?
        params[:product_costs].each do |id, cost|
          Product.find(id).update!(shipping_unit_cost: cost.to_s.tr(",", "."))
        end
        redirect_to admin_shipping_path, notice: "Costes por producto guardados."
      else
        redirect_to admin_shipping_path
      end
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_shipping_path, alert: e.record.errors.full_messages.to_sentence
    end
  end
end
