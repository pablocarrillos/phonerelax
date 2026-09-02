module Admin
  # Leads comerciales (copiado del sistema de gestion): listado por secciones
  # (activos / en espera / perdidos / confirmados) con buscador, ficha con
  # historial de gestiones y vínculos con muestras y presupuestos.
  class LeadsController < BaseController
    MAIN_SECTION = "main".freeze
    SECTION_STATUSES = {
      "waiting" => Lead::WAITING_STATUS,
      "lost" => "Perdido",
      "won" => "Confirmado"
    }.freeze

    before_action :set_lead, only: [ :show, :edit, :update, :destroy, :mark_template_sent ]

    def index
      @query = params[:q].to_s.strip
      @section = SECTION_STATUSES.key?(params[:section]) ? params[:section] : MAIN_SECTION
      matching = Lead.for_index(@query)
      @counts = SECTION_STATUSES.transform_values { |status| matching.count { |lead| lead.status == status } }
      @counts[MAIN_SECTION] = matching.size - @counts.values.sum
      @leads = if @section == MAIN_SECTION
        matching.reject { |lead| SECTION_STATUSES.value?(lead.status) }
      else
        matching.select { |lead| lead.status == SECTION_STATUSES[@section] }
      end
      @templates = EmailTemplate.ordered
    end

    def show
      @lead_management = @lead.lead_managements.build(status: @lead.status, happened_at: Time.current)
      @templates = EmailTemplate.ordered
    end

    def new
      @lead = Lead.new(status: Lead::STATUSES.first, to_answer: true)
    end

    def create
      @lead = Lead.new(lead_params.merge(to_answer: true))
      if @lead.save
        redirect_to admin_lead_path(@lead), notice: "Lead creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @lead.update(lead_params)
        redirect_to admin_lead_path(@lead), notice: "Lead guardado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @lead.destroy!
      redirect_to admin_leads_path, notice: "Lead «#{@lead.full_name}» borrado.", status: :see_other
    end

    # El envío real ocurre en Gmail: este botón deja constancia manual en el
    # historial de que se envió la plantilla (y refresca la última actividad).
    def mark_template_sent
      template = EmailTemplate.find(params[:template_id])
      @lead.lead_managements.create!(status: @lead.status, channel: "Correo", happened_at: Time.current,
                                     action: "Enviada la plantilla «#{template.name}» por email.")
      redirect_back fallback_location: admin_lead_path(@lead),
                    notice: "Apuntado en el historial: plantilla «#{template.name}» enviada a #{@lead.full_name}."
    end

    private

    def set_lead
      @lead = Lead.includes(:lead_emails, :lead_managements, :samples, quotes: :client).find(params[:id])
    end

    def lead_params
      params.require(:lead).permit(:name, :last_name, :email_subject, :phone, :city, :origin, :status, :to_answer, :email_list, :client_id)
    end
  end
end
