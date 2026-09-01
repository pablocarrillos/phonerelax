module Admin
  # Gestiones del historial de un lead: al crear o borrar una, el estado y el
  # presupuesto del lead se recalculan desde la última gestión.
  class LeadManagementsController < BaseController
    before_action :set_lead

    def create
      @lead_management = @lead.lead_managements.build(lead_management_params)
      ActiveRecord::Base.transaction do
        @lead_management.save!
        @lead.sync_from_managements!
      end
      redirect_to admin_lead_path(@lead), notice: "Gestión añadida."
    rescue ActiveRecord::RecordInvalid
      render "admin/leads/show", status: :unprocessable_entity
    end

    def destroy
      management = @lead.lead_managements.find(params[:id])
      ActiveRecord::Base.transaction do
        management.destroy!
        @lead.sync_from_managements!
      end
      redirect_to admin_lead_path(@lead), notice: "Gestión borrada.", status: :see_other
    end

    private

    def set_lead
      @lead = Lead.includes(:lead_emails, :lead_managements, :samples, quotes: :client).find(params[:lead_id])
    end

    def lead_management_params
      params.require(:lead_management).permit(:status, :channel, :happened_at, :action, :budget_amount)
    end
  end
end
