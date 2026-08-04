class QuotesController < ApplicationController
  allow_unauthenticated_access
  # Protección antibots: honeypot + tiempo mínimo de envío + límite por IP.
  invisible_captcha only: [ :create ], on_spam: :spam_detected, on_timestamp_spam: :spam_detected
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to quote_path, alert: t("flash.verify_failed") }

  def new
    @quote_request = QuoteRequest.new
  end

  # La solicitud no se guarda: se valida y se reenvía por email al buzón de la tienda.
  def create
    @quote_request = QuoteRequest.new(quote_params)
    if @quote_request.valid?
      QuoteMailer.new_request(quote_params.to_h).deliver_later
      redirect_to quote_path, notice: t("flash.quote_sent")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def spam_detected
    redirect_to quote_path, alert: t("flash.verify_failed")
  end

  def quote_params
    params.require(:quote_request).permit(:name, :organization, :email, :phone, :sector, :units, :message)
  end
end
