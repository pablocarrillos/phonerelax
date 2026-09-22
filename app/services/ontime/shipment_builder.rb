module Ontime
  # Monta el hash de un envío para el POST /v1/shipments/ de Ontime, con el
  # remitente (Phone Relax / Drop Point Systems) y los valores por defecto que
  # Ontime exige (delayedDeliveryDate es obligatorio aunque no haya entrega
  # aplazada; finalShipment true; portes pagados). El centro de origen y el
  # servicio por defecto son configurables por ENV.
  class ShipmentBuilder
    DEFAULT_ORIGIN_CENTER = "000322".freeze
    DEFAULT_SERVICE = "24".freeze # XS

    # Remitente por defecto si Datos de Empresa no tuviera algún campo relleno.
    SENDER_FALLBACK = {
      "taxId" => "B02631976",
      "name" => "Drop Point Systems S.L.U.",
      "address" => "C/ Carrasqueta, 14",
      "city" => "Petrer",
      "postalCode" => "03610",
      "country" => "ES",
      "phone" => "965371962",
      "email" => "info@phonerelax.com"
    }.freeze

    def self.build(**args) = new(**args).build

    def initialize(recipient:, admission_code:, service_code: DEFAULT_SERVICE, parcel_count: 1, weight: 1.0, remarks: [])
      @recipient = recipient
      @admission_code = admission_code
      @service_code = service_code.presence || DEFAULT_SERVICE
      @parcel_count = parcel_count.to_i.clamp(1, 99)
      @weight = weight.to_f.positive? ? weight.to_f : 1.0
      @remarks = Array(remarks).map(&:to_s).reject(&:blank?)
    end

    def build
      {
        "admissionCode" => @admission_code,
        "originCenter" => origin_center,
        "productCode" => @service_code,
        "delayedDelivery" => false,
        "delayedDeliveryDate" => Date.current.iso8601,
        "returnRequired" => false,
        "largeRetail" => false,
        "shipmentWithPickup" => false,
        "printLabel" => false,
        "finalShipment" => true,
        "labelFormat" => "ZPL",
        "freightType" => "P",
        "parcelCount" => @parcel_count,
        "weight" => @weight,
        "remarks" => @remarks,
        "sender" => sender,
        "recipient" => recipient
      }
    end

    private

    def origin_center = ENV.fetch("ONTIME_ORIGIN_CENTER", DEFAULT_ORIGIN_CENTER)

    def sender
      setting = CompanySetting.current
      {
        "taxId" => setting.tax_id.presence || SENDER_FALLBACK["taxId"],
        "name" => setting.legal_name.presence || SENDER_FALLBACK["name"],
        "address" => setting.address.presence || SENDER_FALLBACK["address"],
        "city" => setting.city.presence || SENDER_FALLBACK["city"],
        "postalCode" => setting.postal_code.presence || SENDER_FALLBACK["postalCode"],
        "country" => "ES",
        "phone" => setting.phone.presence || SENDER_FALLBACK["phone"],
        "email" => setting.email.presence || SENDER_FALLBACK["email"]
      }
    rescue StandardError
      SENDER_FALLBACK.dup
    end

    def recipient
      r = @recipient
      {
        "name" => r[:name],
        "contactName" => r[:contact_name].presence || r[:name],
        "address" => r[:address],
        "city" => r[:city],
        "postalCode" => r[:postal_code],
        "country" => r[:country_iso].presence || "ES",
        "phone" => r[:phone],
        "email" => r[:email]
      }.compact_blank
    end
  end
end
