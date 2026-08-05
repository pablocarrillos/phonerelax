class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend
  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale

  helper_method :cart_items_count

  private

  # Fija el idioma a partir del prefijo de la URL (:locale). Sin prefijo → español.
  def switch_locale(&action)
    locale = params[:locale].to_s
    locale = I18n.default_locale unless I18n.available_locales.map(&:to_s).include?(locale)
    I18n.with_locale(locale, &action)
  end

  # Hace que los path/url helpers usen la variante traducida del idioma activo
  # (con route_translator cada ruta pública existe una vez por idioma; el
  # español va sin prefijo). Para el idioma por defecto no se pasa nada, así
  # las rutas no localizadas (admin, sesión…) no arrastran ?locale.
  def default_url_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale.to_s }
  end

  # Carrito en sesión: { "product_id" => cantidad }
  def cart
    session[:cart] ||= {}
  end

  def cart_items_count
    cart.values.sum
  end
end
