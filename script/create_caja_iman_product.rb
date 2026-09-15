# frozen_string_literal: true

# Crea (o actualiza) el producto «Caja para guardar el imán»: 48 € + IVA por
# unidad, con -5 % a partir de 10 uds. No incluye el imán. Idempotente:
#   bin/rails runner script/create_caja_iman_product.rb

HANDLE = "caja-metalica-para-iman-phonerelax"
GALLERY = %w[
  caja-iman-cerrada.jpg
  caja-iman-cerrada-top.jpg
  caja-iman-abierta-1.jpg
  caja-iman-abierta-2.jpg
]
DESCRIPTION = <<~HTML.strip
  <p>Caja metálica para guardar el imán PhoneRelax.</p>
  <p><strong>Medidas:</strong> 170 mm de ancho × 55 mm de profundidad × 90 mm de alto.</p>
  <p>Está preparada para <strong>exteriores</strong> y diseñada <strong>a medida</strong> para instalar el imán PhoneRelax y <strong>fijarse cómodamente a la pared</strong>.</p>
  <p><strong>⚠ No incluye el imán:</strong> debe comprarse por separado.</p>
HTML

# Traducciones (columnas name_<loc> / description_<loc>)
TRANSLATIONS = {
  pt: { name: "Caixa metálica para íman PhoneRelax",
        description: <<~HTML.strip },
          <p>Caixa metálica para guardar o íman PhoneRelax.</p>
          <p><strong>Dimensões:</strong> 170 mm de largura × 55 mm de profundidade × 90 mm de altura.</p>
          <p>Está preparada para <strong>exterior</strong> e foi concebida <strong>à medida</strong> para instalar o íman PhoneRelax e <strong>fixar-se comodamente à parede</strong>.</p>
          <p><strong>⚠ Não inclui o íman:</strong> deve ser comprado separadamente.</p>
        HTML
  en: { name: "Metal box for the PhoneRelax magnet",
        description: <<~HTML.strip },
          <p>Metal box to store the PhoneRelax magnet.</p>
          <p><strong>Dimensions:</strong> 170 mm wide × 55 mm deep × 90 mm high.</p>
          <p>It is <strong>weatherproof</strong> and <strong>custom-designed</strong> to fit the PhoneRelax magnet and <strong>mount easily on the wall</strong>.</p>
          <p><strong>⚠ The magnet is not included:</strong> it must be bought separately.</p>
        HTML
  fr: { name: "Boîte métallique pour l'aimant PhoneRelax",
        description: <<~HTML.strip },
          <p>Boîte métallique pour ranger l'aimant PhoneRelax.</p>
          <p><strong>Dimensions :</strong> 170 mm de largeur × 55 mm de profondeur × 90 mm de hauteur.</p>
          <p>Elle est prévue pour l'<strong>extérieur</strong> et conçue <strong>sur mesure</strong> pour installer l'aimant PhoneRelax et <strong>se fixer facilement au mur</strong>.</p>
          <p><strong>⚠ L'aimant n'est pas inclus :</strong> il doit être acheté séparément.</p>
        HTML
  it: { name: "Scatola metallica per il magnete PhoneRelax",
        description: <<~HTML.strip },
          <p>Scatola metallica per riporre il magnete PhoneRelax.</p>
          <p><strong>Dimensioni:</strong> 170 mm di larghezza × 55 mm di profondità × 90 mm di altezza.</p>
          <p>È adatta per <strong>esterni</strong> e progettata <strong>su misura</strong> per installare il magnete PhoneRelax e <strong>fissarsi comodamente alla parete</strong>.</p>
          <p><strong>⚠ Non include il magnete:</strong> va acquistato separatamente.</p>
        HTML
  de: { name: "Metallbox für den PhoneRelax-Magneten",
        description: <<~HTML.strip },
          <p>Metallbox zur Aufbewahrung des PhoneRelax-Magneten.</p>
          <p><strong>Maße:</strong> 170 mm Breite × 55 mm Tiefe × 90 mm Höhe.</p>
          <p>Sie ist <strong>wetterfest</strong> und <strong>maßgeschneidert</strong>, um den PhoneRelax-Magneten aufzunehmen, und lässt sich <strong>bequem an der Wand befestigen</strong>.</p>
          <p><strong>⚠ Der Magnet ist nicht enthalten:</strong> er muss separat gekauft werden.</p>
        HTML
  sv: { name: "Metallåda för PhoneRelax-magneten",
        description: <<~HTML.strip },
          <p>Metallåda för att förvara PhoneRelax-magneten.</p>
          <p><strong>Mått:</strong> 170 mm bred × 55 mm djup × 90 mm hög.</p>
          <p>Den är <strong>väderbeständig</strong> och <strong>specialdesignad</strong> för att montera PhoneRelax-magneten och <strong>fästas enkelt på väggen</strong>.</p>
          <p><strong>⚠ Magneten ingår inte:</strong> den måste köpas separat.</p>
        HTML
  da: { name: "Metalboks til PhoneRelax-magneten",
        description: <<~HTML.strip }
          <p>Metalboks til opbevaring af PhoneRelax-magneten.</p>
          <p><strong>Mål:</strong> 170 mm bred × 55 mm dyb × 90 mm høj.</p>
          <p>Den er <strong>vejrbestandig</strong> og <strong>specialdesignet</strong> til at montere PhoneRelax-magneten og <strong>fastgøres nemt på væggen</strong>.</p>
          <p><strong>⚠ Magneten er ikke inkluderet:</strong> den skal købes separat.</p>
        HTML
}.freeze

product = Product.find_or_initialize_by(shopify_handle: HANDLE)
product.name = "Caja metálica para imán PhoneRelax"
product.description = DESCRIPTION
TRANSLATIONS.each do |loc, t|
  product.public_send("name_#{loc}=", t[:name])
  product.public_send("description_#{loc}=", t[:description])
end
product.active = true
product.pack = false
product.vat_percentage = 21
product.stock = 100 if product.new_record?

# Escalado de precios (sin IVA): 48,00 desde 1 ud.; 45,60 (−5 %) desde 10 uds.
product.price_tiers.find_or_initialize_by(min_units: 1).unit_price  = BigDecimal("48.00")
product.price_tiers.find_or_initialize_by(min_units: 10).unit_price = BigDecimal("45.60")
product.save! # sync_price_from_tiers fija price = 48 × 1,21 = 58,08

# Portada (la usa el grid de la tienda): la foto cerrada
unless product.cover_image.attached?
  product.cover_image.attach(io: File.open(Rails.root.join("db/seed_assets", "caja-iman-cerrada.jpg")),
                             filename: "caja-iman-cerrada.jpg", content_type: "image/jpeg")
end

# Galería (en orden), idempotente por nombre de fichero
GALLERY.each_with_index do |filename, index|
  next if product.product_images.any? { |pi| pi.file.attached? && pi.file.filename.to_s == filename }

  image = product.product_images.new(position: index + 1)
  image.file.attach(io: File.open(Rails.root.join("db/seed_assets", filename)),
                    filename: filename, content_type: "image/jpeg")
  image.save!
end

product.reload
puts "Producto '#{product.name}' (handle=#{product.shopify_handle}) id=#{product.id} " \
     "active=#{product.active} price=#{product.price} stock=#{product.stock} " \
     "tramos=#{product.price_tiers.ordered.map { |t| "#{t.min_units}→#{t.unit_price}" }.join(', ')} " \
     "galería=#{product.product_images.count}"
