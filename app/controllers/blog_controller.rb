class BlogController < ApplicationController
  allow_unauthenticated_access

  def index
    @posts = Post.recent_first
  end

  def show
    @post = Post.find_by!(slug: params[:slug])
  end
end
