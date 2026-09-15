# frozen_string_literal: true

# Accesorios sugeridos por producto, orden del listado (Caja a la derecha del
# Imán) y stock de la Caja. Idempotente:
#   bin/rails runner script/seed_product_accessories.rb

FUNDA_ACCESSORIES = [ "Lanyard PhoneRelax", "Personalización DTF funda" ]

ACCESSORIES = {
  "Imán PhoneRelax" => [ "Caja metálica para imán PhoneRelax" ],
  "Funda PhoneRelax SignalBlocking (bloquea cobertura móvil)" => FUNDA_ACCESSORIES,
  "Funda PhoneRelax" => FUNDA_ACCESSORIES,
  "Funda PhoneRelax SignalBlocking con Tarjetero (bloquea cobertura móvil)" => FUNDA_ACCESSORIES
}.freeze

ACCESSORIES.each do |owner_name, accessory_names|
  owner = Product.find_by(name: owner_name)
  next puts("AVISO: no se encontró el producto '#{owner_name}'") unless owner

  accessory_names.each_with_index do |accessory_name, index|
    accessory = Product.find_by(name: accessory_name)
    next puts("AVISO: accesorio '#{accessory_name}' no encontrado") unless accessory

    link = ProductAccessory.find_or_initialize_by(product_id: owner.id, accessory_id: accessory.id)
    link.position = index + 1
    link.save!
  end
  puts "#{owner_name} -> #{owner.reload.accessories.map(&:name).join(', ')}"
end

# Orden del listado: la Caja justo a la derecha del Imán
iman = Product.find_by(name: "Imán PhoneRelax")
caja = Product.find_by(name: "Caja metálica para imán PhoneRelax")
if iman && caja && caja.position != iman.position + 1
  Product.where("position > ?", iman.position).where.not(id: caja.id).update_all("position = position + 1")
  caja.update_columns(position: iman.position + 1)
  puts "Orden: Caja (pos #{caja.reload.position}) a la derecha del Imán (pos #{iman.position})"
end

# Stock de la Caja
if caja && caja.stock != 100
  caja.update_columns(stock: 100)
  puts "Stock de la Caja = #{caja.reload.stock}"
end

puts "Hecho."
