# Proveedor al que se compra mercancía (fábricas, mayoristas, transportistas…).
class Supplier < ApplicationRecord
  has_many :purchases, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :ordered, -> { order(:name) }
end
