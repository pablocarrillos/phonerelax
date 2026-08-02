module ApplicationHelper
  include Pagy::Frontend

  # Descripción por defecto (fallback si falta la clave i18n common.site_description).
  DEFAULT_META_DESCRIPTION =
    'PhoneRelax: bolsas y fundas magnéticas para guardar y bloquear la señal del ' \
    'móvil en aulas, eventos y espacios sin distracciones. Envío a toda España.'.freeze

  # Imagen por defecto para Open Graph (previews en redes y en respuestas de IA).
  DEFAULT_OG_IMAGE = '/images/site/alumnos-en-clase.jpg'.freeze

  # --- Meta / canonical / Open Graph -------------------------------------

  def meta_description
    (content_for(:description).presence || t('common.site_description', default: DEFAULT_META_DESCRIPTION)).to_s.strip
  end

  # Base del dominio canónico. Configurable con CANONICAL_HOST (p. ej.
  # "https://phonerelax.com"); si no, se usa el dominio que sirve la petición.
  # Código idioma-región para hreflang/inLanguage (es-ES, pt-PT).
  def locale_region
    { es: 'es-ES', pt: 'pt-PT', en: 'en' }[I18n.locale] || 'es-ES'
  end

  # Dominio canónico del sitio (sin www). Se puede sobreescribir con CANONICAL_HOST.
  def canonical_base
    ENV['CANONICAL_HOST'].presence || 'https://phonerelax.com'
  end

  def canonical_url
    "#{canonical_base}#{request.path}"
  end

  # URL absoluta de la página actual en el idioma dado (para hreflang y el selector
  # de idioma). El idioma por defecto va sin prefijo. Devuelve nil si no se puede
  # regenerar la ruta (p. ej. acciones sin GET).
  def locale_url(locale)
    # Si la página define rutas equivalentes por idioma (p. ej. un post del blog con
    # slug propio en cada idioma), se usan esas; si no, se regenera la ruta actual.
    if @localized_paths && (path = @localized_paths[locale.to_sym])
      return absolute_url(path)
    end

    loc = (locale.to_sym == I18n.default_locale ? nil : locale)
    absolute_url(url_for(locale: loc, only_path: true))
  rescue StandardError
    nil
  end

  # Convierte una ruta relativa en URL absoluta (deja intactas las ya absolutas).
  def absolute_url(path)
    return path if path.blank? || path.start_with?('http://', 'https://')

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
               .gsub('<', "#{bs}u003c")
               .gsub('>', "#{bs}u003e")
               .gsub('&', "#{bs}u0026")
    content_tag(:script, json.html_safe, type: 'application/ld+json')
  end

  # Organización + sitio web (se emiten en el <head> de todas las páginas).
  def site_schema
    {
      '@context' => 'https://schema.org',
      '@graph' => [
        {
          '@type' => 'Organization',
          '@id' => "#{canonical_base}/#organization",
          'name' => 'PhoneRelax',
          'url' => "#{canonical_base}/",
          'logo' => absolute_url('/icon.svg'),
          'email' => 'info@phonerelax.com',
          'description' => t('common.site_description', default: DEFAULT_META_DESCRIPTION)
        },
        {
          '@type' => 'WebSite',
          '@id' => "#{canonical_base}/#website",
          'url' => "#{canonical_base}/",
          'name' => 'PhoneRelax',
          'inLanguage' => locale_region,
          'publisher' => { '@id' => "#{canonical_base}/#organization" }
        }
      ]
    }
  end

  # Migas de pan: recibe pares [nombre, ruta] y devuelve el hash BreadcrumbList.
  def breadcrumb_schema(items)
    {
      '@context' => 'https://schema.org',
      '@type' => 'BreadcrumbList',
      'itemListElement' => items.each_with_index.map do |(name, path), i|
        { '@type' => 'ListItem', 'position' => i + 1, 'name' => name,
          'item' => absolute_url(path) }
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
    content_tag(:nav, class: 'breadcrumbs', 'aria-label': t('common.breadcrumb')) do
      content_tag(:ol) do
        safe_join(items.each_with_index.map do |(name, path), i|
          content = if i == items.size - 1
                      content_tag(:span, name, 'aria-current': 'page')
                    else
                      link_to(name, path)
                    end
          content_tag(:li, content)
        end)
      end
    end
  end
end
