module Admin
  class SamplesController < BaseController
    before_action :set_sample, only: [ :edit, :update, :destroy, :mark_returned, :toggle_sold ]

    # Columnas por las que se puede ordenar la tabla (whitelist para evitar
    # inyección: el nombre de columna solo puede ser uno de estos).
    SORT_COLUMNS = %w[organization sent_on returned_on].freeze

    def index
      @sort = SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "sent_on"
      @dir = params[:dir] == "asc" ? "asc" : "desc"
      @filter = %w[pending returned sold].include?(params[:filter]) ? params[:filter] : nil
      order = @sort == "organization" ? "LOWER(organization) #{@dir}" : "#{@sort} #{@dir} NULLS LAST"

      all = Sample.includes(:quote, sample_lines: :product).order(Arel.sql("#{order}, id desc"))
      @landed_costs = Purchase.average_landed_costs
      # Resumen sobre TODAS las muestras (no depende del filtro de la tabla).
      @pending_count = all.count { |s| !s.returned? }
      @returned_count = all.count(&:returned?)
      @sold_count = all.count(&:sold?)
      @pending_cost = all.reject(&:returned?).sum { |s| s.cost(@landed_costs) }
      @total_cost = all.sum { |s| s.cost(@landed_costs) }

      @samples = case @filter
                 when "pending" then all.reject(&:returned?)
                 when "returned" then all.select(&:returned?)
                 when "sold" then all.select(&:sold?)
                 else all
                 end
    end

    def new
      @sample = Sample.new(sent_on: Date.current)
      build_blank_lines
    end

    def create
      @sample = Sample.new(sample_params)
      if @sample.save
        redirect_to admin_samples_path, notice: "Muestra registrada."
      else
        build_blank_lines
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_blank_lines
    end

    def update
      if @sample.update(sample_params)
        redirect_to admin_samples_path, notice: "Muestra actualizada."
      else
        build_blank_lines
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @sample.destroy!
      redirect_to admin_samples_path, notice: "Muestra borrada."
    end

    # Marca la muestra como recogida/devuelta hoy.
    def mark_returned
      @sample.update!(returned_on: Date.current)
      redirect_to admin_samples_path, notice: "Muestra de #{@sample.organization} marcada como devuelta."
    end

    # Alterna si la muestra acabó en venta (con independencia de la devolución).
    def toggle_sold
      @sample.update!(sold: !@sample.sold?)
      estado = @sample.sold? ? "con venta" : "sin venta"
      redirect_back fallback_location: admin_samples_path, notice: "Muestra de #{@sample.organization} marcada como #{estado}."
    end

    private

    def set_sample
      @sample = Sample.find(params[:id])
    end

    def build_blank_lines
      2.times { @sample.sample_lines.build }
    end

    def sample_params
      params.require(:sample).permit(:organization, :contact_name, :email, :sent_on, :returned_on, :notes, :quote_id, :sold,
                                     sample_lines_attributes: [ :id, :product_id, :quantity, :_destroy ])
    end
  end
end
