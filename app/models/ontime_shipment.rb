# Un envío dado de alta en Ontime desde un pedido (Order) o un presupuesto
# (Quote). Guarda el nº de seguimiento y el CP de destino (que Ontime exige para
# consultar estado y etiqueta), y va registrando en `last_response` la última
# respuesta cruda de la API. Los cambios de estado se apuntan en el historial del
# pedido/presupuesto asociado (ver #poll!).
class OntimeShipment < ApplicationRecord
  belongs_to :shippable, polymorphic: true

  validates :admission_code, presence: true, uniqueness: true
  validates :postal_code, presence: true
  validates :service_code, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
  # Pendientes de seguir consultando: ya tienen seguimiento y no se han entregado.
  scope :trackable, -> { where(delivered: false).where.not(tracking_number: [ nil, "" ]) }

  # Servicios de Ontime (productCode => etiqueta). El XS (24) es el habitual.
  SERVICES = { "24" => "XS", "23" => "S", "22" => "M", "21" => "L" }.freeze

  # Estado legible para mostrar (nunca vacío).
  def display_status
    status.presence || "pendiente de recogida"
  end

  def service_label
    SERVICES[service_code] || service_code
  end

  # PDF de la etiqueta (vía Labelary, igual que el visor de etiquetas).
  def label_pdf(client: Ontime::Client.new)
    Ontime::LabelPdf.render(tracking: tracking_number, postal_code: postal_code, client: client)
  end

  # Consulta el estado en Ontime y, si ha cambiado, lo apunta en el historial del
  # pedido/presupuesto. Devuelve self. No revienta si Ontime no lo encuentra.
  def poll!(client: Ontime::Client.new)
    return self if tracking_number.blank?

    body = client.tracking(tracking: tracking_number, postal_code: postal_code)
    return self unless body.is_a?(Hash) && body["success"]

    apply_tracking!(body)
    self
  rescue Ontime::Client::Error => e
    Rails.logger.warn("[Ontime] no se pudo consultar #{tracking_number}: #{e.message}")
    self
  end

  # --- Extracción defensiva del estado (el esquema exacto de cada evento no está
  # documentado; se prueba con varios nombres de campo y se guarda el crudo). ---

  # Nombre legible del estado. Ontime lo da como `statusName` (con `statusCode`
  # numérico); se prueban también otros nombres por si el esquema variara.
  def self.status_text(raw)
    case raw
    when String then raw.strip.presence
    when Hash
      raw.values_at("statusName", "tmsStatusName", "description", "statusDescription",
                    "status", "name", "text", "situation").compact.first ||
        raw.values_at("statusCode", "code").compact.first
    end
  end

  def self.event_text(event)
    return event.to_s if event.is_a?(String)
    return nil unless event.is_a?(Hash)

    desc = event.values_at("statusName", "tmsStatusName", "description", "statusDescription",
                           "status", "name", "text", "event").compact.first
    code = event.values_at("statusCode", "code").compact.first
    raw_date = event.values_at("date", "statusDate", "eventDate", "dateTime", "datetime", "timestamp").compact.first
    label = [ desc.presence, code.presence ].compact.first
    [ format_event_date(raw_date), label ].compact.join(" · ").presence || event.to_json
  end

  # Fecha del evento en formato legible (dd/mm/aaaa hh:mm); si no se puede
  # interpretar, se deja tal cual la mande Ontime.
  def self.format_event_date(raw)
    return nil if raw.blank?

    Time.zone.parse(raw.to_s).strftime("%d/%m/%Y %H:%M")
  rescue ArgumentError, TypeError
    raw.to_s
  end

  def self.delivered_status?(text)
    text.to_s.match?(/entregad|delivered|finalizad/i)
  end

  # Código de estado solo si Ontime lo da como objeto; si es texto plano, no hay.
  def self.status_code_from(raw)
    return nil unless raw.is_a?(Hash)

    (raw["statusCode"] || raw["code"]).presence
  end

  private

  def apply_tracking!(body)
    events = Array(body["events"])
    # El endpoint de tracking no trae `currentStatus`; en ese caso el estado
    # actual es el del último evento. El nombre (statusName) se muestra limpio,
    # sin la fecha (esa va en el historial).
    current = body["currentStatus"] || events.last
    new_status = self.class.status_text(current)
    previous_count = event_count

    update!(
      status: new_status.presence || status,
      status_code: self.class.status_code_from(current),
      event_count: (body["eventCount"] || events.size).to_i,
      delivered: delivered || self.class.delivered_status?(new_status),
      last_response: body,
      last_polled_at: Time.current
    )

    log_new_events(events, previous_count, new_status)
  end

  # Apunta en el historial del pedido/presupuesto los movimientos nuevos, o el
  # cambio de estado si Ontime no detalla eventos.
  def log_new_events(events, previous_count, new_status)
    if events.size > previous_count
      events[previous_count..].each do |event|
        shippable.record_ontime_event("OnTime #{tracking_number}: #{self.class.event_text(event)}")
      end
    elsif new_status.present? && saved_change_to_status?
      shippable.record_ontime_event("OnTime #{tracking_number}: #{new_status}")
    end
  end
end
