# Línea de una muestra: unidades enviadas de un producto.
class SampleLine < ApplicationRecord
  belongs_to :sample, inverse_of: :sample_lines
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
