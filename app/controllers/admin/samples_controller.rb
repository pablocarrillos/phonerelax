module Admin
  class SamplesController < BaseController
    before_action :set_sample, only: [ :edit, :update, :destroy, :mark_returned ]

    def index
      @samples = Sample.includes(sample_lines: :product).recent_first
      @landed_costs = Purchase.average_landed_costs
      @pending_cost = @samples.select { |s| !s.returned? }.sum { |s| s.cost(@landed_costs) }
      @total_cost = @samples.sum { |s| s.cost(@landed_costs) }
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

    private

    def set_sample
      @sample = Sample.find(params[:id])
    end

    def build_blank_lines
      2.times { @sample.sample_lines.build }
    end

    def sample_params
      params.require(:sample).permit(:organization, :contact_name, :email, :sent_on, :returned_on, :notes,
                                     sample_lines_attributes: [ :id, :product_id, :quantity, :_destroy ])
    end
  end
end
