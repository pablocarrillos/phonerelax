module Admin
  class ClientsController < BaseController
    before_action :set_client, only: [ :edit, :update, :destroy ]

    def index
      @clients = Client.ordered
    end

    # Autocompletado del formulario de presupuestos: clientes cuyo nombre
    # contiene el término (a partir de 3 letras). Devuelve JSON.
    def search
      term = params[:q].to_s.strip
      results = term.length >= 3 ? Client.name_like(term).ordered.limit(10) : Client.none
      render json: results.map { |c| { id: c.id, name: c.name } }
    end

    def new
      @client = Client.new
      # datos fiscales de un lead: se precargan sus datos para crear el cliente
      if (lead = Lead.find_by(id: params[:lead_id]))
        @lead = lead
        @client.name = lead.full_name
        @client.email = lead.primary_email
        @client.phone = lead.phone
      end
    end

    def create
      @client = Client.new(client_params)
      if @client.save
        # cliente creado desde un lead (datos fiscales): se enlaza y se sigue
        # directamente con la generación del presupuesto
        if (lead = Lead.find_by(id: params[:lead_id]))
          lead.update!(client: @client)
          return redirect_to new_admin_quote_path(client_id: @client.id, lead_id: lead.id),
                             notice: "Cliente creado y vinculado al lead #{lead.full_name}: ya puedes generar el presupuesto."
        end
        redirect_to params[:return_to].presence || admin_clients_path, notice: "Cliente creado."
      else
        @lead = Lead.find_by(id: params[:lead_id])
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
