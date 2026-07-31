# Catálogo importado de phonerelax.com (Shopify), con descripción HTML e imágenes completas.
products = [
  {
    shopify_handle: 'funda-phonerelax-version-sin-cobertura-movil',
    name: 'Funda PhoneRelax SignalBlocking (bloquea cobertura móvil)',
    price: '14.95',
    image_url: '/images/products/funda-signalblocking-frontal.jpg',
    description: '<p><span>PhoneRelax es una funda magnética para teléfonos móviles pensada para evitar que alumnos o usuarios de la misma se puedan distraer con el teléfono en colegios, institutos, conciertos o eventos privados. Su funcionamiento es muy sencillo, debes introducir el teléfono móvil dentro y cerrar su cerradura para que quede sellado dentro. Para retirar el teléfono de su interior será necesario acercar su cerradura magnética de la funda PhoneRelax a uno de nuestros imanes especiales de apertura  y retirar el teléfono de su interior. </span></p>
<p><span></span><span><strong>La principal ventaja de esta versión que bloquea la cobertura móvil es que el usuario no se verá distraído con notificaciones, tonos de llamada o vibraciones si se olvidó silenciar o apagar su teléfono antes de introducirlo en la bolsa PhoneRelax por lo que el usuario no tendrá tampoco la ansiedad y distracción que generan las notificaciones constantes de las diferentes aplicaciones.</strong></span></p>
<div class="fe-block fe-block-yui_3_17_2_1_1693447307014_180849">
<div class="sqs-block html-block sqs-block-html" id="block-yui_3_17_2_1_1693447307014_180849">
<div class="sqs-block-content">
<div class="sqs-html-content">
<p class="sqsrte-large preFade fadeIn"><strong><span>Especificaciones técnicas:</span></strong></p>
</div>
</div>
</div>
</div>
<div class="fe-block fe-block-5c4872ac66f1a93f8585">
<div class="sqs-block html-block sqs-block-html" id="block-5c4872ac66f1a93f8585">
<div class="sqs-block-content">
<div class="sqs-html-content">
<p class="preFade fadeIn"><span class="sqsrte-text-color--black"><span><strong>Dimensiones del producto:</strong> 12cm ancho x 26cm alto x 4,5cm profundidad<br><strong>Material:</strong> 30% neopreno, 40% poliester, 20% aluminio y 10% plástico.<br><strong>Teléfonos compatibles:</strong> Cualquier teléfono inteligente con un tamaño de pantalla de hasta 6,8 pulgadas.<br><strong>Color:</strong> Negro<br><strong>Peso:</strong> 115g</span></span></p>
</div>
</div>
</div>
</div>',
    position: 1,
    images: ['/images/products/funda-signalblocking-frontal.jpg', '/images/products/funda-signalblocking-trasera.jpg']
  },
  {
    shopify_handle: 'iman-phonerelax',
    name: 'Imán PhoneRelax',
    price: '59.90',
    image_url: '/images/products/iman-1.jpg',
    description: '<p>Permite la apertura de las bolsas PhoneRelax simplemente acercando la parte redondeada de la cerradura de la bolsa al centro del imán.</p>
<p>El imán dispone de cuatro agujeros pensados para poder fijarlo en cualquier superficie y así evitar que pueda perderse o que se mueva durante el proceso de apertura de las bolsas PhoneRelax.</p>',
    position: 2,
    images: ['/images/products/iman-1.jpg', '/images/products/iman-2.jpg']
  },
  {
    shopify_handle: 'funda-phonerelax',
    name: 'Funda PhoneRelax',
    price: '9.95',
    image_url: '/images/products/funda-1.jpg',
    description: '<p><span>PhoneRelax es una funda magnética para teléfonos móviles pensada para evitar que alumnos o usuarios de la misma se puedan distraer con el teléfono en colegios, institutos, conciertos o eventos privados. Su funcionamiento es muy sencillo, debes introducir el teléfono móvil dentro y cerrar su cerradura para que quede sellado dentro. Para retirar el teléfono de su interior será necesario acercar su cerradura magnética de la funda PhoneRelax a uno de nuestros imanes especiales de apertura  y retirar el teléfono de su interior. </span></p>
<p><strong><span>Especificaciones técnicas:</span></strong></p>
<div class="fe-block fe-block-5c4872ac66f1a93f8585">
<div id="block-5c4872ac66f1a93f8585" class="sqs-block html-block sqs-block-html">
<div class="sqs-block-content">
<div class="sqs-html-content">
<p class="preFade fadeIn"><span class="sqsrte-text-color--darkAccent"><strong><span>Dimensiones del producto:</span></strong></span><span class="sqsrte-text-color--black"><span> 12cm ancho x 24cm alto x 4,5cm profundidad<br></span></span><span class="sqsrte-text-color--black"><span><span class="sqsrte-text-color--darkAccent"><strong>Material:</strong></span> 40% neopreno, 50% poliester y 10% plástico.<br></span></span><span class="sqsrte-text-color--darkAccent"><strong><span>Teléfonos compatibles:</span></strong></span><span class="sqsrte-text-color--black"><span> Cualquier teléfono inteligente con un tamaño de pantalla de hasta 6,8 pulgadas.<br></span></span><span class="sqsrte-text-color--darkAccent"><strong><span>Color: </span></strong></span><span class="sqsrte-text-color--black"><span>Negro<br></span></span><span class="sqsrte-text-color--darkAccent"><strong><span>Peso: </span></strong></span><span class="sqsrte-text-color--black"><span>82g</span></span></p>
<p class="preFade fadeIn"><br></p>
</div>
</div>
</div>
</div>',
    position: 3,
    images: ['/images/products/funda-1.jpg', '/images/products/funda-2.jpg']
  },
]

