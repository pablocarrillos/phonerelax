module Admin
  class PostsController < BaseController
    before_action :set_post, only: [ :edit, :update, :destroy ]

    def index
      @posts = Post.recent_first
    end

    def new
      @post = Post.new(published_on: Date.current)
    end

    def create
      @post = Post.new(post_params)
      @post.slug = @post.title.to_s.parameterize if @post.slug.blank?
      if @post.save
        redirect_to admin_posts_path, notice: "Artículo creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @post.update(post_params)
        redirect_to admin_posts_path, notice: "Artículo actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_path, notice: "Artículo borrado."
    end

    private

    def set_post
      @post = Post.find_by!(slug: params[:id])
    end

    def post_params
      params.require(:post).permit(:title, :slug, :excerpt, :body, :title_pt, :excerpt_pt, :body_pt, :slug_pt, :title_en, :excerpt_en, :body_en, :slug_en, :title_fr, :excerpt_fr, :body_fr, :slug_fr, :title_de, :excerpt_de, :body_de, :slug_de, :title_sv, :excerpt_sv, :body_sv, :slug_sv, :image_url, :published_on)
    end
  end
end
