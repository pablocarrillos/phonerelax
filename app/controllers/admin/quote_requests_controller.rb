module Admin
  class QuoteRequestsController < BaseController
    def index
      @quote_requests = QuoteRequest.recent_first
    end

    def destroy
      QuoteRequest.find(params[:id]).destroy
      redirect_to admin_quote_requests_path, notice: 'Solicitud borrada.'
    end
  end
end
