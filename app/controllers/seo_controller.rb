class SeoController < ApplicationController
  allow_unauthenticated_access

  # /robots.txt — permite el rastreo del contenido público, bloquea las áreas
  # privadas/transaccionales y da la bienvenida explícita a los crawlers de IA.
  def robots
    render plain: robots_txt, content_type: "text/plain"
  end

  # /sitemap.xml — multilingüe: cada página en es/pt/en con anotaciones hreflang.
  def sitemap
    @entries = sitemap_entries
    render layout: false, content_type: "application/xml"
  end

  # /llms.txt — resumen curado del sitio para modelos de IA (llmstxt.org).
  def llms
    render plain: llms_txt, content_type: "text/plain"
  end

  private

  def canonical_base
    ENV["CANONICAL_HOST"].presence || "https://phonerelax.com"
  end
  helper_method :canonical_base

  # Prefijo de idioma en la ruta (el español, por defecto, va sin prefijo).
  def locale_prefix(locale)
    locale == I18n.default_locale ? "" : "/#{locale}"
  end

  # Una entrada del sitemap: URLs absolutas de la página en cada idioma.
  # `path_for` recibe el locale y devuelve la ruta (sin dominio) en ese idioma.
  def sitemap_entry(lastmod: nil, priority: nil, changefreq: nil, &path_for)
    urls = I18n.available_locales.index_with { |loc| "#{canonical_base}#{path_for.call(loc)}" }
    { urls: urls, lastmod: lastmod, priority: priority, changefreq: changefreq }
  end

  def sitemap_entries
    entries = []
    entries << sitemap_entry(priority: "1.0", changefreq: "weekly") { |l| locale_prefix(l).presence || "/" }

    { "/pages/como-funciona" => "0.7", "/presupuesto" => "0.8",
      "/colegios" => "0.8", "/eventos" => "0.8", "/empresas" => "0.8", "/oposiciones" => "0.8",
      "/blogs/news" => "0.7",
      "/pages/contact" => "0.5", "/politica-privacidad" => "0.3" }.each do |path, pr|
      entries << sitemap_entry(priority: pr, changefreq: "monthly") { |l| "#{locale_prefix(l)}#{path}" }
    end

    Product.where(active: true).order(:position).each do |product|
      entries << sitemap_entry(lastmod: product.updated_at.to_date.iso8601, priority: "0.9", changefreq: "weekly") do |l|
        "#{locale_prefix(l)}/products/#{product.to_param}"
      end
    end

    Post.order(created_at: :desc).each do |post|
      entries << sitemap_entry(lastmod: post.updated_at.to_date.iso8601, priority: "0.6", changefreq: "monthly") do |l|
        "#{locale_prefix(l)}/blogs/news/#{post.slug_for(l)}"
      end
    end

    entries
  end

  def llms_txt
    base = canonical_base
    products = Product.active.order(:position, :name)
    posts    = Post.order(created_at: :desc).limit(10)

    out = []
    out << "# PhoneRelax"
    out << ""
    out << "> Bolsas y fundas magnéticas para guardar y bloquear la señal del móvil en aulas, centros educativos, eventos y espacios sin distracciones."
    out << ""
    out << "PhoneRelax vende bolsas magnéticas donde el propio usuario guarda su móvil y lo sella; se abren acercando la cerradura a un imán especial PhoneRelax. Hay una versión básica (sella la bolsa) y una versión SignalBlocking que además bloquea la señal móvil y el wifi. Pensadas para colegios, institutos, academias y eventos."
    out << ""
    out << "## Páginas"
    out << "- [Inicio](#{base}/): tienda y presentación"
    out << "- [¿Cómo funciona?](#{base}/pages/como-funciona): funcionamiento y preguntas frecuentes"
    out << "- [Blog](#{base}/blogs/news): artículos sobre el uso responsable del móvil"
    out << "- [Contacto](#{base}/pages/contact)"
    out << ""
    out << "## Productos"
    products.each do |p|
      price = helpers.number_to_currency(p.price, unit: "€", format: "%n %u")
      out << "- [#{p.name}](#{base}#{product_page_path(p)}): #{price}"
    end
    out << ""
    out << "## Blog"
    posts.each do |post|
      out << "- [#{post.title}](#{base}#{blog_post_path(post)})"
    end
    out << ""
    out << "## Contacto"
    out << "- Email: info@phonerelax.com"
    out.join("\n") + "\n"
  end

  def robots_txt
    <<~TXT
      # PhoneRelax
      User-agent: *
      Allow: /
      Disallow: /admin
      Disallow: /carrito
      Disallow: /pedido
      Disallow: /session

      # Rastreadores de IA — permitidos explícitamente
      User-agent: GPTBot
      User-agent: OAI-SearchBot
      User-agent: ChatGPT-User
      User-agent: ClaudeBot
      User-agent: Claude-Web
      User-agent: PerplexityBot
      User-agent: Google-Extended
      User-agent: Applebot-Extended
      User-agent: CCBot
      Allow: /

      Sitemap: #{canonical_base}/sitemap.xml
    TXT
  end
end
