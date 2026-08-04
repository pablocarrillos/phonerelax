module Admin
  class ClientsController < BaseController
    before_action :set_client, only: [ :edit, :update, :destroy ]

    def index
      @clients = Client.ordered
    end

    def new
      @client = Client.new
    end

    def create
      @client = Client.new(client_params)
      if @client.save
        redirect_to params[:return_to].presence || admin_clients_path, notice: "Cliente creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @client.update(client_params)
        redirect_to admin_clients_path, notice: "Cliente actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @client.destroy
        redirect_to admin_clients_path, notice: "Cliente borrado."
      else
        redirect_to admin_clients_path, alert: @client.errors.full_messages.to_sentence
      end
    end

    private

    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.require(:client).permit(:name, :tax_id, :address, :email, :phone, :notes)
    end
  end
end
