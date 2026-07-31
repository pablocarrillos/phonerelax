# Catálogo importado de phonerelax.com (Shopify) el 31/07/2026.
products = [
  {
    name: 'Funda PhoneRelax SignalBlocking (bloquea cobertura móvil)',
    price: '14.95',
    shopify_handle: 'funda-phonerelax-version-sin-cobertura-movil',
    image_url: 'https://cdn.shopify.com/s/files/1/0796/9813/3316/files/funda-phonerelax-frontal-sin-cobertura.jpg',
    description: 'PhoneRelax es una funda magnética para teléfonos móviles pensada para evitar que alumnos o usuarios de la misma se puedan distraer con el teléfono en colegios, institutos, conciertos o eventos privados. Su funcionamiento es muy sencillo, debes introducir el teléfono móvil dentro y cerrar su cerradura para que quede sellado dentro. Para retirar el teléfono de su interior será necesario acercar su cerradura magnética de la funda PhoneRelax a uno de nuestros imanes especiales de apertura y retirar el teléfono de su interior. La principal ventaja de esta versión que bloquea la cobertura móvil es q',
    position: 1
  },
  {
    name: 'Imán PhoneRelax',
    price: '59.90',
    shopify_handle: 'iman-phonerelax',
    image_url: 'https://cdn.shopify.com/s/files/1/0796/9813/3316/files/PhotoRoom-20240105-091157_2.jpg',
    description: 'Permite la apertura de las bolsas PhoneRelax simplemente acercando la parte redondeada de la cerradura de la bolsa al centro del imán. El imán dispone de cuatro agujeros pensados para poder fijarlo en cualquier superficie y así evitar que pueda perderse o que se mueva durante el proceso de apertura de las bolsas PhoneRelax.',
    position: 2
  },
  {
    name: 'Funda PhoneRelax',
    price: '9.95',
    shopify_handle: 'funda-phonerelax',
    image_url: 'https://cdn.shopify.com/s/files/1/0796/9813/3316/files/PhotoRoom-20240104-223354_2.jpg',
    description: 'PhoneRelax es una funda magnética para teléfonos móviles pensada para evitar que alumnos o usuarios de la misma se puedan distraer con el teléfono en colegios, institutos, conciertos o eventos privados. Su funcionamiento es muy sencillo, debes introducir el teléfono móvil dentro y cerrar su cerradura para que quede sellado dentro. Para retirar el teléfono de su interior será necesario acercar su cerradura magnética de la funda PhoneRelax a uno de nuestros imanes especiales de apertura y retirar el teléfono de su interior. Especificaciones técnicas: Dimensiones del producto: 12cm ancho x 24cm a',
    position: 3
  },
]

products.each do |attrs|
  product = Product.find_or_initialize_by(shopify_handle: attrs[:shopify_handle])
  product.update!(attrs)
end
puts "Productos: #{Product.count}"

# Usuario del panel de gestión (cámbiale la contraseña en cuanto entres).
admin = User.find_or_initialize_by(email_address: 'admin@phonerelax.com')
admin.password = 'phonerelax-admin'
admin.save!
puts "Admin: admin@phonerelax.com"
