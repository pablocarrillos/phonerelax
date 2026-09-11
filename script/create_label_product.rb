# frozen_string_literal: true

# Crea (o actualiza) el producto interno «Etiqueta blanca para poner el nombre».
# No se vende en la tienda (active: false); su precio es 0,35 € + IVA. Se ofrece
# al crear un presupuesto. Idempotente:
#   bin/rails runner script/create_label_product.rb

product = Product.find_or_initialize_by(shopify_handle: Product::NAME_LABEL_HANDLE)
product.name = "Etiqueta blanca para poner el nombre"
product.active = false             # no disponible para la venta en la tienda
product.pack = false
product.vat_percentage = 21
product.stock = 0 if product.new_record?

tier = product.price_tiers.find_or_initialize_by(min_units: 1)
tier.unit_price = BigDecimal("0.35") # precio SIN IVA; el price con IVA lo calcula sync_price_from_tiers

product.save! # sync_price_from_tiers fija price = 0,35 × 1,21 = 0,42

puts "Producto '#{product.name}' (handle=#{product.shopify_handle}) " \
     "id=#{product.id} active=#{product.active} price=#{product.price} " \
     "(neto #{tier.unit_price}, IVA #{product.vat_percentage}%)"
