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

  # Hace que los path/url helpers añadan el prefijo /pt automáticamente cuando el
  # idioma activo no es el por defecto (el español va sin prefijo).
  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end

  # Carrito en sesión: { "product_id" => cantidad }
  def cart
    session[:cart] ||= {}
  end

  def cart_items_count
    cart.values.sum
  end
end
