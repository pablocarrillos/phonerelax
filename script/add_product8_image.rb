# frozen_string_literal: true

# Añade la imagen del render con cotas (funda con tarjetero, ventana 10×8 cm) a
# la galería del producto «Funda PhoneRelax SignalBlocking con Tarjetero».
# Idempotente:
#   bin/rails runner script/add_product8_image.rb

FILENAME = "funda-tarjetero-medidas.jpg"
IMAGE_PATH = Rails.root.join("db/seed_assets", FILENAME)
PRODUCT_NAME = "Funda PhoneRelax SignalBlocking con Tarjetero (bloquea cobertura móvil)"

product = Product.find_by!(name: PRODUCT_NAME)

if product.product_images.any? { |pi| pi.file.attached? && pi.file.filename.to_s == FILENAME }
  puts "Ya existe '#{FILENAME}' en la galería del producto #{product.id}; nada que hacer."
else
  position = (product.product_images.maximum(:position) || 0) + 1
  image = product.product_images.new(position: position)
  image.file.attach(io: File.open(IMAGE_PATH), filename: FILENAME, content_type: "image/jpeg")
  image.save!
  puts "Añadida '#{FILENAME}' al producto #{product.id} (position #{position}). " \
       "Galería: #{product.product_images.count} imágenes."
end
