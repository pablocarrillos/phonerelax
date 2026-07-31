class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  # Al establecer contraseña, debe confirmarse por duplicado.
  validates :password_confirmation, presence: true, if: -> { password.present? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
