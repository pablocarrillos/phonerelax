class ContactsController < ApplicationController
  allow_unauthenticated_access

  def new
    @contact_message = ContactMessage.new
  end

  def create
    @contact_message = ContactMessage.new(contact_params)
    if @contact_message.save
      redirect_to contacto_path, notice: 'Mensaje enviado. Te responderemos lo antes posible.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact_message).permit(:name, :email, :phone, :message)
  end
end
