# Email de contacto de un lead (puede tener varios).
class LeadEmail < ApplicationRecord
  belongs_to :lead

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { scope: :lead_id }
end
