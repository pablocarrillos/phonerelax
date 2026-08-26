module Admin
  # Comentarios del seguimiento de un presupuesto: quedan con su fecha/hora y
  # el usuario que los deja.
  class QuoteCommentsController < BaseController
    before_action :set_quote

    def create
      body = params.dig(:quote_comment, :body).to_s.strip
      if body.present?
        @quote.comments.create!(body: body, user: Current.user)
        redirect_to admin_quote_path(@quote, anchor: "comentarios"), notice: "Comentario añadido."
      else
        redirect_to admin_quote_path(@quote, anchor: "comentarios"), alert: "Escribe el comentario antes de añadirlo."
      end
    end

    def destroy
      comment = @quote.comments.find(params[:id])
      comment.destroy
      redirect_to admin_quote_path(@quote, anchor: "comentarios"), notice: "Comentario borrado.", status: :see_other
    end

    private

    def set_quote
      @quote = Quote.find(params[:quote_id])
    end
  end
end
