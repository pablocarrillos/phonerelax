module Admin
  # Plantillas de respuesta estándar de los leads: se gestionan aquí y se usan
  # desde la lista/ficha del lead, que abre Gmail con la respuesta ya cargada.
  class EmailTemplatesController < BaseController
    before_action :set_template, only: [ :edit, :update, :destroy ]

    def index
      @templates = EmailTemplate.ordered
    end

    def new
      @template = EmailTemplate.new
    end

    def create
      @template = EmailTemplate.new(template_params)
      if @template.save
        redirect_to admin_email_templates_path, notice: "Plantilla «#{@template.name}» creada."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @template.update(template_params)
        redirect_to admin_email_templates_path, notice: "Plantilla «#{@template.name}» guardada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy!
      redirect_to admin_email_templates_path, notice: "Plantilla «#{@template.name}» borrada.", status: :see_other
    end

    private

    def set_template
      @template = EmailTemplate.find(params[:id])
    end

    def template_params
      params.require(:email_template).permit(:name, :subject, :body)
    end
  end
end
