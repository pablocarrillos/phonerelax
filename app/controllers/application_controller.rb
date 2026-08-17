class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale
  before_action :remember_or_detect_locale

  helper_method :cart_items_count

  # Rastreadores y previsualizadores: ni se les redirige por idioma ni se les
  # deja cookie (Google debe ver cada URL en el idioma que indica su prefijo).
  BOT_UA = /bot|crawl|spider|slurp|facebookexternalhit|whatsapp|telegram|linkedin|preview|lighthouse|headless|curl|wget/i
  LOCALE_FALLBACK = "en" # navegador en un idioma que no tenemos → inglés

  private

  # Idioma por defecto del visitante. Solo en las rutas públicas localizadas
  # (las que llevan :locale), en GET html:
  #  - ?hl=xx (selector de idioma): elección explícita → cookie y a la URL de ese idioma.
  #  - URL con prefijo (/fr/…): ese idioma queda como preferido en la cookie.
  #  - URL española (sin prefijo): si hay cookie con otro idioma, o si es la
  #    primera visita y el navegador (Accept-Language) prefiere otro, se
  #    redirige a la misma página en ese idioma; idioma desconocido → inglés.
  #    Sin cabecera (curl, bots) se queda en español.
  def remember_or_detect_locale
    return unless request.get? && html_like_request? && request.path_parameters.key?(:locale)

    if (chosen = params[:hl].to_s.presence) && locale_available?(chosen)
      cookies.permanent[:locale] = chosen
      return redirect_to(localized_current_path(chosen) || root_path)
    end

    current = params[:locale].to_s
    if current != I18n.default_locale.to_s
      cookies.permanent[:locale] = current unless bot?
      return
    end

    preferred = cookies[:locale].presence
    unless preferred
      return if bot?

      preferred = preferred_locale_from_browser or return
      cookies.permanent[:locale] = preferred
    end
    return if preferred == I18n.default_locale.to_s || !locale_available?(preferred)

    target = localized_current_path(preferred) or return
    redirect_to target
  end

  # Peticiones de página (Accept text/html o */*), no fetch/JSON.
  def html_like_request?
    !request.xhr? && (request.format.html? || request.format == Mime::ALL)
  end

  def bot?
    BOT_UA.match?(request.user_agent.to_s)
  end

  def locale_available?(locale)
    I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end

  # Idioma preferido según Accept-Language: el primero (por peso q) que
  # tengamos; si el navegador solo pide idiomas que no tenemos, inglés; sin
  # cabecera, nil (no se toca nada).
  def preferred_locale_from_browser
    header = request.headers["Accept-Language"].to_s
    return nil if header.blank?

    langs = header.split(",").filter_map do |part|
      tag, q = part.strip.split(";q=")
      next if tag.blank? || tag == "*"

      [ tag.downcase.split("-").first, (q || "1").to_f ]
    end
    return nil if langs.empty?

    langs.sort_by { |_, q| -q }.map(&:first).find { |lang| locale_available?(lang) } || LOCALE_FALLBACK
  end

  # La página actual en el idioma dado (misma ruta, prefijo/segmentos de ese
  # idioma, misma query menos hl); nil si no se puede construir.
  def localized_current_path(locale)
    path = url_for(request.path_parameters.merge(locale: locale.to_s, only_path: true))
    query = request.query_parameters.except("hl")
    query.empty? ? path : "#{path}?#{query.to_query}"
  rescue StandardError
    nil
  end

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
