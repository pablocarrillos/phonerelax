class BlogController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.recent_first
  end

  def show
    @post = Post.by_any_slug(params[:slug]).first!

    # Redirige 301 al slug canónico del idioma activo (p. ej. /en/blog/<slug_en>).
    canonical_slug = @post.slug_for(I18n.locale)
    return redirect_to(blog_post_path(@post), status: :moved_permanently) if params[:slug] != canonical_slug

    # URLs equivalentes en cada idioma (para hreflang y el selector de idioma).
    # con with_locale el helper genera la variante de CADA idioma (pasar
    # locale: nil para el español devolvía la ruta del idioma activo)
    @localized_paths = I18n.available_locales.index_with do |loc|
      I18n.with_locale(loc) { blog_post_path(@post.slug_for(loc)) }
    end
  end
end
