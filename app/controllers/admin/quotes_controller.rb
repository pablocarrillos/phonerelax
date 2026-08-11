module Admin
  class QuotesController < BaseController
    before_action :set_quote, only: [ :show, :edit, :update, :destroy, :print, :duplicate,
                                      :set_status, :set_payment, :upload_files, :purge_file ]

    # "Vendidos" = presupuestos aprobados o ya entregados.
    SOLD_STATUSES = %w[aprobado entregado].freeze

    def index
      @quotes = Quote.includes(:client, quote_lines: :product).recent_first
      @client_filter = Client.find_by(id: params[:client_id])
      @quotes = @quotes.where(client: @client_filter) if @client_filter

      # Rango de fechas por fecha de creación (ambos extremos opcionales).
      @from = Date.parse(params[:from]) rescue nil
      @to = Date.parse(params[:to]) rescue nil
      @quotes = @quotes.where(created_at: @from.beginning_of_day..) if @from
      @quotes = @quotes.where(created_at: ..@to.end_of_day) if @to

      # Contadores por estado (del subconjunto de cliente y fechas, si los hay).
      @status_counts = @quotes.except(:includes, :order).group(:status).count
      @sold_count = SOLD_STATUSES.sum { |s| @status_counts[s].to_i }

      @status_filter = params[:status].presence
      if @status_filter == "vendidos"
        @quotes = @quotes.where(status: SOLD_STATUSES)
      elsif Quote.statuses.key?(@status_filter)
        @quotes = @quotes.where(status: @status_filter)
      else
        @status_filter = nil
      end
      # La lista de «Aprobado» muestra el estado DTF de cada presupuesto:
      # precarga packs y adjunto para no disparar consultas por fila.
      if @status_filter == "aprobado"
        @quotes = @quotes.includes(quote_lines: { product: { pack_items: :component } }).with_attached_dtf_file
      end

      @line_totals = line_totals if @status_filter
    end

    # Etiqueta del filtro actual (estado o el pseudo-estado "Vendidos").
    helper_method :status_filter_label
    def status_filter_label
      @status_filter == "vendidos" ? "Vendidos" : Quote::STATUS_LABELS[@status_filter]
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
                         bank_account: Quote::DEFAULT_BANK_ACCOUNT)
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

    # Marca el estado comercial del presupuesto (abierto / aprobado / en pausa / perdido).
    def set_status
      status = params[:status].to_s
      if Quote.statuses.key?(status)
        @quote.update!(status: status)
        redirect_back fallback_location: admin_quote_path(@quote), notice: "Presupuesto #{@quote.number} marcado como «#{@quote.status_label}»."
      else
        redirect_back fallback_location: admin_quote_path(@quote), alert: "Estado no válido."
      end
    end

    # Marca el estado del cobro (sin pagos / pagado para confirmar / pagado totalmente).
    def set_payment
      payment = params[:payment_status].to_s
      if Quote.payment_statuses.key?(payment)
        @quote.update!(payment_status: payment)
        redirect_back fallback_location: admin_quote_path(@quote), notice: "Presupuesto #{@quote.number}: «#{@quote.payment_status_label}»."
      else
        redirect_back fallback_location: admin_quote_path(@quote), alert: "Estado de pago no válido."
      end
    end

    # Sube los ficheros del pedido (logo del colegio, fichero DTF y presupuesto
    # firmado). Solo tiene sentido —y solo se permite— con el presupuesto aprobado.
    def upload_files
      unless @quote.confirmed?
        return redirect_to admin_quote_path(@quote), alert: "Los ficheros solo se pueden subir en presupuestos aprobados o entregados."
      end

      saved = @quote.available_files.select do |name|
        file = params.dig(:quote, name)
        @quote.order_file(name).attach(file) if file.present?
      end
      if saved.any?
        redirect_to admin_quote_path(@quote), notice: "Guardado: #{saved.map { |name| Quote::ATTACHMENTS[name] }.join(', ')}."
      else
        redirect_to admin_quote_path(@quote), alert: "Selecciona algún fichero para subir."
      end
    end

    # Borra uno de los ficheros del pedido.
    def purge_file
      name = params[:attachment].to_s
      return redirect_to admin_quote_path(@quote), alert: "Fichero no válido." unless Quote::ATTACHMENTS.key?(name)

      @quote.order_file(name).purge
      redirect_to admin_quote_path(@quote), notice: "#{Quote::ATTACHMENTS[name]}: borrado."
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

    # Totales de todas las líneas de venta de los presupuestos filtrados,
    # agrupadas por producto (o por descripción si la línea es libre).
    def line_totals
      @quotes.flat_map(&:quote_lines)
             .group_by { |line| line.product&.name || line.description }
             .map { |name, lines| { name: name, units: lines.sum { |l| l.quantity.to_i }, total: lines.sum(&:total) } }
             .sort_by { |row| -row[:total] }
    end

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
      params.require(:quote).permit(:number, :client_id, :issued_on, :valid_until, :shipping_cost, :manual_shipping, :vat_rate,
                                    :payment_terms, :delivery_terms, :notes, :remarks, :bank_account, :discount_percent, :shipping_country, :internal_description,
                                    quote_lines_attributes: [ :id, :product_id, :description, :quantity,
                                                              :unit_price, :vat_rate, :discount_percent, :position, :_destroy ])
    end
  end
end
