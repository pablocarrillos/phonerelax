class ContactMessage < ApplicationRecord
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :recent_first, -> { order(created_at: :desc) }
end
