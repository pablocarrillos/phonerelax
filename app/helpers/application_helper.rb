module ApplicationHelper
  include Pagy::Frontend

  # Descripción por defecto (fallback si falta la clave i18n common.site_description).
  DEFAULT_META_DESCRIPTION =
    "PhoneRelax: bolsas y fundas magnéticas para guardar y bloquear la señal del " \
    "móvil en aulas, eventos y espacios sin distracciones. Envío a toda España.".freeze

  # Imagen por defecto para Open Graph (previews en redes y en respuestas de IA).
  DEFAULT_OG_IMAGE = "/images/site/alumnos-en-clase.jpg".freeze

  # Ejemplos reales de personalización (fotos de bolsas con la marca del cliente).
  # Se muestran en la galería de /presupuesto solo si el archivo existe en
  # public/images/personalizacion/, así que basta con dejar ahí la foto.
  CUSTOMIZATION_EXAMPLES = [
    { file: "kensington-school.jpg",    name: "Kensington School" },
    { file: "colegio-norfolk.jpg",      name: "Colegio Norfolk" },
    { file: "colegio-san-fernando.jpg", name: "Colegio San Fernando" },
    { file: "montcau-la-mola.jpg",      name: "Escola Montcau-La Mola" },
    { file: "salvador-de-madariaga.jpg", name: "IES Salvador de Madariaga" },
    { file: "colegio-villalkor.jpg",    name: "Colegio Villalkor" },
    { file: "phonerelax-basica.jpg",    name: "PhoneRelax" }
  ].freeze

  def customization_examples
    CUSTOMIZATION_EXAMPLES.select do |ex|
      File.exist?(Rails.root.join("public", "images", "personalizacion", ex[:file]))
    end
  end

  # Centros que ya usan PhoneRelax (prueba social). Son clientes reales; se
  # muestran como texto, así que no dependen de que exista la foto.
  TRUSTED_CLIENTS = [
    "Kensington School", "Colegio Norfolk", "Colegio San Fernando", "Escola Montcau-La Mola",
    "Colegio Villalkor", "IES Salvador de Madariaga", "Ayuntamiento de Las Rozas", "Ayuntamiento de Peñíscola"
  ].freeze

  def trusted_clients
    TRUSTED_CLIENTS
  end

  # Logo del centro si existe en public/images/logos/<slug>.(svg|png|webp|jpg),
  # p. ej. "Colegio Norfolk" -> images/logos/colegio-norfolk.svg; si no, nil y
  # la vista muestra el nombre en texto como hasta ahora.
  def trusted_client_logo(name)
    slug = name.parameterize
    %w[svg png webp jpg].each do |ext|
      relative = "images/logos/#{slug}.#{ext}"
      return "/#{relative}" if Rails.public_path.join(relative).exist?
    end
    nil
  end

  # --- Meta / canonical / Open Graph -------------------------------------

  def meta_description
    (content_for(:description).presence || t("common.site_description", default: DEFAULT_META_DESCRIPTION)).to_s.strip
  end

  # Base del dominio canónico. Configurable con CANONICAL_HOST (p. ej.
  # "https://phonerelax.com"); si no, se usa el dominio que sirve la petición.
  # Código idioma-región para hreflang/inLanguage (es-ES, pt-PT).
  def locale_region
    { es: "es-ES", pt: "pt-PT", en: "en", fr: "fr", de: "de" }[I18n.locale] || "es-ES"
  end

  # Dominio canónico del sitio (sin www). Se puede sobreescribir con CANONICAL_HOST.
  def canonical_base
    ENV["CANONICAL_HOST"].presence || "https://phonerelax.com"
  end

  def canonical_url
    "#{canonical_base}#{request.path}"
  end

  # Bandera y nombre nativo de cada idioma, para el selector con dropdown.
  LOCALE_FLAGS = { "es" => "🇪🇸", "pt" => "🇵🇹", "en" => "🇬🇧", "fr" => "🇫🇷", "de" => "🇩🇪" }.freeze
  LOCALE_NAMES = { "es" => "Español", "pt" => "Português", "en" => "English", "fr" => "Français", "de" => "Deutsch" }.freeze

  def locale_flag(locale)
    LOCALE_FLAGS[locale.to_s] || "🏳️"
  end

  def locale_name(locale)
    LOCALE_NAMES[locale.to_s] || locale.to_s.upcase
  end

  # Bandera emoji de un código de país ISO (ES → 🇪🇸), vía indicadores regionales.
  def country_flag(iso)
    iso.to_s.upcase.chars.map { |c| c.ord + 127397 }.pack("U*")
  end

  # Ruta (relativa al host) de la página actual en el idioma dado. Se usa en el
  # SELECTOR DE IDIOMA para que la navegación se quede en el mismo host — así en
  # local no salta a producción. El idioma por defecto va sin prefijo. Devuelve
  # nil si no se puede regenerar la ruta (p. ej. acciones sin GET).
  def locale_path(locale)
    # Si la página define rutas equivalentes por idioma (p. ej. un post del blog con
    # slug propio en cada idioma), se usan esas; si no, se regenera la ruta actual
    # con los MISMOS parámetros pero la variante traducida del idioma pedido
    # (cada ruta pública existe una vez por idioma vía route_translator).
    if @localized_paths && (path = @localized_paths[locale.to_sym])
      return path
    end

    url_for(request.path_parameters.merge(locale: locale.to_s, only_path: true))
  rescue StandardError
    nil
  end

  # URL ABSOLUTA de la página actual en el idioma dado (para hreflang y Open
  # Graph, donde el buscador exige URLs absolutas con el dominio canónico).
  def locale_url(locale)
    path = locale_path(locale)
    path && absolute_url(path)
  end

  # Convierte una ruta relativa en URL absoluta (deja intactas las ya absolutas).
  def absolute_url(path)
    return path if path.blank? || path.start_with?("http://", "https://")

    "#{canonical_base}#{path.start_with?('/') ? '' : '/'}#{path}"
  end

  def og_image_url
    absolute_url(content_for(:og_image).presence || DEFAULT_OG_IMAGE)
  end

  # --- Datos estructurados (JSON-LD, schema.org) -------------------------

  # Emite un <script type="application/ld+json"> con el hash dado, escapando
  # los caracteres que podrían romper el contexto HTML (XSS-safe).
  def json_ld_tag(data)
    data = data.compact if data.is_a?(Hash)
    bs = 92.chr # backslash, para emitir escapes \u00XX seguros dentro de <script>
    json = data.to_json
               .gsub("<", "#{bs}u003c")
               .gsub(">", "#{bs}u003e")
               .gsub("&", "#{bs}u0026")
    content_tag(:script, json.html_safe, type: "application/ld+json")
  end

  # Organización + sitio web (se emiten en el <head> de todas las páginas).
  def site_schema
    {
      "@context" => "https://schema.org",
      "@graph" => [
        {
          "@type" => "Organization",
          "@id" => "#{canonical_base}/#organization",
          "name" => "PhoneRelax",
          "url" => "#{canonical_base}/",
          "logo" => absolute_url("/icon.svg"),
          "email" => "info@phonerelax.com",
          "description" => t("common.site_description", default: DEFAULT_META_DESCRIPTION)
        },
        {
          "@type" => "WebSite",
          "@id" => "#{canonical_base}/#website",
          "url" => "#{canonical_base}/",
          "name" => "PhoneRelax",
          "inLanguage" => locale_region,
          "publisher" => { "@id" => "#{canonical_base}/#organization" }
        }
      ]
    }
  end

  # Migas de pan: recibe pares [nombre, ruta] y devuelve el hash BreadcrumbList.
  def breadcrumb_schema(items)
    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map do |(name, path), i|
        { "@type" => "ListItem", "position" => i + 1, "name" => name,
          "item" => absolute_url(path) }
      end
    }
  end

  # Texto plano (sin HTML) y recortado, para descripciones de meta/JSON-LD.
  def plain_summary(html, length: 300)
    strip_tags(html.to_s).squish.truncate(length)
  end

  # Migas de pan visibles. `items` es [[nombre, ruta], ...]; el último es la
  # página actual (sin enlace). Combínalo con breadcrumb_schema para el JSON-LD.
  def render_breadcrumbs(items)
    content_tag(:nav, class: "breadcrumbs", 'aria-label': t("common.breadcrumb")) do
      content_tag(:ol) do
        safe_join(items.each_with_index.map do |(name, path), i|
          content = if i == items.size - 1
                      content_tag(:span, name, 'aria-current': "page")
          else
                      link_to(name, path)
          end
          content_tag(:li, content)
        end)
      end
    end
  end
  # Dimensiones (ancho x alto) de una imagen subida a Active Storage (servicio
  # Disk), leyendo solo la cabecera del fichero. nil si no se pueden obtener.
  def attached_image_dims(attachment)
    blob = attachment.blob
    return nil unless blob.service.respond_to?(:path_for, true)

    FastImage.size(blob.service.send(:path_for, blob.key))
  rescue StandardError
    nil
  end

  # Importe de una compra en su moneda y, si es en dólares con tipo de cambio
  # fijado, también su equivalente en euros. Sin saltos de línea entre número
  # y símbolo (NBSP + nowrap).
  def purchase_amount(purchase, amount)
    sym = purchase.usd? ? "$" : "€"
    parts = [ tag.span(number_to_currency(amount, unit: sym, format: "%n %u"), style: "white-space:nowrap") ]
    if purchase.usd? && purchase.exchange_rate.present?
      parts << tag.span("(#{number_to_currency(amount * purchase.eur_rate, unit: "€", format: "%n %u")})", class: "dual-eur")
    end
    safe_join(parts, " ")
  end
end
