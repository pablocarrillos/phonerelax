class SeoController < ApplicationController
  allow_unauthenticated_access

  # /robots.txt — permite el rastreo del contenido público, bloquea las áreas
  # privadas/transaccionales y da la bienvenida explícita a los crawlers de IA.
  def robots
    render plain: robots_txt, content_type: 'text/plain'
  end

  # /sitemap.xml — home, páginas de contenido, productos activos y artículos.
  def sitemap
    @products = Product.where(active: true).order(:position)
    @posts    = Post.order(created_at: :desc)
    render layout: false, content_type: 'application/xml'
  end

  # /llms.txt — resumen curado del sitio para modelos de IA (llmstxt.org).
  def llms
    render plain: llms_txt, content_type: 'text/plain'
  end

  private

  def canonical_base
    ENV['CANONICAL_HOST'].presence || request.base_url
  end
  helper_method :canonical_base

  def llms_txt
    base = canonical_base
    products = Product.active.order(:position, :name)
    posts    = Post.order(created_at: :desc).limit(10)

    out = []
    out << '# PhoneRelax'
    out << ''
    out << '> Bolsas y fundas magnéticas para guardar y bloquear la señal del móvil en aulas, centros educativos, eventos y espacios sin distracciones.'
    out << ''
    out << 'PhoneRelax vende bolsas magnéticas donde el propio usuario guarda su móvil y lo sella; se abren acercando la cerradura a un imán especial PhoneRelax. Hay una versión básica (sella la bolsa) y una versión SignalBlocking que además bloquea la señal móvil y el wifi. Pensadas para colegios, institutos, academias y eventos.'
    out << ''
    out << '## Páginas'
    out << "- [Inicio](#{base}/): tienda y presentación"
    out << "- [¿Cómo funciona?](#{base}/como-funciona): funcionamiento y preguntas frecuentes"
    out << "- [Quiénes somos](#{base}/quienes-somos)"
    out << "- [Blog](#{base}/blog): artículos sobre el uso responsable del móvil"
    out << "- [Contacto](#{base}/contacto)"
    out << ''
    out << '## Productos'
    products.each do |p|
      price = helpers.number_to_currency(p.price, unit: '€', format: '%n %u')
      out << "- [#{p.name}](#{base}#{product_page_path(p)}): #{price}"
    end
    out << ''
    out << '## Blog'
    posts.each do |post|
      out << "- [#{post.title}](#{base}#{blog_post_path(post)})"
    end
    out << ''
    out << '## Contacto'
    out << '- Email: info@phonerelax.com'
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
