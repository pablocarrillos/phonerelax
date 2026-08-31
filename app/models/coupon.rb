# Cupón de descuento para la tienda: código único, con rango de fechas y
# número máximo de usos opcionales, y un descuento en porcentaje (sobre la
# base, sin IVA: al ir los precios con IVA incluido, el mismo porcentaje sobre
# el bruto descuenta exactamente ese porcentaje de la base) O una cantidad
# exacta en euros (sobre el total con IVA de los productos). El transporte
# nunca se descuenta. Cada uso avisa por email al promotor del cupón.
class Coupon < ApplicationRecord
  has_many :orders, dependent: :nullify

  normalizes :code, with: ->(code) { code.strip.upcase }

  validates :code, presence: true
  validates :code, uniqueness: { case_sensitive: false }
  validates :discount_percent, numericality: { greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :discount_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :exactly_one_discount
  validate :coherent_dates
  validate :notify_emails_look_like_emails

  scope :recent_first, -> { order(created_at: :desc) }

  def self.lookup(code)
    normalized = code.to_s.strip.upcase
    return nil if normalized.blank?

    where("LOWER(code) = ?", normalized.downcase).first
  end

  def redeemable?
    rejection_reason.nil?
  end

  # Por qué no se puede usar (nil si sí se puede), para el mensaje del checkout.
  def rejection_reason
    return :disabled unless enabled?
    return :not_started if starts_on.present? && Date.current < starts_on
    return :expired if ends_on.present? && Date.current > ends_on
    return :exhausted if max_uses.present? && uses_count >= max_uses

    nil
  end

  # Descuento en euros (con IVA) para un total de productos dado; nunca más
  # que el propio total.
  def discount_for(lines_total)
    total = lines_total.to_d
    return BigDecimal("0") unless total.positive?

    raw = discount_percent.present? ? total * discount_percent.to_d / 100 : discount_amount.to_d
    [ raw.round(2), total ].min
  end

  def notify_email_list
    notify_emails.to_s.split(/[\s,;]+/).reject(&:blank?)
  end

  # Descripción corta del descuento, para listados y correos.
  def discount_label
    if discount_percent.present?
      "#{discount_percent.to_s.sub(/\.0+\z/, '')} % (sobre la base, sin IVA)"
    else
      "#{ActiveSupport::NumberHelper.number_to_rounded(discount_amount, precision: 2, separator: ',')} €"
    end
  end

  # Apunta un uso y avisa al promotor con el importe del pedido.
  def register_use!(order)
    increment!(:uses_count)
    notify_email_list.each { |email| CouponMailer.redeemed(self, order, email).deliver_later }
  end

  private

  def exactly_one_discount
    return if discount_percent.present? ^ discount_amount.present?

    errors.add(:base, "Indica el porcentaje O la cantidad exacta de descuento (una de las dos)")
  end

  def coherent_dates
    return if starts_on.blank? || ends_on.blank? || starts_on <= ends_on

    errors.add(:ends_on, "no puede ser anterior a la fecha de inicio")
  end

  def notify_emails_look_like_emails
    bad = notify_email_list.reject { |email| email.match?(URI::MailTo::EMAIL_REGEXP) }
    errors.add(:notify_emails, "contiene direcciones no válidas: #{bad.join(', ')}") if bad.any?
  end
end
