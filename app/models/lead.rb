# Lead comercial (colegio, empresa, evento…) al que se hace seguimiento hasta
# convertirlo en cliente. Copiado del sistema de Leads de gestion: varios
# emails, historial de gestiones (la última fija el estado y el presupuesto
# del lead) y, aquí, vínculos con las muestras enviadas y los presupuestos
# generados (estos últimos al añadir los datos fiscales, que crean el Client).
class Lead < ApplicationRecord
  WAITING_STATUS = "En espera".freeze
  STATUSES = [
    "1er contacto",
    "Muestra enviada",
    "Info general enviada",
    "Consulta de estado",
    WAITING_STATUS,
    "Producto no disponible",
    "Presupuestado sucio",
    "Presupuestado formal",
    "Perdido",
    "Confirmado"
  ].freeze

  # Cliente al que dio lugar el lead (se crea al añadir los datos fiscales).
  belongs_to :client, optional: true
  has_many :lead_emails, dependent: :destroy
  has_many :lead_managements, -> { order(happened_at: :desc, id: :desc) }, dependent: :destroy
  has_many :samples, dependent: :nullify
  has_many :quotes, dependent: :nullify

  before_validation :sync_email_list
  before_validation :disable_to_answer_for_lost_status

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :budget_amount, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  # Los emails se editan como un único texto (separados por comas o espacios).
  def email_list
    return @email_list unless @email_list.nil?

    lead_emails.reject(&:marked_for_destruction?).map(&:email).join(", ")
  end

  attr_writer :email_list

  def self.search(query)
    query = query.to_s.strip
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.downcase)}%"
    left_outer_joins(:lead_emails)
      .where(
        "LOWER(leads.status) LIKE :pattern OR LOWER(leads.name) LIKE :pattern OR LOWER(leads.phone) LIKE :pattern OR LOWER(COALESCE(leads.city, '')) LIKE :pattern OR LOWER(lead_emails.email) LIKE :pattern",
        pattern: pattern
      )
      .distinct
  end

  # Listado: primero los pendientes de contestar y, dentro, los de actividad
  # más reciente.
  def self.for_index(query)
    includes(:lead_emails, :lead_managements)
      .search(query)
      .to_a
      .sort_by { |lead| [ lead.to_answer? ? 0 : 1, -lead.latest_activity_at.to_i ] }
  end

  def latest_activity_at
    lead_managements.map(&:happened_at).compact.max || created_at
  end

  def latest_budget_management
    lead_managements.detect { |management| management.budget_amount.present? }
  end

  def days_without_contact(reference_time = Time.current)
    [ (reference_time.to_date - latest_activity_at.to_date).to_i, 0 ].max
  end

  def primary_email
    lead_emails.map(&:email).compact_blank.min
  end

  # El estado y el presupuesto del lead reflejan siempre la última gestión.
  def sync_from_managements!
    latest = lead_managements.reload.first
    attributes = { budget_amount: latest_budget_management&.budget_amount }
    attributes[:status] = latest.status if latest.present?
    update!(attributes)
  end

  # Deja constancia en el historial del envío de una muestra vinculada.
  def register_sample!(sample)
    productos = sample.sample_lines.map { |l| "#{l.quantity}× #{l.product.name}" }.join(", ")
    lead_managements.create!(status: "Muestra enviada", channel: "Muestra", happened_at: Time.current,
                             action: "Muestra enviada a #{sample.organization}#{" (#{productos})" if productos.present?}.")
    sync_from_managements!
  end

  # Deja constancia de un presupuesto generado desde el lead (con su importe).
  def register_quote!(quote)
    lead_managements.create!(status: "Presupuestado formal", channel: "Presupuesto", happened_at: Time.current,
                             budget_amount: quote.total,
                             action: "Presupuesto #{quote.number} generado para #{quote.client.name}.")
    sync_from_managements!
  end

  private

  def sync_email_list
    return if @email_list.nil?

    emails = @email_list.to_s.split(/[\s,;]+/).map(&:strip).compact_blank.map(&:downcase).uniq
    lead_emails.each do |lead_email|
      lead_email.mark_for_destruction unless emails.include?(lead_email.email.to_s.downcase)
    end

    existing = lead_emails.reject(&:marked_for_destruction?).map { |lead_email| lead_email.email.to_s.downcase }
    emails.each { |email| lead_emails.build(email: email) unless existing.include?(email) }
  end

  def disable_to_answer_for_lost_status
    self.to_answer = false if status == "Perdido"
  end
end
