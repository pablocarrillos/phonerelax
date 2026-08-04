module Admin
  class QuotesController < BaseController
    before_action :set_quote, only: [ :show, :edit, :update, :destroy, :print, :duplicate ]

    def index
      @quotes = Quote.includes(:client, :quote_lines).recent_first
      @client_filter = Client.find_by(id: params[:client_id])
      @quotes = @quotes.where(client: @client_filter) if @client_filter
    end

    def show; end

    # Página imprimible con el formato del presupuesto oficial (imprimir → PDF).
    def print
      render layout: false
    end


    def new
      @quote = Quote.new(issued_on: Date.current,
                         valid_until: Date.current + Quote::DEFAULT_VALIDITY_DAYS.days,
                         shipping_cost: Quote::DEFAULT_SHIPPING,
                         payment_terms: Quote::DEFAULT_PAYMENT_TERMS,
                         bank_account: Quote::BANK_ACCOUNTS.first)
      build_blank_lines
    end

    def create
      @quote = Quote.new(quote_params)
      # El botón «Previsualizar PDF» envía el mismo formulario con preview=1.
      return render_preview if params[:preview]

      if @quote.save
        redirect_to admin_quote_path(@quote), notice: "Presupuesto #{@quote.number} creado."
      else
        build_blank_lines
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_blank_lines
    end

    def update
      if params[:preview]
        @quote.assign_attributes(quote_params)
        return render_preview
      end

      if @quote.update(quote_params)
        redirect_to admin_quote_path(@quote), notice: "Presupuesto actualizado."
      else
        build_blank_lines
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @quote.destroy!
      redirect_to admin_quotes_path, notice: "Presupuesto borrado."
    end

    # Crea un presupuesto nuevo partiendo de este: mismas líneas y condiciones,
    # pero con número nuevo y fechas de hoy, listo para editar.
    def duplicate
      copy = @quote.dup
      copy.assign_attributes(number: nil, issued_on: Date.current,
                             valid_until: Date.current + Quote::DEFAULT_VALIDITY_DAYS.days)
      @quote.quote_lines.each { |line| copy.quote_lines.build(line.attributes.except("id", "quote_id", "created_at", "updated_at")) }
      copy.save!
      redirect_to edit_admin_quote_path(copy), notice: "Presupuesto #{copy.number} creado a partir de #{@quote.number}."
    end

    private

    # El documento con lo que hay en el formulario, sin guardar nada.
    def render_preview
      unless @quote.client
        return render plain: "Elige un cliente para poder previsualizar el presupuesto.", status: :unprocessable_entity
      end

      @quote.valid? # autocompleta descripciones y precios del escalado, como al guardar
      @quote.number = "BORRADOR" unless @quote.persisted?
      render :print, layout: false
    end

    def set_quote
      @quote = Quote.includes(quote_lines: :product).find(params[:id])
    end

    def build_blank_lines
      3.times { @quote.quote_lines.build }
    end

    def quote_params
      params.require(:quote).permit(:client_id, :issued_on, :valid_until, :shipping_cost, :vat_rate,
                                    :payment_terms, :delivery_terms, :notes, :remarks, :bank_account, :discount_percent, :shipping_country, :internal_description,
                                    quote_lines_attributes: [ :id, :product_id, :description, :quantity,
                                                              :unit_price, :vat_rate, :discount_percent, :position, :_destroy ])
    end
  end
end