products.each do |attrs|
  images = attrs.delete(:images)
  product = Product.find_or_initialize_by(shopify_handle: attrs[:shopify_handle])
  product.update!(attrs)
  images.each_with_index do |url, index|
    image = product.product_images.find_or_initialize_by(url: url)
    image.update!(position: index + 1)
  end
end
puts "Productos: #{Product.count} (#{ProductImage.count} imágenes)"

# Usuario del panel de gestión (cámbiale la contraseña en cuanto entres).
admin = User.find_or_initialize_by(email_address: 'admin@phonerelax.com')
admin.name ||= 'Admin'
admin.password = 'phonerelax-admin'
admin.save!
puts "Admin: admin@phonerelax.com"

# Artículos del blog importados de phonerelax.com.
blog_posts = [
  {
    slug: 'cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas',
    title: 'Ventajas de controlar el uso de móviles en el aula',
    excerpt: 'Controlar el uso de teléfonos móviles en colegios para niños y adolescentes mediante el uso de bolsas PhoneRelax tiene varias ventajas claras entre las que se encuentran principalmente el fomento del enfoque académico. Sin distracciones de los teléfonos, los estudiantes tienden a prestar más atenció',
    image_url: '/images/blog/alumnos-con-telefono.jpg',
    published_on: '2024-01-05',
    body: '<p><span style="font-weight: 400;">Controlar el uso de teléfonos móviles en colegios para niños y adolescentes mediante el uso de bolsas PhoneRelax tiene varias ventajas claras entre las que se encuentran principalmente el <strong>f</strong></span><span style="font-weight: 400;"><strong>omento del enfoque académico</strong>. Sin distracciones de los teléfonos, los estudiantes tienden a prestar más atención en clase, lo que puede mejorar su rendimiento académico. Es una realidad que a menos distracciones hay una mayor concentración y sin la tentación constante de revisar el teléfono, los estudiantes pueden concentrarse más en las tareas y actividades escolares, lo que mejora su capacidad de atención.<br></span></p>
<p><span style="font-weight: 400;">Otra ventaja es la <strong>m</strong></span><span style="font-weight: 400;"><strong>ejora en la interacción social,</strong> es decir, al limitar el uso de teléfonos, se promueve la interacción cara a cara entre los estudiantes, fortaleciendo sus habilidades sociales y su capacidad para trabajar en equipo.</span></p>
<p><span style="font-weight: 400;">Se ha demostrado también que <strong>reduce el acoso cibernético</strong> ya que al restringir el uso de dispositivos electrónicos puede disminuir los casos de acoso cibernético y el acceso a contenido inapropiado, ayudando a crear un entorno escolar más seguro.</span></p>
<p><span style="font-weight: 400;">En el patio produce un <strong>mayor tiempo de actividad física</strong>, ya que sin el constante uso de dispositivos, los estudiantes pueden tener más tiempo para actividades físicas, lo que es beneficioso para su salud y bienestar.</span></p>
<p><span style="font-weight: 400;">Una ventaja de la limitación del  uso de los móviles en colegios e institutos es el <strong>desarrollo de habilidades de resolución de problemas</strong> pues al no depender tanto de la tecnología, los estudiantes pueden desarrollar habilidades para resolver problemas de manera más creativa y con recursos más variados.</span></p>
<p><span style="font-weight: 400;">A pesar de estas ventajas, también es importante considerar cómo se implementa la prohibición de los dispositivos móviles, ya que en algunos casos pueden ser herramientas útiles para el aprendizaje que bajo la supervisión de los profesores puedan ayudar al aprendizaje en determinar áreas o tareas.</span></p>'
  },
  {
    slug: 'ventajas-de-evitar-el-uso-de-moviles-en-conciertos',
    title: 'Conciertos sin teléfonos o "Phone-Free Events"',
    excerpt: 'El uso de bolsas PhoneRelax para evitar el uso de móviles en conciertos tiene varias ventajas significativas como por ejemplo una experiencia más inmersiva ya que los asistentes al concierto podrán disfrutar plenamente de la música, la atmósfera y la conexión con el artista y otros asistentes. Este ',
    image_url: '/images/blog/phonerelax-para-eventos.jpg',
    published_on: '2024-01-05',
    body: '<div class="flex-1 overflow-hidden">
<div class="react-scroll-to-bottom--css-tzuiv-79elbk h-full">
<div class="react-scroll-to-bottom--css-tzuiv-1n7m0yu">
<div class="flex flex-col pb-9 text-sm">
<div class="w-full text-token-text-primary">
<div class="px-4 py-2 justify-center text-base md:gap-6 m-auto">
<div class="flex flex-1 text-base mx-auto gap-3 md:px-5 lg:px-1 xl:px-5 md:max-w-3xl lg:max-w-[40rem] xl:max-w-[48rem] group final-completion">
<div class="relative flex w-full flex-col lg:w-[calc(100%-115px)] agent-turn">
<div class="flex-col gap-1 md:gap-3">
<div class="flex flex-grow flex-col max-w-full">
<div class="min-h-[20px] text-message flex flex-col items-start gap-3 whitespace-pre-wrap break-words [.text-message+&amp;]:mt-5 overflow-x-auto">
<div class="markdown prose w-full break-words dark:prose-invert dark">
<p>El uso de bolsas PhoneRelax para evitar el uso de móviles en conciertos tiene varias ventajas significativas como por ejemplo una <strong>experiencia más inmersiva</strong> ya que los asistentes al concierto podrán disfrutar plenamente de la música, la atmósfera y la conexión con el artista y otros asistentes.</p>
<p></p>
<p>Este tipo de eventos ya se conocen como "phone free events" o "experiencias libres de móviles"</p>
<p>Una de las principales ventajas es el<strong> respeto hacia el artista </strong>pues usar el teléfono puede distraer tanto al público como al artista. Evitar el uso de móviles muestra respeto hacia el trabajo del músico y permite que todos disfruten plenamente del espectáculo sin interrupciones.</p>
<p>Es conocido el caso de la cantante Adele solicitando a un asistente de su concierto que parara de grabar y disfrutara del show en vivo.</p>
<p></p>
<p>Por otro lado, los asistentes al concierto al no estar absortos en las pantallas <strong>mejoran la conexión interpersonal</strong>, es decir, es más probable que interactúen con las personas a tu alrededor, fomentando conexiones humanas reales y posiblemente compartiendo momentos significativos con otros fans.</p>
<p>Otro punto fundamental es la<strong> mejora en la calidad del sonido y la visión del artista</strong>, ya que al levantar el teléfono móvil para grabar o tomar fotos, a menudo se bloquea la vista de otras personas y se puede reducir la calidad del sonido pero sobretodo la visión directa del artista o del evento. Como ejemplo podemos ver estas imágenes de las celebraciones del Año Nuevo en París donde prácticamente todos los asistentes están grabando con sus teléfonos móviles:</p>
<p></p>
<p>Y por último, pero no menos importante,<strong> generar memorias más auténticas,</strong> pues en lugar de capturar todo el concierto en la pantalla del teléfono móvil, es mejor disfrutar del momento y guardar los recuerdos en tu mente para crear memorias más vívidas y auténticas que perduren a largo plazo.</p>
<p>Aunque es comprensible querer capturar algunos momentos del concierto, limitar el uso del móvil puede enriquecer significativamente la experiencia tanto para uno mismo como para los demás asistentes.</p>
<p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>
</div>'
  },
  {
    slug: 'y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas',
    title: 'Cómo evitar el uso de teléfonos en los institutos',
    excerpt: 'Las bolsas con cierres magnéticos PhoneRelax, diseñadas para que los propios alumnos guarden sus móviles y no tengan acceso a ellos en zonas designadas pueden ser una herramienta eficaz para controlar el uso de dispositivos electrónicos en entornos escolares. Estas bolsas ofrecen ventajas muy claras',
    image_url: '/images/blog/hiding-mobile-kid.jpg',
    published_on: '2024-01-05',
    body: '<p><span style="font-weight: 400;">Las bolsas con cierres magnéticos PhoneRelax, diseñadas para que los propios alumnos guarden sus móviles y no tengan acceso a ellos en zonas designadas pueden ser una herramienta eficaz para controlar el uso de dispositivos electrónicos en entornos escolares. Estas bolsas ofrecen ventajas muy claras:</span></p>
<p><span style="font-weight: 400;"><strong>Seguridad y control:</strong> Al utilizar cierres magnéticos que impiden el acceso al teléfono mientras está guardado, se garantiza un mayor nivel de seguridad y control sobre el dispositivo durante el horario escolar.</span></p>
<p><span style="font-weight: 400;"><strong>Prevención de distracciones:</strong> Al no poder acceder fácilmente a los teléfonos, se minimiza la tentación y la posibilidad de distracciones en el aula, lo que puede mejorar el enfoque de los estudiantes en el aprendizaje. Disponemos incluso de una versión de la bolsa PhoneRelax que deja sin cobertura móvil al teléfono previniendo que aunque el alumno se olvide de silenciar su móvil pueda recibir llamadas o notificaciones entrantes de las aplicaciones.</span></p>
<p><span style="font-weight: 400;"><strong>Uniformidad y facilidad de gestión:</strong> Si todos los estudiantes utilizan las bolsas PhoneRelax sefacilitar la gestión para los profesores y el personal escolar, manteniendo un sistema uniforme y claro para todos.</span></p>
<p><span style="font-weight: 400;"><strong>Custodia por parte de los alumnos de los teléfonos en sus bolsas PhoneRelax:</strong> Al confiar a los estudiantes la responsabilidad de guardar sus propios teléfonos en las bolsas PhoneRelax se evita cualquier problema relacionado con posibles daños en los dispositivos liberando así de la responsabilidad a profesores y personal escolar.</span></p>
<p><span style="font-weight: 400;">Sin embargo, es importante considerar algunos aspectos:</span></p>
<p><span style="font-weight: 400;"><strong>Necesidades específicas:</strong> Algunos estudiantes pueden tener necesidades particulares para acceder a sus teléfonos debido a emergencias médicas o familiares. Siempre debería haber cierta flexibilidad para atender estas situaciones.</span></p>'
  },
]
blog_posts.each do |attrs|
  post = Post.find_or_initialize_by(slug: attrs[:slug])
  post.update!(attrs)
end
puts "Artículos: #{Post.count}"
