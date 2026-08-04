class ContactsController < ApplicationController
  allow_unauthenticated_access
  # Protección antibots: honeypot + tiempo mínimo de envío + spinner (invisible_captcha)
  # y límite de envíos por IP (rate_limit).
  invisible_captcha only: [ :create ], on_spam: :spam_detected, on_timestamp_spam: :spam_detected
  rate_limit to: 5, within: 1.hour, only: :create,
             with: -> { redirect_to contacto_path, alert: t("flash.verify_failed") }

  def new
    @contact_message = ContactMessage.new
  end

  # El mensaje no se guarda: se valida y se reenvía por email al buzón de la tienda.
  def create
    @contact_message = ContactMessage.new(contact_params)
    if @contact_message.valid?
      ContactMailer.new_message(contact_params.to_h).deliver_later
      redirect_to contacto_path, notice: t("flash.message_sent")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def spam_detected
    redirect_to contacto_path, alert: t("flash.verify_failed")
  end

  def contact_params
    params.require(:contact_message).permit(:name, :email, :phone, :message)
  end
end
