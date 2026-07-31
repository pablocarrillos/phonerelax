module Admin
  class ContactMessagesController < BaseController
    def index
      @messages = ContactMessage.recent_first
    end

    def destroy
      ContactMessage.find(params[:id]).destroy
      redirect_to admin_contact_messages_path, notice: 'Mensaje borrado.'
    end
  end
end
