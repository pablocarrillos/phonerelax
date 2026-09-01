# Línea de un albarán: solo descripción y unidades, sin precios.
class DeliveryNoteLine < ApplicationRecord
  belongs_to :delivery_note, inverse_of: :lines

  validates :description, presence: true
  validates :quantity, numericality: { greater_than: 0 }
end
