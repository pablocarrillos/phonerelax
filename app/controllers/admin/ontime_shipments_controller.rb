module Admin
  # Alta y seguimiento de envíos de Ontime desde un pedido (Order) o un
  # presupuesto (Quote). El alta pasa por una pantalla de revisión porque crea un
  # envío REAL de pago en producción.
  class OntimeShipmentsController < BaseController
    before_action :set_shipment, only: %i[poll]

    # Lista de todos los envíos, con su pedido/presupuesto y su estado.
    def index
      @shipments = OntimeShipment.includes(:shippable).recent_first
    end

    # Pantalla de revisión: datos del destinatario prerrellenados desde el
    # pedido/presupuesto para revisar/completar antes de crear el envío.
    def new
      @shippable = load_shippable(params[:shippable_type], params[:shippable_id])
      return redirect_to admin_ontime_shipments_path, alert: "No se encuentra el pedido o presupuesto." unless @shippable

      @recipient = @shippable.ontime_recipient
    end

    # Crea el envío en Ontime y lo guarda, apuntando el alta en el historial.
    def create
      @shippable = load_shippable(shipment_params[:shippable_type], shipment_params[:shippable_id])
      return redirect_to admin_ontime_shipments_path, alert: "No se encuentra el pedido o presupuesto." unless @shippable

      @recipient = recipient_from_params
      missing = missing_recipient_fields(@recipient)
      if missing.any?
        flash.now[:alert] = "Faltan datos para crear el envío: #{missing.to_sentence}."
        return render :new, status: :unprocessable_entity
      end

      create_shipment!
    rescue Ontime::Client::Error => e
      flash.now[:alert] = "No se pudo crear el envío en Ontime: #{e.message}"
      render :new, status: :unprocessable_entity
    end

    # Actualiza a mano el estado de un envío consultando Ontime.
    def poll
      @shipment.poll!
      redirect_back fallback_location: admin_ontime_shipments_path,
                    notice: "Estado del envío #{@shipment.tracking_number}: #{@shipment.display_status}."
    end

    # Actualiza el estado de todos los envíos activos (botón de la lista).
    def poll_all
      updated = OntimeShipment.trackable.find_each.count { |s| s.poll! && true }
      redirect_to admin_ontime_shipments_path, notice: "#{updated} envío(s) consultados en Ontime."
    end

    private

    def set_shipment
      @shipment = OntimeShipment.find(params[:id])
    end

    def load_shippable(type, id)
      return nil unless %w[Order Quote].include?(type.to_s)

      type.to_s.constantize.find_by(id: id)
    end

    def shipment_params
      params.require(:ontime_shipment).permit(:shippable_type, :shippable_id, :name, :contact_name,
                                              :address, :city, :postal_code, :country_iso,
                                              :phone, :email, :service_code, :parcel_count, :weight, :remarks)
    end

    def recipient_from_params
      shipment_params.slice(:name, :contact_name, :address, :city, :postal_code, :country_iso, :phone, :email)
                     .to_h.symbolize_keys
    end

    def missing_recipient_fields(recipient)
      missing = []
      missing << "el nombre" if recipient[:name].blank?
      missing << "la dirección" if recipient[:address].blank?
      missing << "la población" if recipient[:city].blank?
      missing << "el código postal" if recipient[:postal_code].blank?
      missing << "el teléfono" if recipient[:phone].blank?
      missing
    end

    def create_shipment!
      admission_code = generate_admission_code
      payload = Ontime::ShipmentBuilder.build(
        recipient: @recipient,
        admission_code: admission_code,
        service_code: shipment_params[:service_code],
        parcel_count: shipment_params[:parcel_count],
        weight: shipment_params[:weight],
        remarks: [ shipment_params[:remarks] ].compact_blank
      )
      result = Ontime::Client.new.create_shipment(payload)

      shipment = @shippable.ontime_shipments.create!(
        admission_code: admission_code,
        tracking_number: result["trackingNumber"],
        postal_code: @recipient[:postal_code],
        service_code: payload["productCode"],
        recipient_name: @recipient[:name],
        parcel_count: payload["parcelCount"],
        weight: payload["weight"],
        last_response: result
      )
      @shippable.record_ontime_event(
        "OnTime #{shipment.tracking_number}: envío creado (#{shipment.service_label}, #{shipment.parcel_count} bulto(s))"
      )

      redirect_to shippable_path(@shippable),
                  notice: "Envío Ontime creado. Nº de seguimiento #{shipment.tracking_number}."
    end

    # Referencia propia y única del envío para Ontime (admissionCode).
    def generate_admission_code
      loop do
        code = "PR#{SecureRandom.alphanumeric(8).upcase}"
        break code unless OntimeShipment.exists?(admission_code: code)
      end
    end

    def shippable_path(record)
      record.is_a?(Order) ? admin_order_path(record) : admin_quote_path(record)
    end
    helper_method :shippable_path
  end
end
