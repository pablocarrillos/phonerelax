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
    images: [ '/images/products/funda-signalblocking-frontal.jpg', '/images/products/funda-signalblocking-trasera.jpg' ]
  },
  {
    shopify_handle: 'iman-phonerelax',
    name: 'Imán PhoneRelax',
    price: '59.90',
    schools_only: true, # solo centros educativos, nunca particulares
    image_url: '/images/products/iman-1.jpg',
    description: '<p>Permite la apertura de las bolsas PhoneRelax simplemente acercando la parte redondeada de la cerradura de la bolsa al centro del imán.</p>
<p>El imán dispone de cuatro agujeros pensados para poder fijarlo en cualquier superficie y así evitar que pueda perderse o que se mueva durante el proceso de apertura de las bolsas PhoneRelax.</p>',
    position: 2,
    images: [ '/images/products/iman-1.jpg', '/images/products/iman-2.jpg' ]
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
    images: [ '/images/products/funda-1.jpg', '/images/products/funda-2.jpg' ]
  }
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
admin.password_confirmation = 'phonerelax-admin'
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
  }
]
blog_posts.each do |attrs|
  post = Post.find_or_initialize_by(slug: attrs[:slug])
  post.update!(attrs)
end
puts "Artículos: #{Post.count}"

# --- Traducciones al portugués (pt-PT). Idempotente: vacío = se muestra el español. ---
product_translations = {
  'funda-phonerelax-version-sin-cobertura-movil' => {
    name_pt: 'Bolsa PhoneRelax SignalBlocking (bloqueia a rede móvel)',
    description_pt: '<p>A PhoneRelax é uma bolsa magnética para telemóveis pensada para evitar que alunos ou utilizadores se distraiam com o telemóvel em escolas, concertos ou eventos privados. O seu funcionamento é muito simples: basta introduzir o telemóvel no interior e fechar o fecho para que fique selado lá dentro. Para retirar o telemóvel será necessário aproximar o fecho magnético da bolsa PhoneRelax de um dos nossos ímanes especiais de abertura e retirá-lo.</p>
<p><strong>A principal vantagem desta versão que bloqueia a rede móvel é que o utilizador não será distraído com notificações, toques de chamada ou vibrações caso se tenha esquecido de silenciar ou desligar o telemóvel antes de o introduzir na bolsa PhoneRelax; assim, também não terá a ansiedade e a distração que geram as notificações constantes das diferentes aplicações.</strong></p>
<p><strong>Especificações técnicas:</strong></p>
<p><strong>Dimensões do produto:</strong> 12 cm largura x 26 cm altura x 4,5 cm profundidade<br><strong>Material:</strong> 30% neopreno, 40% poliéster, 20% alumínio e 10% plástico.<br><strong>Telemóveis compatíveis:</strong> qualquer smartphone com ecrã até 6,8 polegadas.<br><strong>Cor:</strong> preto<br><strong>Peso:</strong> 115 g</p>'
  },
  'iman-phonerelax' => {
    name_pt: 'Íman PhoneRelax',
    description_pt: '<p>Permite a abertura das bolsas PhoneRelax simplesmente aproximando a parte arredondada do fecho da bolsa do centro do íman.</p>
<p>O íman dispõe de quatro furos pensados para o fixar em qualquer superfície e assim evitar que se possa perder ou mover durante o processo de abertura das bolsas PhoneRelax.</p>'
  },
  'funda-phonerelax' => {
    name_pt: 'Bolsa PhoneRelax',
    description_pt: '<p>A PhoneRelax é uma bolsa magnética para telemóveis pensada para evitar que alunos ou utilizadores se distraiam com o telemóvel em escolas, concertos ou eventos privados. O seu funcionamento é muito simples: basta introduzir o telemóvel no interior e fechar o fecho para que fique selado lá dentro. Para retirar o telemóvel será necessário aproximar o fecho magnético da bolsa PhoneRelax de um dos nossos ímanes especiais de abertura e retirá-lo.</p>
<p><strong>Especificações técnicas:</strong></p>
<p><strong>Dimensões do produto:</strong> 12 cm largura x 24 cm altura x 4,5 cm profundidade<br><strong>Material:</strong> 40% neopreno, 50% poliéster e 10% plástico.<br><strong>Telemóveis compatíveis:</strong> qualquer smartphone com ecrã até 6,8 polegadas.<br><strong>Cor:</strong> preto<br><strong>Peso:</strong> 82 g</p>'
  }
}
product_translations.each { |handle, attrs| Product.find_by(shopify_handle: handle)&.update!(attrs) }

post_translations = {
  'cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas' => {
    title_pt: 'Vantagens de controlar o uso de telemóveis na sala de aula',
    excerpt_pt: 'Controlar o uso de telemóveis nas escolas para crianças e adolescentes através das bolsas PhoneRelax tem várias vantagens claras, entre as quais se destaca o fomento do foco académico. Sem distrações dos telemóveis, os estudantes tendem a prestar mais atenção',
    body_pt: '<p>Controlar o uso de telemóveis nas escolas para crianças e adolescentes através das bolsas PhoneRelax tem várias vantagens claras, entre as quais se destaca o <strong>fomento do foco académico</strong>. Sem distrações dos telemóveis, os estudantes tendem a prestar mais atenção nas aulas, o que pode melhorar o seu rendimento académico. É um facto que a menos distrações há uma maior concentração e, sem a tentação constante de verificar o telemóvel, os estudantes conseguem concentrar-se mais nas tarefas e atividades escolares, o que melhora a sua capacidade de atenção.</p>
<p>Outra vantagem é a <strong>melhoria na interação social</strong>: ao limitar o uso de telemóveis, promove-se a interação cara a cara entre os estudantes, fortalecendo as suas competências sociais e a sua capacidade de trabalhar em equipa.</p>
<p>Demonstrou-se também que <strong>reduz o cyberbullying</strong>, já que restringir o uso de dispositivos eletrónicos pode diminuir os casos de assédio online e o acesso a conteúdos inapropriados, ajudando a criar um ambiente escolar mais seguro.</p>
<p>No recreio proporciona um <strong>maior tempo de atividade física</strong>, pois, sem o uso constante de dispositivos, os estudantes podem ter mais tempo para atividades físicas, o que é benéfico para a sua saúde e bem-estar.</p>
<p>Uma vantagem da limitação do uso dos telemóveis nas escolas é o <strong>desenvolvimento de competências de resolução de problemas</strong>, pois, ao não dependerem tanto da tecnologia, os estudantes podem desenvolver competências para resolver problemas de forma mais criativa e com recursos mais variados.</p>
<p>Apesar destas vantagens, é também importante considerar como se implementa a proibição dos dispositivos móveis, já que em alguns casos podem ser ferramentas úteis para a aprendizagem que, sob a supervisão dos professores, podem ajudar em determinadas áreas ou tarefas.</p>'
  },
  'ventajas-de-evitar-el-uso-de-moviles-en-conciertos' => {
    title_pt: 'Concertos sem telemóveis ou "Phone-Free Events"',
    excerpt_pt: 'O uso de bolsas PhoneRelax para evitar o uso de telemóveis em concertos tem várias vantagens significativas, como por exemplo uma experiência mais imersiva, já que os espectadores poderão desfrutar plenamente da música, da atmosfera e da ligação com o artista e os restantes assistentes.',
    body_pt: '<p>O uso de bolsas PhoneRelax para evitar o uso de telemóveis em concertos tem várias vantagens significativas, como por exemplo uma <strong>experiência mais imersiva</strong>, já que os espectadores poderão desfrutar plenamente da música, da atmosfera e da ligação com o artista e os restantes assistentes.</p>
<p>Este tipo de eventos já é conhecido como "phone free events" ou "experiências livres de telemóveis".</p>
<p>Uma das principais vantagens é o <strong>respeito pelo artista</strong>, pois usar o telemóvel pode distrair tanto o público como o artista. Evitar o uso de telemóveis mostra respeito pelo trabalho do músico e permite que todos desfrutem plenamente do espetáculo sem interrupções.</p>
<p>É conhecido o caso da cantora Adele a pedir a um espectador do seu concerto que parasse de gravar e desfrutasse do espetáculo ao vivo.</p>
<p>Por outro lado, ao não estarem absortos nos ecrãs, os espectadores <strong>melhoram a ligação interpessoal</strong>: é mais provável que interajam com as pessoas à sua volta, fomentando ligações humanas reais e partilhando momentos significativos com outros fãs.</p>
<p>Outro ponto fundamental é a <strong>melhoria na qualidade do som e na visão do artista</strong>, já que ao levantar o telemóvel para gravar ou tirar fotografias muitas vezes se bloqueia a vista de outras pessoas e se reduz a qualidade do som, mas sobretudo a visão direta do artista ou do evento.</p>
<p>E por último, mas não menos importante, <strong>criar memórias mais autênticas</strong>: em vez de captar todo o concerto no ecrã do telemóvel, é melhor desfrutar do momento e guardar as recordações na mente para criar memórias mais vívidas e autênticas que perdurem a longo prazo.</p>
<p>Embora seja compreensível querer captar alguns momentos do concerto, limitar o uso do telemóvel pode enriquecer significativamente a experiência tanto para si como para os restantes assistentes.</p>
<p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>'
  },
  'y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas' => {
    title_pt: 'Como evitar o uso de telemóveis nas escolas',
    excerpt_pt: 'As bolsas com fecho magnético PhoneRelax, concebidas para que os próprios alunos guardem os seus telemóveis e não tenham acesso a eles em zonas designadas, podem ser uma ferramenta eficaz para controlar o uso de dispositivos eletrónicos em ambientes escolares. Estas bolsas oferecem vantagens muito claras',
    body_pt: '<p>As bolsas com fecho magnético PhoneRelax, concebidas para que os próprios alunos guardem os seus telemóveis e não tenham acesso a eles em zonas designadas, podem ser uma ferramenta eficaz para controlar o uso de dispositivos eletrónicos em ambientes escolares. Estas bolsas oferecem vantagens muito claras:</p>
<p><strong>Segurança e controlo:</strong> ao utilizar fechos magnéticos que impedem o acesso ao telemóvel enquanto está guardado, garante-se um maior nível de segurança e controlo sobre o dispositivo durante o horário escolar.</p>
<p><strong>Prevenção de distrações:</strong> ao não ser possível aceder facilmente aos telemóveis, minimiza-se a tentação e a possibilidade de distrações na sala de aula, o que pode melhorar o foco dos estudantes na aprendizagem. Dispomos inclusive de uma versão da bolsa PhoneRelax que deixa o telemóvel sem rede, evitando que, mesmo que o aluno se esqueça de silenciar o telemóvel, este receba chamadas ou notificações das aplicações.</p>
<p><strong>Uniformidade e facilidade de gestão:</strong> se todos os estudantes utilizarem as bolsas PhoneRelax, facilita-se a gestão para os professores e o pessoal escolar, mantendo um sistema uniforme e claro para todos.</p>
<p><strong>Custódia dos telemóveis pelos próprios alunos nas suas bolsas PhoneRelax:</strong> ao confiar aos estudantes a responsabilidade de guardar os seus próprios telemóveis nas bolsas PhoneRelax, evita-se qualquer problema relacionado com possíveis danos nos dispositivos, libertando dessa responsabilidade os professores e o pessoal escolar.</p>
<p>No entanto, é importante considerar alguns aspetos:</p>
<p><strong>Necessidades específicas:</strong> alguns estudantes podem ter necessidades particulares de acesso aos seus telemóveis devido a emergências médicas ou familiares. Deve haver sempre alguma flexibilidade para atender a estas situações.</p>'
  }
}
post_translations.each { |slug, attrs| Post.find_by(slug: slug)&.update!(attrs) }
puts "Traducciones PT: #{Product.where.not(name_pt: [ nil, '' ]).count} productos, #{Post.where.not(title_pt: [ nil, '' ]).count} artículos"

# --- Traducciones al inglés (en). Idempotente: vacío = se muestra el español. ---
product_translations_en = {
  'funda-phonerelax-version-sin-cobertura-movil' => {
    name_en: 'PhoneRelax SignalBlocking pouch (blocks mobile signal)',
    description_en: <<~HTML
      <p>PhoneRelax is a magnetic pouch for mobile phones designed to prevent students or users from getting distracted by their phone in schools, concerts or private events. It's very simple to use: put the phone inside and close its lock so it stays sealed within. To take the phone out, bring the magnetic lock of the PhoneRelax pouch close to one of our special opening magnets and remove the phone.</p>
      <p><strong>The main advantage of this version that blocks the mobile signal is that the user won't be distracted by notifications, ringtones or vibrations if they forgot to silence or turn off their phone before putting it in the PhoneRelax pouch; this way the user also avoids the anxiety and distraction caused by the constant notifications from different apps.</strong></p>
      <p><strong>Technical specifications:</strong></p>
      <p><strong>Product dimensions:</strong> 12 cm wide x 26 cm high x 4.5 cm deep<br><strong>Material:</strong> 30% neoprene, 40% polyester, 20% aluminium and 10% plastic.<br><strong>Compatible phones:</strong> any smartphone with a screen up to 6.8 inches.<br><strong>Colour:</strong> black<br><strong>Weight:</strong> 115 g</p>
    HTML
  },
  'iman-phonerelax' => {
    name_en: 'PhoneRelax magnet',
    description_en: <<~HTML
      <p>It lets the PhoneRelax pouches be opened simply by bringing the rounded part of the pouch's lock close to the centre of the magnet.</p>
      <p>The magnet has four holes designed to fix it to any surface, preventing it from being lost or from moving during the process of opening the PhoneRelax pouches.</p>
    HTML
  },
  'funda-phonerelax' => {
    name_en: 'PhoneRelax pouch',
    description_en: <<~HTML
      <p>PhoneRelax is a magnetic pouch for mobile phones designed to prevent students or users from getting distracted by their phone in schools, concerts or private events. It's very simple to use: put the phone inside and close its lock so it stays sealed within. To take the phone out, bring the magnetic lock of the PhoneRelax pouch close to one of our special opening magnets and remove the phone.</p>
      <p><strong>Technical specifications:</strong></p>
      <p><strong>Product dimensions:</strong> 12 cm wide x 24 cm high x 4.5 cm deep<br><strong>Material:</strong> 40% neoprene, 50% polyester and 10% plastic.<br><strong>Compatible phones:</strong> any smartphone with a screen up to 6.8 inches.<br><strong>Colour:</strong> black<br><strong>Weight:</strong> 82 g</p>
    HTML
  }
}
product_translations_en.each { |handle, attrs| Product.find_by(shopify_handle: handle)&.update!(attrs) }

post_translations_en = {
  'cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas' => {
    title_en: 'Benefits of controlling mobile phone use in the classroom',
    excerpt_en: 'Controlling the use of mobile phones in schools for children and teenagers through PhoneRelax pouches has several clear benefits, mainly the promotion of academic focus. Without phone distractions, students tend to pay more attention',
    body_en: <<~HTML
      <p>Controlling the use of mobile phones in schools for children and teenagers through PhoneRelax pouches has several clear benefits, mainly the <strong>promotion of academic focus</strong>. Without phone distractions, students tend to pay more attention in class, which can improve their academic performance. It's a fact that fewer distractions mean greater concentration, and without the constant temptation to check their phone, students can focus more on schoolwork and activities, improving their attention span.</p>
      <p>Another benefit is the <strong>improvement in social interaction</strong>: by limiting phone use, face-to-face interaction between students is encouraged, strengthening their social skills and their ability to work as a team.</p>
      <p>It has also been shown to <strong>reduce cyberbullying</strong>, since restricting the use of electronic devices can decrease cases of online harassment and access to inappropriate content, helping to create a safer school environment.</p>
      <p>In the playground it leads to <strong>more physical activity time</strong>, since without the constant use of devices, students have more time for physical activities, which is good for their health and wellbeing.</p>
      <p>One benefit of limiting phone use in schools is the <strong>development of problem-solving skills</strong>, since by not relying so much on technology, students can develop skills to solve problems more creatively and with more varied resources.</p>
      <p>Despite these benefits, it's also important to consider how the ban on mobile devices is implemented, since in some cases they can be useful learning tools that, under the supervision of teachers, can support learning in certain areas or tasks.</p>
    HTML
  },
  'ventajas-de-evitar-el-uso-de-moviles-en-conciertos' => {
    title_en: 'Phone-free concerts or "Phone-Free Events"',
    excerpt_en: 'Using PhoneRelax pouches to prevent phone use at concerts has several significant benefits, such as a more immersive experience, since attendees can fully enjoy the music, the atmosphere and the connection with the artist and the other attendees.',
    body_en: <<~HTML
      <p>Using PhoneRelax pouches to prevent phone use at concerts has several significant benefits, such as a <strong>more immersive experience</strong>, since attendees can fully enjoy the music, the atmosphere and the connection with the artist and the other attendees.</p>
      <p>These events are already known as "phone free events" or "phone-free experiences".</p>
      <p>One of the main benefits is <strong>respect for the artist</strong>, since using your phone can distract both the audience and the artist. Avoiding phone use shows respect for the musician's work and lets everyone fully enjoy the show without interruptions.</p>
      <p>The well-known case of singer Adele asking an attendee at her concert to stop recording and enjoy the show live comes to mind.</p>
      <p>On the other hand, by not being absorbed in their screens, attendees <strong>improve interpersonal connection</strong>: they are more likely to interact with the people around them, fostering real human connections and sharing meaningful moments with other fans.</p>
      <p>Another key point is the <strong>improvement in sound quality and the view of the artist</strong>, since raising your phone to record or take photos often blocks other people's view and can reduce sound quality, but above all the direct view of the artist or the event.</p>
      <p>And last but not least, <strong>creating more authentic memories</strong>: instead of capturing the whole concert on your phone screen, it's better to enjoy the moment and keep the memories in your mind to create more vivid and authentic memories that last over time.</p>
      <p>While it's understandable to want to capture some moments of the concert, limiting phone use can significantly enrich the experience both for yourself and for the other attendees.</p>
      <p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
    HTML
  },
  'y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas' => {
    title_en: 'How to prevent phone use in secondary schools',
    excerpt_en: 'PhoneRelax magnetic-lock pouches, designed so that students themselves store their phones and cannot access them in designated areas, can be an effective tool for controlling the use of electronic devices in school environments. These pouches offer very clear benefits',
    body_en: <<~HTML
      <p>PhoneRelax magnetic-lock pouches, designed so that students themselves store their phones and cannot access them in designated areas, can be an effective tool for controlling the use of electronic devices in school environments. These pouches offer very clear benefits:</p>
      <p><strong>Safety and control:</strong> by using magnetic locks that prevent access to the phone while it's stored, a higher level of safety and control over the device during school hours is guaranteed.</p>
      <p><strong>Preventing distractions:</strong> by not being able to easily access phones, the temptation and the possibility of distractions in the classroom are minimised, which can improve students' focus on learning. We even offer a version of the PhoneRelax pouch that leaves the phone without mobile signal, preventing it from receiving calls or app notifications even if the student forgets to silence it.</p>
      <p><strong>Uniformity and ease of management:</strong> if all students use PhoneRelax pouches, management becomes easier for teachers and school staff, keeping a uniform and clear system for everyone.</p>
      <p><strong>Students keeping custody of their phones in their PhoneRelax pouches:</strong> by entrusting students with the responsibility of storing their own phones in the PhoneRelax pouches, any problem related to possible damage to the devices is avoided, freeing teachers and school staff from that responsibility.</p>
      <p>However, it's important to consider some aspects:</p>
      <p><strong>Specific needs:</strong> some students may have particular needs to access their phones due to medical or family emergencies. There should always be some flexibility to handle these situations.</p>
    HTML
  }
}
post_translations_en.each { |slug, attrs| Post.find_by(slug: slug)&.update!(attrs) }
puts "Traducciones EN: #{Product.where.not(name_en: [ nil, '' ]).count} productos, #{Post.where.not(title_en: [ nil, '' ]).count} artículos"

# --- Traducciones al francés (fr). Idempotente: vacío = se muestra el español. ---
product_translations_fr = {
  'funda-phonerelax-version-sin-cobertura-movil' => {
    name_fr: 'Pochette PhoneRelax SignalBlocking (bloque le réseau mobile)',
    description_fr: <<~HTML
      <p>PhoneRelax est une pochette magnétique pour téléphones portables conçue pour éviter que les élèves ou les utilisateurs ne se laissent distraire par leur téléphone dans les écoles, les concerts ou les événements privés. Son fonctionnement est très simple : placez le téléphone à l'intérieur et fermez son verrou pour qu'il reste scellé dedans. Pour récupérer le téléphone, il suffit d'approcher le verrou magnétique de la pochette PhoneRelax de l'un de nos aimants spéciaux d'ouverture et de le retirer.</p>
      <p><strong>Le principal avantage de cette version qui bloque le réseau mobile est que l'utilisateur ne sera pas distrait par des notifications, des sonneries ou des vibrations s'il a oublié de mettre son téléphone en silencieux ou de l'éteindre avant de le placer dans la pochette PhoneRelax ; il évite ainsi l'anxiété et la distraction générées par les notifications constantes des différentes applications.</strong></p>
      <p><strong>Caractéristiques techniques :</strong></p>
      <p><strong>Dimensions du produit :</strong> 12 cm de largeur x 26 cm de hauteur x 4,5 cm de profondeur<br><strong>Matériau :</strong> 30 % néoprène, 40 % polyester, 20 % aluminium et 10 % plastique.<br><strong>Téléphones compatibles :</strong> tout smartphone avec un écran jusqu'à 6,8 pouces.<br><strong>Couleur :</strong> noir<br><strong>Poids :</strong> 115 g</p>
    HTML
  },
  'iman-phonerelax' => {
    name_fr: 'Aimant PhoneRelax',
    description_fr: <<~HTML
      <p>Il permet l'ouverture des pochettes PhoneRelax en approchant simplement la partie arrondie du verrou de la pochette du centre de l'aimant.</p>
      <p>L'aimant dispose de quatre trous conçus pour le fixer sur n'importe quelle surface, évitant ainsi qu'il ne se perde ou ne bouge pendant l'ouverture des pochettes PhoneRelax.</p>
    HTML
  },
  'funda-phonerelax' => {
    name_fr: 'Pochette PhoneRelax',
    description_fr: <<~HTML
      <p>PhoneRelax est une pochette magnétique pour téléphones portables conçue pour éviter que les élèves ou les utilisateurs ne se laissent distraire par leur téléphone dans les écoles, les concerts ou les événements privés. Son fonctionnement est très simple : placez le téléphone à l'intérieur et fermez son verrou pour qu'il reste scellé dedans. Pour récupérer le téléphone, il suffit d'approcher le verrou magnétique de la pochette PhoneRelax de l'un de nos aimants spéciaux d'ouverture et de le retirer.</p>
      <p><strong>Caractéristiques techniques :</strong></p>
      <p><strong>Dimensions du produit :</strong> 12 cm de largeur x 24 cm de hauteur x 4,5 cm de profondeur<br><strong>Matériau :</strong> 40 % néoprène, 50 % polyester et 10 % plastique.<br><strong>Téléphones compatibles :</strong> tout smartphone avec un écran jusqu'à 6,8 pouces.<br><strong>Couleur :</strong> noir<br><strong>Poids :</strong> 82 g</p>
    HTML
  }
}
product_translations_fr.each { |handle, attrs| Product.find_by(shopify_handle: handle)&.update!(attrs) }

post_translations_fr = {
  'cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas' => {
    title_fr: "Les avantages d'encadrer l'usage du téléphone en classe",
    excerpt_fr: "Encadrer l'usage des téléphones portables à l'école pour les enfants et les adolescents grâce aux pochettes PhoneRelax présente plusieurs avantages évidents, à commencer par le renforcement de la concentration scolaire. Sans les distractions du téléphone, les élèves ont tendance à être plus attentifs",
    body_fr: <<~HTML
      <p>Encadrer l'usage des téléphones portables à l'école pour les enfants et les adolescents grâce aux pochettes PhoneRelax présente plusieurs avantages évidents, à commencer par le <strong>renforcement de la concentration scolaire</strong>. Sans les distractions du téléphone, les élèves ont tendance à être plus attentifs en classe, ce qui peut améliorer leurs résultats. C'est un fait : moins de distractions signifie une plus grande concentration et, sans la tentation constante de consulter le téléphone, les élèves peuvent se concentrer davantage sur les travaux et les activités scolaires, ce qui améliore leur capacité d'attention.</p>
      <p>Un autre avantage est l'<strong>amélioration des interactions sociales</strong> : en limitant l'usage des téléphones, on favorise les échanges en face à face entre les élèves, renforçant leurs compétences sociales et leur capacité à travailler en équipe.</p>
      <p>Il a également été démontré que cela <strong>réduit le cyberharcèlement</strong>, car restreindre l'usage des appareils électroniques peut diminuer les cas de harcèlement en ligne et l'accès à des contenus inappropriés, contribuant à créer un environnement scolaire plus sûr.</p>
      <p>Dans la cour, cela se traduit par <strong>plus de temps d'activité physique</strong> : sans l'usage constant des appareils, les élèves ont plus de temps pour les activités physiques, ce qui est bénéfique pour leur santé et leur bien-être.</p>
      <p>Un avantage de la limitation de l'usage des téléphones dans les écoles et les collèges est le <strong>développement des capacités de résolution de problèmes</strong> : en dépendant moins de la technologie, les élèves peuvent apprendre à résoudre les problèmes de manière plus créative et avec des ressources plus variées.</p>
      <p>Malgré ces avantages, il est aussi important de réfléchir à la manière de mettre en œuvre l'interdiction des appareils mobiles, car dans certains cas ils peuvent être des outils utiles pour l'apprentissage qui, sous la supervision des enseignants, peuvent aider dans certaines matières ou activités.</p>
    HTML
  },
  'ventajas-de-evitar-el-uso-de-moviles-en-conciertos' => {
    title_fr: 'Des concerts sans téléphones ou « Phone-Free Events »',
    excerpt_fr: "L'utilisation des pochettes PhoneRelax pour éviter l'usage des téléphones pendant les concerts présente plusieurs avantages significatifs, comme une expérience plus immersive : les spectateurs peuvent profiter pleinement de la musique, de l'ambiance et de la connexion avec l'artiste et les autres spectateurs.",
    body_fr: <<~HTML
      <p>L'utilisation des pochettes PhoneRelax pour éviter l'usage des téléphones pendant les concerts présente plusieurs avantages significatifs, comme une <strong>expérience plus immersive</strong> : les spectateurs peuvent profiter pleinement de la musique, de l'ambiance et de la connexion avec l'artiste et les autres spectateurs.</p>
      <p>Ce type d'événements est déjà connu sous le nom de « phone free events » ou « expériences sans téléphones ».</p>
      <p>L'un des principaux avantages est le <strong>respect de l'artiste</strong> : utiliser son téléphone peut distraire aussi bien le public que l'artiste. Éviter l'usage des téléphones témoigne du respect pour le travail du musicien et permet à tous de profiter pleinement du spectacle sans interruptions.</p>
      <p>On connaît le cas de la chanteuse Adele demandant à un spectateur de son concert d'arrêter de filmer et de profiter du spectacle en direct.</p>
      <p>Par ailleurs, en n'étant pas absorbés par les écrans, les spectateurs <strong>améliorent leurs liens interpersonnels</strong> : ils sont plus susceptibles d'interagir avec les personnes qui les entourent, favorisant des connexions humaines réelles et le partage de moments significatifs avec d'autres fans.</p>
      <p>Un autre point fondamental est l'<strong>amélioration de la qualité du son et de la vue sur l'artiste</strong> : lever son téléphone pour filmer ou prendre des photos bloque souvent la vue des autres et peut réduire la qualité du son, mais surtout la vision directe de l'artiste ou de l'événement.</p>
      <p>Et enfin, mais non des moindres, <strong>créer des souvenirs plus authentiques</strong> : plutôt que de capturer tout le concert sur l'écran du téléphone, mieux vaut profiter du moment et garder les souvenirs en mémoire pour créer des souvenirs plus vivants et authentiques qui durent dans le temps.</p>
      <p>Même s'il est compréhensible de vouloir immortaliser quelques moments du concert, limiter l'usage du téléphone peut enrichir considérablement l'expérience, pour soi-même comme pour les autres spectateurs.</p>
      <p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
    HTML
  },
  'y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas' => {
    title_fr: "Comment éviter l'usage des téléphones au collège et au lycée",
    excerpt_fr: "Les pochettes à verrou magnétique PhoneRelax, conçues pour que les élèves rangent eux-mêmes leur téléphone sans pouvoir y accéder dans les zones désignées, peuvent être un outil efficace pour encadrer l'usage des appareils électroniques en milieu scolaire. Ces pochettes offrent des avantages très clairs",
    body_fr: <<~HTML
      <p>Les pochettes à verrou magnétique PhoneRelax, conçues pour que les élèves rangent eux-mêmes leur téléphone sans pouvoir y accéder dans les zones désignées, peuvent être un outil efficace pour encadrer l'usage des appareils électroniques en milieu scolaire. Ces pochettes offrent des avantages très clairs :</p>
      <p><strong>Sécurité et contrôle :</strong> grâce aux verrous magnétiques qui empêchent d'accéder au téléphone tant qu'il est rangé, on garantit un meilleur niveau de sécurité et de contrôle sur l'appareil pendant le temps scolaire.</p>
      <p><strong>Prévention des distractions :</strong> en ne pouvant pas accéder facilement aux téléphones, on réduit la tentation et le risque de distractions en classe, ce qui peut améliorer la concentration des élèves sur les apprentissages. Nous proposons même une version de la pochette PhoneRelax qui laisse le téléphone sans réseau, évitant qu'il ne reçoive des appels ou des notifications même si l'élève a oublié de le mettre en silencieux.</p>
      <p><strong>Uniformité et facilité de gestion :</strong> si tous les élèves utilisent les pochettes PhoneRelax, la gestion devient plus simple pour les enseignants et le personnel, avec un système uniforme et clair pour tous.</p>
      <p><strong>La garde des téléphones par les élèves eux-mêmes dans leurs pochettes PhoneRelax :</strong> en confiant aux élèves la responsabilité de ranger leur propre téléphone dans les pochettes PhoneRelax, on évite tout problème lié à d'éventuels dommages aux appareils, libérant de cette responsabilité les enseignants et le personnel scolaire.</p>
      <p>Il est cependant important de prendre en compte certains aspects :</p>
      <p><strong>Besoins spécifiques :</strong> certains élèves peuvent avoir des besoins particuliers d'accès à leur téléphone en raison d'urgences médicales ou familiales. Une certaine flexibilité doit toujours exister pour répondre à ces situations.</p>
    HTML
  }
}
post_translations_fr.each { |slug, attrs| Post.find_by(slug: slug)&.update!(attrs) }
puts "Traducciones FR: #{Product.where.not(name_fr: [ nil, '' ]).count} productos, #{Post.where.not(title_fr: [ nil, '' ]).count} artículos"

# --- Artículo de blog: normativa del móvil en las aulas en España (es/pt/en). Idempotente. ---
normativa = Post.find_or_initialize_by(slug: 'normativa-movil-aulas-espana')
normativa.assign_attributes(
  image_url: '/images/blog/normativa-movil-aulas.jpg',
  published_on: '2026-07-15',
  title: 'Normativa sobre el uso del móvil en las aulas en España',
  excerpt: 'El uso del móvil en las aulas está cada vez más restringido en España, pero la normativa depende de cada comunidad autónoma. Te contamos quién regula, las diferencias entre Primaria y Secundaria, y cómo aplicar la norma en el día a día del centro.',
  # La versión portuguesa habla de la normativa de Portugal (no de la española).
  slug_pt: 'regras-telemovel-escolas-portugal',
  title_pt: 'Regras sobre o uso do telemóvel nas escolas em Portugal',
  excerpt_pt: 'Portugal proíbe por lei o uso do smartphone na escola até ao 6.º ano e vai alargar a restrição até ao 9.º ano em 2027. Explicamos o que diz o Decreto-Lei n.º 95/2025, as exceções previstas e como aplicar a regra no dia a dia da escola.',
  slug_en: 'mobile-phone-rules-classrooms-spain',
  title_en: 'Mobile phone rules in classrooms in Spain',
  excerpt_en: 'Mobile phone use in classrooms is increasingly restricted in Spain, but the rules depend on each autonomous community. We explain who regulates it, the differences between primary and secondary, and how to apply the rule day to day.',
  # La versión francesa habla de la normativa de Francia (no de la española).
  slug_fr: 'reglementation-telephone-portable-ecole-france',
  title_fr: "Réglementation sur l'usage du téléphone portable à l'école en France",
  excerpt_fr: "La France interdit le téléphone portable à l'école et au collège depuis 2018, et la « pause numérique » se généralise depuis la rentrée 2025. Nous vous expliquons ce que dit la loi, les exceptions prévues et comment l'appliquer au quotidien.",
  # La versión sueca habla de la ley sueca de escuelas sin móviles (no de la española).
  slug_sv: 'mobilforbud-skolan-sverige',
  title_sv: 'Mobilförbud i skolan: vad den nya lagen i Sverige innebär',
  excerpt_sv: 'Sedan den 1 augusti 2026 är svenska grundskolor mobilfria enligt lag: elevernas mobiler samlas in vid skoldagens början och lämnas tillbaka vid dess slut. Vi förklarar vilka skolformer som omfattas, vilka undantag som finns och hur regeln kan tillämpas i vardagen utan att lärarna blir mobilvakter.',
  # La versión alemana habla de la normativa de Alemania (no de la española).
  slug_de: 'handyregeln-schulen-deutschland',
  title_de: 'Regeln zur Handynutzung an Schulen in Deutschland',
  excerpt_de: 'In Deutschland ist Bildung Ländersache: Ein bundesweites Handyverbot gibt es nicht, aber seit dem Schuljahr 2025/26 haben mehrere Bundesländer verbindliche Verbote eingeführt. Wir erklären, wer was regelt und wie sich die Regeln im Schulalltag umsetzen lassen.',
  body: <<~HTML_ES,
    <p>El uso del móvil en clase se ha convertido en uno de los grandes debates de la comunidad educativa en España. En los últimos años, la mayoría de las administraciones educativas han pasado de la recomendación a la <strong>restricción</strong>, y muchos centros buscan la mejor forma de aplicarla en el día a día.</p>
    <h2>¿Quién regula el uso del móvil en los colegios?</h2>
    <p>En España, la educación es una <strong>competencia transferida a las comunidades autónomas</strong>. Esto significa que no existe una única ley estatal que prohíba el móvil en todos los centros por igual: cada comunidad establece su propia normativa y, dentro de ese marco, cada centro concreta las reglas en su reglamento de régimen interior.</p>
    <p>El <strong>Consejo Escolar del Estado</strong> se ha pronunciado a favor de limitar el uso de dispositivos en las aulas, y ese consenso se ha ido trasladando a la mayoría de las comunidades.</p>
    <h2>La tendencia: de la recomendación a la prohibición</h2>
    <p>La dirección es clara: cada vez más comunidades restringen o prohíben el móvil en los centros educativos. Galicia fue de las primeras en limitarlo en las aulas y, en los últimos cursos, se ha sumado la mayor parte del territorio, con normas que van desde la prohibición total hasta el uso exclusivamente pedagógico y supervisado.</p>
    <h2>Primaria y Secundaria: reglas distintas</h2>
    <p>Aunque cada comunidad tiene sus matices, el patrón más habitual es:</p>
    <ul>
      <li><strong>Infantil y Primaria:</strong> prohibición general del uso del móvil durante toda la jornada, incluidos los recreos.</li>
      <li><strong>ESO y Bachillerato:</strong> prohibición como norma, con posibles <strong>excepciones para uso pedagógico</strong> cuando lo indica el profesorado y siempre bajo su supervisión.</li>
    </ul>
    <h2>El reto no es la norma, es aplicarla</h2>
    <p>Aprobar la norma es la parte fácil; el reto está en cumplirla sin convertir al profesorado en vigilante. Las soluciones más comunes —apagar el móvil, dejarlo en la mochila o depositarlo en una caja del aula— generan dudas: ¿quién se responsabiliza si un teléfono se daña o desaparece? ¿Cómo se evita que el alumno lo consulte a escondidas?</p>
    <h2>Cómo lo resuelve PhoneRelax</h2>
    <p>Con las bolsas magnéticas <strong>PhoneRelax</strong>, cada alumno guarda su propio teléfono en una bolsa que se sella y solo se abre acercándola al imán del centro. Así:</p>
    <ul>
      <li>Es <strong>el propio alumno quien custodia su móvil</strong>: el centro no se hace responsable de posibles daños.</li>
      <li>La versión <strong>SignalBlocking</strong> deja el teléfono sin cobertura ni wifi, evitando notificaciones o su uso a escondidas, especialmente útil en exámenes.</li>
      <li>Es un sistema <strong>uniforme y sencillo</strong> para todo el centro, fácil de aplicar cada día.</li>
    </ul>
    <h2>Antes de decidir</h2>
    <p>La normativa concreta depende de cada comunidad autónoma y puede cambiar de un curso a otro, así que conviene consultar la de tu región y reflejarla en el reglamento del centro. Si buscas una forma práctica de cumplirla, <a href="/colegios">PhoneRelax para colegios</a> te ayuda a crear aulas sin distracciones. ¿Necesitas equipar varias aulas? <a href="/presupuesto">Pide presupuesto</a>.</p>
  HTML_ES
  body_pt: <<~HTML_PT,
    <p>O uso do telemóvel na sala de aula deixou de ser apenas um debate para passar a ser <strong>lei</strong> em Portugal. Desde o ano letivo de 2025/26, os alunos mais novos não podem usar o smartphone na escola, e a restrição vai alargar-se nos próximos anos. Explicamos o que diz a norma e como aplicá-la no dia a dia.</p>
    <h2>O que diz a lei portuguesa?</h2>
    <p>O <strong>Decreto-Lei n.º 95/2025, de 14 de agosto</strong>, proíbe a utilização de smartphones e de outros dispositivos com acesso à internet pelos alunos do <strong>1.º e 2.º ciclos do ensino básico (até ao 6.º ano)</strong> em todas as escolas — públicas, privadas e cooperativas — durante todo o horário escolar, incluindo os intervalos e os períodos não letivos.</p>
    <p>Há exceções pontuais, mediante autorização: necessidades pedagógicas, razões de saúde devidamente comprovadas ou tradução. Os telemóveis básicos sem acesso à internet continuam a ser permitidos para contactar a família em caso de necessidade.</p>
    <h2>A proibição alarga-se até ao 9.º ano em 2027</h2>
    <p>Os resultados foram considerados um sucesso: nas escolas que aplicaram a restrição, a socialização aumentou 36% e a disciplina melhorou 13%, segundo os estudos divulgados. Com base nisso, o Governo aprovou alargar a proibição ao <strong>3.º ciclo (7.º ao 9.º ano)</strong> a partir de <strong>1 de janeiro de 2027</strong>, com o primeiro período do ano letivo 2026/27 como fase de adaptação.</p>
    <h2>E no ensino secundário?</h2>
    <p>No secundário não existe, para já, uma proibição nacional: <strong>cada escola define as suas regras no regulamento interno</strong>. Muitas optam por restringir o uso na sala de aula e nos momentos de avaliação, e as escolas frequentadas simultaneamente por alunos do 3.º ciclo e do secundário terão de harmonizar as regras entre os dois níveis.</p>
    <h2>O desafio não é a regra, é aplicá-la</h2>
    <p>Aprovar a regra é a parte fácil; o desafio está em cumpri-la sem transformar o professor em vigilante. As soluções mais comuns — desligar o telemóvel, deixá-lo na mochila ou colocá-lo numa caixa da sala — geram dúvidas: quem se responsabiliza se um telemóvel se danifica ou desaparece? Como se evita que o aluno o consulte às escondidas?</p>
    <h2>Como a PhoneRelax resolve isto</h2>
    <p>Com as bolsas magnéticas <strong>PhoneRelax</strong>, cada aluno guarda o seu próprio telemóvel numa bolsa que se sela e só abre aproximando-a do íman da escola. Assim:</p>
    <ul>
      <li>É <strong>o próprio aluno que guarda o seu telemóvel</strong>: a escola não se responsabiliza por eventuais danos.</li>
      <li>A versão <strong>SignalBlocking</strong> deixa o telemóvel sem rede nem wifi, evitando notificações ou o uso às escondidas, especialmente útil em exames.</li>
      <li>É um sistema <strong>uniforme e simples</strong> para toda a escola, fácil de aplicar todos os dias.</li>
    </ul>
    <h2>Antes de decidir</h2>
    <p>A regulamentação está a evoluir de ano para ano — o alargamento ao 9.º ano é a prova disso — por isso convém acompanhar as novidades e refletir as regras no regulamento interno da escola. Se procura uma forma prática de as cumprir, a <a href="/pt/escolas">PhoneRelax para escolas</a> ajuda a criar salas de aula sem distrações. Precisa de equipar várias salas? <a href="/pt/orcamento">Peça orçamento</a>.</p>
  HTML_PT
  body_en: <<~HTML_EN,
    <p>Mobile phone use in class has become one of the biggest debates in Spain's education community. In recent years, most education authorities have moved from recommendation to <strong>restriction</strong>, and many schools are looking for the best way to apply it day to day.</p>
    <h2>Who regulates phone use in schools?</h2>
    <p>In Spain, education is a <strong>power devolved to the autonomous communities</strong>. This means there is no single national law banning phones in every school in the same way: each community sets its own rules and, within that framework, each school spells out the details in its internal regulations.</p>
    <p>The <strong>State School Council</strong> has come out in favour of limiting the use of devices in classrooms, and that consensus has spread to most communities.</p>
    <h2>The trend: from recommendation to ban</h2>
    <p>The direction is clear: more and more communities are restricting or banning phones in schools. Galicia was one of the first to limit it in classrooms, and in recent school years most of the country has followed, with rules ranging from a total ban to strictly educational, supervised use.</p>
    <h2>Primary and secondary: different rules</h2>
    <p>Although each community has its own nuances, the most common pattern is:</p>
    <ul>
      <li><strong>Pre-school and primary:</strong> a general ban on phone use throughout the day, including breaks.</li>
      <li><strong>Secondary:</strong> a ban as the rule, with possible <strong>exceptions for educational use</strong> when the teacher decides and always under their supervision.</li>
    </ul>
    <h2>The challenge isn't the rule, it's enforcing it</h2>
    <p>Passing the rule is the easy part; the challenge is enforcing it without turning teachers into watchmen. The most common solutions — turning the phone off, leaving it in the backpack or dropping it in a classroom box — raise doubts: who is liable if a phone is damaged or goes missing? How do you stop a student from secretly checking it?</p>
    <h2>How PhoneRelax solves it</h2>
    <p>With <strong>PhoneRelax</strong> magnetic pouches, each student stores their own phone in a pouch that seals and only opens by bringing it close to the school's magnet. This way:</p>
    <ul>
      <li><strong>Each student keeps their own phone</strong>: the school is not liable for any damage.</li>
      <li>The <strong>SignalBlocking</strong> version leaves the phone with no reception or wifi, preventing notifications or secret use, especially useful during exams.</li>
      <li>It's a <strong>uniform, simple</strong> system for the whole school, easy to apply every day.</li>
    </ul>
    <h2>Before you decide</h2>
    <p>The specific rules depend on each autonomous community and can change from one school year to the next, so it's worth checking your region's and reflecting it in your school's regulations. If you're looking for a practical way to comply, <a href="/en/schools">PhoneRelax for schools</a> helps you create distraction-free classrooms. Need to equip several classrooms? <a href="/en/quote">Request a quote</a>.</p>
  HTML_EN
  body_fr: <<~HTML_FR,
    <p>La France a été pionnière en Europe : le téléphone portable est <strong>interdit à l'école et au collège depuis 2018</strong>, et depuis la rentrée 2025 la « pause numérique » généralise la mise à l'écart physique des téléphones dans les collèges. Voici ce que dit la réglementation et comment l'appliquer au quotidien.</p>
    <h2>Ce que dit la loi</h2>
    <p>La <strong>loi du 3 août 2018</strong> (article L511-5 du code de l'éducation) interdit l'utilisation du téléphone portable par les élèves dans les <strong>écoles maternelles, les écoles élémentaires et les collèges</strong>, pendant toute activité d'enseignement et dans l'ensemble de l'enceinte scolaire. Le règlement intérieur peut prévoir des exceptions, notamment pour des usages pédagogiques encadrés, et des aménagements existent pour les élèves présentant un handicap ou un besoin de santé.</p>
    <h2>La « pause numérique » généralisée au collège</h2>
    <p>Après une expérimentation menée en 2024-2025 auprès de plus de 32 000 collégiens — avec des effets positifs sur le climat scolaire, la concentration et le bien-être, et une baisse des signalements de cyberharcèlement —, la <strong>circulaire du 10 juillet 2025</strong> généralise le dispositif « Portable en pause » à l'ensemble des collèges publics dès l'année 2025-2026 : le téléphone doit être <strong>physiquement mis à l'écart pendant toute la journée</strong>, et chaque collège choisit la modalité (casiers, boîtes, pochettes…) en concertation avec la communauté éducative.</p>
    <h2>Et au lycée ?</h2>
    <p>Au lycée, il n'existe pas d'interdiction nationale : le <strong>règlement intérieur</strong> peut interdire l'utilisation du téléphone dans tout ou partie de l'enceinte de l'établissement. De nombreux lycées la restreignent en classe et pendant les examens.</p>
    <h2>Le défi n'est pas la règle, c'est de l'appliquer</h2>
    <p>Adopter la règle est la partie facile ; le défi est de la faire respecter sans transformer les enseignants en surveillants. Les solutions habituelles — éteindre le téléphone, le laisser dans le sac ou le déposer dans une boîte — soulèvent des questions : qui est responsable si un téléphone est endommagé ou disparaît ? Comment éviter qu'un élève le consulte en cachette ?</p>
    <h2>La réponse PhoneRelax</h2>
    <p>Avec les pochettes magnétiques <strong>PhoneRelax</strong>, chaque élève range son propre téléphone dans une pochette qui se scelle et ne s'ouvre qu'en l'approchant de l'aimant de l'établissement. Ainsi :</p>
    <ul>
      <li>C'est <strong>l'élève lui-même qui garde son téléphone</strong> : l'établissement n'est pas responsable d'éventuels dommages — une modalité parfaitement compatible avec la « pause numérique ».</li>
      <li>La version <strong>SignalBlocking</strong> laisse le téléphone sans réseau ni wifi, évitant les notifications ou l'usage en cachette, particulièrement utile pendant les examens.</li>
      <li>C'est un système <strong>uniforme et simple</strong> pour tout l'établissement, facile à appliquer chaque jour.</li>
    </ul>
    <h2>Avant de décider</h2>
    <p>La réglementation évolue d'une rentrée à l'autre — la généralisation de la « pause numérique » en est la preuve — il convient donc de suivre les nouveautés et de les refléter dans le règlement intérieur de l'établissement. Si vous cherchez un moyen pratique de les appliquer, <a href="/fr/ecoles">PhoneRelax pour les établissements scolaires</a> vous aide à créer des classes sans distractions. Besoin d'équiper plusieurs classes ? <a href="/fr/devis">Demandez un devis</a>.</p>
  HTML_FR
  body_de: <<~HTML_DE,
    <p>Die Handynutzung im Unterricht ist auch in Deutschland eines der großen Bildungsthemen. In den letzten Jahren sind viele Bundesländer von Empfehlungen zu <strong>verbindlichen Regeln</strong> übergegangen, und viele Schulen suchen nach dem besten Weg, sie im Alltag umzusetzen.</p>
    <h2>Wer regelt die Handynutzung an Schulen?</h2>
    <p>In Deutschland ist Bildung <strong>Ländersache</strong>. Es gibt also kein bundesweites Gesetz, das Handys an allen Schulen gleich regelt: Jedes Bundesland setzt seinen eigenen Rahmen, und innerhalb dieses Rahmens konkretisiert jede Schule die Regeln in ihrer Haus- bzw. Schulordnung.</p>
    <h2>Der Trend: von der Empfehlung zum Verbot</h2>
    <p>Die Richtung ist klar: Immer mehr Bundesländer schränken die private Handynutzung an Schulen ein. Seit dem Schuljahr 2025/26 gilt in <strong>Hessen</strong> ein generelles Verbot der privaten Nutzung auf dem gesamten Schulgelände — den ganzen Schultag, inklusive Pausen („handyfreie Schutzzonen“). <strong>Bayern</strong> regelt die Handynutzung bereits seit 2006 gesetzlich und weitet das Verbot aus; auch <strong>Bremen, Sachsen, Schleswig-Holstein und Thüringen</strong> haben verbindliche gesetzliche Verbote. <strong>Baden-Württemberg und Nordrhein-Westfalen</strong> verpflichten ihre Schulen, über die Schulkonferenz verbindliche Regeln zu beschließen; in den übrigen Ländern entscheiden die Schulen selbst.</p>
    <h2>Grundschule und weiterführende Schulen: unterschiedliche Regeln</h2>
    <p>Auch wenn jedes Bundesland seine Besonderheiten hat, ist das häufigste Muster:</p>
    <ul>
      <li><strong>Grundschule:</strong> generelles Verbot der privaten Handynutzung während des gesamten Schultags, einschließlich der Pausen.</li>
      <li><strong>Weiterführende Schulen:</strong> Verbot als Regel, mit möglichen <strong>Ausnahmen für die unterrichtliche Nutzung</strong>, wenn die Lehrkraft es anordnet und beaufsichtigt.</li>
    </ul>
    <h2>Die Herausforderung ist nicht die Regel, sondern ihre Umsetzung</h2>
    <p>Die Regel zu beschließen ist der einfache Teil; die Herausforderung ist, sie durchzusetzen, ohne die Lehrkräfte zu Aufsehern zu machen. Die üblichen Lösungen — Handy ausschalten, im Ranzen lassen oder in eine Kiste legen — werfen Fragen auf: Wer haftet, wenn ein Handy beschädigt wird oder verschwindet? Wie verhindert man die heimliche Nutzung?</p>
    <h2>Die PhoneRelax-Lösung</h2>
    <p>Mit den magnetischen <strong>PhoneRelax</strong>-Taschen verwahrt jeder Schüler sein eigenes Handy in einer Tasche, die versiegelt wird und sich nur am Magneten der Schule öffnen lässt. Das bedeutet:</p>
    <ul>
      <li><strong>Der Schüler verwahrt sein Handy selbst</strong>: Die Schule haftet nicht für etwaige Schäden — und niemand muss Geräte einsammeln.</li>
      <li>Die <strong>SignalBlocking</strong>-Version lässt das Handy ohne Empfang und WLAN und verhindert Benachrichtigungen oder heimliche Nutzung — besonders nützlich bei Prüfungen.</li>
      <li>Ein <strong>einheitliches, einfaches System</strong> für die ganze Schule, das sich jeden Tag leicht anwenden lässt.</li>
    </ul>
    <h2>Bevor Sie entscheiden</h2>
    <p>Die Regeln entwickeln sich von Schuljahr zu Schuljahr weiter — die neuen Ländergesetze sind der Beweis. Es lohnt sich, die Entwicklungen zu verfolgen und sie in der Schulordnung abzubilden. Wenn Sie einen praktischen Weg zur Umsetzung suchen: <a href="/de/schulen">PhoneRelax für Schulen</a> hilft Ihnen, ablenkungsfreie Klassenzimmer zu schaffen. Sie möchten mehrere Klassen ausstatten? <a href="/de/angebot">Fordern Sie ein Angebot an</a>.</p>
  HTML_DE
  body_sv: <<~HTML_SV
    <p>Mobilen i klassrummet har gått från att vara en fråga för varje skola till att bli <strong>lag</strong> i Sverige. Sedan den <strong>1 augusti 2026</strong> ska grundskolan vara mobilfri under hela skoldagen, efter ett beslut i riksdagen sommaren 2026. Vi går igenom vad regeln säger, vilka undantag som finns och hur den kan tillämpas i vardagen.</p>
    <h2>Vad säger den nya lagen?</h2>
    <p>Reglerna i skollagen innebär att elevernas mobiltelefoner <strong>ska samlas in vid skoldagens början och lämnas tillbaka vid skoldagens slut</strong>. Det handlar alltså inte längre om en rekommendation eller om varje skolas egna ordningsregler: mobilförbudet är <strong>nationellt och obligatoriskt</strong>, och det gäller hela skoldagen — lektioner såväl som raster.</p>
    <p>Syftet är att skapa <strong>studiero</strong>, minska stöket i klassrummen, skydda barn mot nätmobbning och få eleverna att umgås mer med varandra i stället för med skärmen.</p>
    <h2>Vilka skolformer omfattas?</h2>
    <p>Förbudet gäller de obligatoriska skolformerna och fritidshemmet, det vill säga:</p>
    <ul>
      <li><strong>Förskoleklassen</strong> och <strong>grundskolan</strong> (F–9), samt anpassade grundskolan, specialskolan och sameskolan.</li>
      <li><strong>Fritidshemmet</strong> och öppen fritidsverksamhet.</li>
    </ul>
    <p><strong>Gymnasieskolan omfattas inte</strong> av det obligatoriska förbudet. Där bestämmer skolan själv sina regler om mobiler — och många gymnasier väljer att införa mobilfria lektioner och prov på egen hand.</p>
    <h2>Undantagen</h2>
    <p>Lagen ger utrymme för undantag när det behövs. Rektorn kan besluta om undantag för enskilda elever med särskilda skäl, till exempel när mobilen behövs som <strong>stöd för en elev</strong> (medicinska skäl eller funktionsnedsättning), och en lärare kan låta eleverna använda mobilen <strong>i undervisningen</strong> när det ingår i lärarens planering. Vid utbildning utanför skolenheten, som utflykter, får rektorn eller läraren avstå från insamlingen om den skulle medföra betydande praktiska svårigheter.</p>
    <h2>Utmaningen är inte regeln, utan att tillämpa den</h2>
    <p>Att lagen finns är den enkla delen; utmaningen är att följa den varje dag utan att göra lärarna till mobilvakter. De vanligaste lösningarna — mobillådor, skåp eller «mobilhotell» i klassrummet — väcker frågor: vem ansvarar om en telefon skadas eller försvinner? Hur mycket tid går åt till att samla in och dela ut? Och hur undviker man att en elev tar tillbaka mobilen i smyg?</p>
    <h2>Så löser PhoneRelax det</h2>
    <p>Med de magnetiska <strong>PhoneRelax</strong>-fickorna förvarar varje elev sin egen telefon i en ficka som förseglas och bara kan öppnas mot skolans magnet. Det innebär att:</p>
    <ul>
      <li>Det är <strong>eleven själv som förvarar sin mobil</strong> — men utan att kunna använda den. Skolan behöver inte hantera eller ansvara för elevernas telefoner.</li>
      <li>Insamling och återlämning tar <strong>några sekunder</strong>: fickan förseglas på morgonen och öppnas med magneten vid skoldagens slut.</li>
      <li><strong>SignalBlocking</strong>-versionen lämnar telefonen utan täckning och wifi, så att inga notiser stör — särskilt användbart vid prov.</li>
      <li>Det är ett <strong>enhetligt och enkelt system</strong> för hela skolan, lätt att tillämpa varje dag och att förklara för elever och vårdnadshavare.</li>
    </ul>
    <h2>Innan ni bestämmer er</h2>
    <p>Reglerna är nya och kan komma att förtydligas av Skolverket och i skolornas egna skolregler, så det lönar sig att följa utvecklingen och beskriva rutinerna i skolans regler. Om ni söker ett praktiskt sätt att uppfylla lagen hjälper <a href="/sv/skolor">PhoneRelax för skolor</a> er att skapa mobilfria klassrum. Behöver ni utrusta flera klasser? <a href="/sv/offert">Begär en offert</a>.</p>
  HTML_SV
)
normativa.save!
puts "Artículo normativa: es/pt/en/fr/de/sv OK (posts: #{Post.count})"

# Tarifas de transporte por país (solo si aún no existen): base actual de la
# tienda — Península 5,95 €, Canarias y resto de la UE 13,95 € — editable desde el admin.
Order::EU_COUNTRIES.each do |country|
  ShippingRate.find_or_create_by!(country: country) do |rate|
    rate.base_cost = case country
    when "España (Península)" then BigDecimal("5.95")
    when "España (Baleares)" then BigDecimal("9.95")
    else BigDecimal("13.95")
    end
  end
end
puts "Tarifas de envío: #{ShippingRate.count} países"

# Productos solo para presupuestos (no visibles en la tienda pública).
lanyard = Product.find_or_create_by!(name: "Lanyard PhoneRelax") do |p|
  p.price = BigDecimal("1.95") # 1,6116 € sin IVA
  p.active = false
  p.stock = 0
  p.position = 90
end
if lanyard.description.blank?
  lanyard.update!(
    description: "<p>Lanyard PhoneRelax para colgar la bolsa. Fabricado en <strong>poliéster</strong> de <strong>6 mm de grosor</strong>.</p>",
    description_pt: "<p>Lanyard PhoneRelax para pendurar a bolsa. Fabricado em <strong>poliéster</strong> de <strong>6 mm de espessura</strong>.</p>",
    description_en: "<p>PhoneRelax lanyard to hang the pouch. Made of <strong>polyester</strong>, <strong>6 mm thick</strong>.</p>"
  )
end
dtf = Product.find_or_create_by!(name: "Personalización DTF funda") do |p|
  p.price = BigDecimal("1.51") # 1,25 € sin IVA
  p.active = false
  p.stock = 0
  p.position = 91
end
# La ficha del producto DTF muestra la muestra real de Villalkor en su galería.
if dtf.product_images.none?
  dtf.product_images.create!(url: "/images/personalizacion/colegio-villalkor.jpg", position: 1)
end
if dtf.description.blank?
  dtf.update!(
    description: "<p>Personalización DTF de la funda con tu logo o marca. <strong>Cantidad mínima: 25 unidades.</strong> Añade al carrito tantas unidades de personalización como bolsas PhoneRelax lleve tu pedido (SignalBlocking o no SignalBlocking).</p>",
    description_pt: "<p>Personalização DTF da bolsa com o seu logótipo ou marca. <strong>Quantidade mínima: 25 unidades.</strong> Adicione ao carrinho tantas unidades de personalização como bolsas PhoneRelax do seu pedido (SignalBlocking ou não SignalBlocking).</p>",
    description_en: "<p>DTF customisation of the pouch with your logo or brand. <strong>Minimum quantity: 25 units.</strong> Add as many customisation units to your cart as PhoneRelax pouches in your order (SignalBlocking or not).</p>"
  )
end

# Escalado de precios para presupuestos (precios SIN IVA por tramos de unidades).
sb    = Product.find_by(name: "Funda PhoneRelax SignalBlocking (bloquea cobertura móvil)")
iman  = Product.find_by(name: "Imán PhoneRelax")
basica = Product.find_by(name: "Funda PhoneRelax")
{
  sb => { 1 => "12.3554", 25 => "11.7376", 50 => "11.3669", 100 => "11.1198",
          250 => "10.5021", 500 => "9.8843", 1000 => "9.2665" },
  lanyard => { 1 => "1.6116", 25 => "1.5793", 50 => "1.5632", 100 => "1.531",
               250 => "1.4504", 500 => "1.3698", 1000 => "1.2893" },
  dtf => { 1 => "1.25", 25 => "1.225", 50 => "1.2125", 100 => "1.1875",
           250 => "1.125", 500 => "1.0625", 1000 => "1" },
  iman => { 1 => "49.5041", 10 => "45.5438", 25 => "43.5636", 50 => "42.0785", 100 => "40.5934" },
  # La funda básica hereda los mismos descuentos por tramo que la SignalBlocking
  # (5, 8, 10, 15, 20 y 25 %) aplicados a su precio sin IVA (9,95 € / 1,21).
  basica => { 1 => "8.2231", 25 => "7.8120", 50 => "7.5653", 100 => "7.4008",
              250 => "6.9897", 500 => "6.5785", 1000 => "6.1674" }
}.each do |product, tiers|
  next if product.nil? || product.price_tiers.exists?

  tiers.each { |units, price| product.price_tiers.create!(min_units: units, unit_price: BigDecimal(price)) }
end
puts "Escalado de precios: #{PriceTier.count} tramos en #{PriceTier.distinct.count(:product_id)} productos"

# Importación inicial del excel de muestras enviadas (solo la primera vez).
# La captura no incluía los productos de cada muestra: se añaden a mano al editarlas.
if Sample.none?
  [
    [ "Colegio Eduardo Pondal", "Tomás Rodriguez", "direccionpondal@gmail.com", "2025-08-28", nil, "preguntad" ],
    [ "Montcau-La Mola", "Cristina Abad", "cabad@montcaulamola.com", "2025-08-25", nil, "consulto si han tenido problema y si el cambio ha valido la pena" ],
    [ "IES Cañada Real", "Manuel Lorente", "mmlm152@educastillalamancha.es", "2025-07-03", "2025-10-15", nil ],
    [ "Salesianos", "Julio Alberto del Castillo", "julioalberto.delcastillo@salesianos.edu", "2025-07-19", nil, "próximo verano volverá a exponer" ],
    [ "IES San Isidro", "Roberto Riquelme", "rriquelme@educa.madrid.org", "2025-07-18", nil, "no contesta :(" ],
    [ "Norfolk", "María Muñoz", nil, "2025-07-25", nil, nil ],
    [ "Norfolk", "José María Vaquero", "josemaria.vaquerosanchez@colegionorfolk.es", "2025-07-25", nil, "indico cambio tamaño y pregunto para el próximo curso" ],
    [ "Salvador de Madariaga", "Rodrigo García-Muñoz", "ies.salvador.madariaga@edu.xunta.gal", "2025-07-17", nil, "no contesta" ],
    [ "Tienda", "Luis Manuel", "luis@kblex.es", "2025-07-17", "2026-07-12", nil ],
    [ "Colegio San Fernando", "Antonio José de la Rosa Martos", "direccion@colegiosanfernandogranada.es", "2025-07-02", nil, "pregunto estado" ],
    [ "Ayto. Denia", "Fátima Castellano", "fcastellano@ayto-denia.es", "2025-10-16", "2026-02-16", nil ],
    [ "Institut Escola Mirades", "Sílvia Martínez Grau", "direccio@escolamirades.cat", "2025-10-24", nil, "PAGADAS" ],
    [ "Colegio Las Chapas - ECOS", "Maila Piconi", "maila.piconi@laschapas-ecos.com", "2025-11-10", nil, nil ],
    [ "IES Agora", "Amalia Gil", "secretaria.ies.agora.alcobendas@educa.madrid.org", "2025-11-14", nil, nil ],
    [ "Liceo Francés Sevilla", "Joseph Hadjadj", "joseph.hadjadj@mlfmonde.org", "2025-12-09", nil, nil ],
    [ "Irlandesas Bami", "Sandra Campanela", "s.campanella.bami@feducativamaryward.org", "2025-12-18", nil, "pregunto estado y envío noticia" ],
    [ "Colegio Alemán de Las Palmas", "Martin Schweinsberg", "martin.schweinsberg@dslpa.org", "2026-01-09", nil, "pregunto si quieren presupuesto formal para el próximo curso" ],
    [ "Padre de colegio Liceo Francés", "Hubert", "hubert.dubrule@gmail.com", nil, nil, "le llegan 2 defectuosas y hacemos cambio" ],
    [ "Kensington School", "Duncan", "dgiles@kensingtonschoolbcn.com", nil, nil, nil ],
    [ "Colegio Reial Monestir de Santa Isabel", "María Cereceda", "mcereceda@rmsantaisabel.com", "2026-02-19", "2026-04-17", "pregunta por 35 bolsas y 2 imanes" ],
    [ "Insti. Cristo Rey Valladolid", "Jose Manuel Trillo Ruiz", "josemanueltr@cristoreyva.com", "2026-04-08", nil, nil ],
    [ "Instituto Solokoetxe", "Aintzane Saez de Guinoa", "2saez.ai@solokoetxebhi.net", nil, nil, nil ],
    [ "Casa Salesianas Elche", "Fini Lledó", nil, "2026-05-14", nil, nil ],
    [ "Ernesto Poveda", nil, nil, nil, nil, "datos y precios para Ernesto Poveda" ],
    [ "Baleares", "Laura Monzó", nil, "2026-05-14", nil, nil ],
    [ "Tomás Ordoñez", nil, nil, "2026-06-12", nil, nil ],
    [ "Alcorcón", "Jesús Carnicero", "jbarranco@andel.es", "2026-06-12", nil, nil ],
    [ "Sage College", "Laura Monzó", "laura.martin@sagecollege.eu", "2026-06-30", nil, nil ],
    [ "Laura Felices Cáceres", nil, "l.felices@slf.edu.es", "2026-07-07", nil, nil ],
    [ "Colegio Villaeuropa", "Luís Fernando Roldán", "direccion@colegio-villaeuropa.com", "2026-07-07", nil, nil ],
    [ "Mundo Estudiante", "Javier Errea", "j.errea@mundoestudiante.com", "2026-07-09", nil, nil ],
    [ "Setroc", nil, nil, "2026-07-21", nil, nil ],
    [ "Ayto. Peñíscola", "Cristina Castell", "ccastell@peniscola.org", "2026-07-22", nil, nil ],
    [ "IEC Miguel de Cervantes", nil, "18700441.edu@juntadeandalucia.es jromfer765@g.educaand.es", "2026-07-22", "2026-07-24", nil ]
  ].each do |organization, contact, email, sent, returned, notes|
    Sample.create!(organization: organization, contact_name: contact, email: email,
                   sent_on: sent, returned_on: returned, notes: notes)
  end
  puts "Muestras importadas del excel: #{Sample.count}"
end

# --- Traducciones al alemán (de). Idempotente: vacío = se muestra el español. ---
product_translations_de = {
  'funda-phonerelax-version-sin-cobertura-movil' => {
    name_de: 'PhoneRelax SignalBlocking-Tasche (blockiert das Mobilfunksignal)',
    description_de: <<~HTML
      <p>PhoneRelax ist eine magnetische Handytasche, die verhindert, dass sich Schüler oder Nutzer in Schulen, bei Konzerten oder privaten Veranstaltungen vom Handy ablenken lassen. Die Anwendung ist ganz einfach: Handy hineinlegen und den Verschluss schließen, damit es versiegelt bleibt. Zum Entnehmen halten Sie den Magnetverschluss der PhoneRelax-Tasche an einen unserer speziellen Öffnungsmagnete und nehmen das Handy heraus.</p>
      <p><strong>Der große Vorteil dieser Version mit Signalblockierung: Der Nutzer wird nicht durch Benachrichtigungen, Klingeltöne oder Vibrationen gestört, falls er vergessen hat, das Handy stummzuschalten oder auszuschalten, bevor er es in die PhoneRelax-Tasche legt — und auch die Unruhe durch ständige App-Benachrichtigungen entfällt.</strong></p>
      <p><strong>Technische Daten:</strong></p>
      <p><strong>Produktmaße:</strong> 12 cm Breite x 26 cm Höhe x 4,5 cm Tiefe<br><strong>Material:</strong> 30 % Neopren, 40 % Polyester, 20 % Aluminium und 10 % Kunststoff.<br><strong>Kompatible Handys:</strong> jedes Smartphone mit einem Display bis 6,8 Zoll.<br><strong>Farbe:</strong> schwarz<br><strong>Gewicht:</strong> 115 g</p>
    HTML
  },
  'iman-phonerelax' => {
    name_de: 'PhoneRelax-Magnet',
    description_de: <<~HTML
      <p>Er öffnet die PhoneRelax-Taschen, indem man einfach den abgerundeten Teil des Taschenverschlusses an die Mitte des Magneten hält.</p>
      <p>Der Magnet hat vier Löcher, um ihn auf jeder Oberfläche zu befestigen — so geht er nicht verloren und verrutscht nicht beim Öffnen der PhoneRelax-Taschen.</p>
    HTML
  },
  'funda-phonerelax' => {
    name_de: 'PhoneRelax-Tasche',
    description_de: <<~HTML
      <p>PhoneRelax ist eine magnetische Handytasche, die verhindert, dass sich Schüler oder Nutzer in Schulen, bei Konzerten oder privaten Veranstaltungen vom Handy ablenken lassen. Die Anwendung ist ganz einfach: Handy hineinlegen und den Verschluss schließen, damit es versiegelt bleibt. Zum Entnehmen halten Sie den Magnetverschluss der PhoneRelax-Tasche an einen unserer speziellen Öffnungsmagnete und nehmen das Handy heraus.</p>
      <p><strong>Technische Daten:</strong></p>
      <p><strong>Produktmaße:</strong> 12 cm Breite x 24 cm Höhe x 4,5 cm Tiefe<br><strong>Material:</strong> 40 % Neopren, 50 % Polyester und 10 % Kunststoff.<br><strong>Kompatible Handys:</strong> jedes Smartphone mit einem Display bis 6,8 Zoll.<br><strong>Farbe:</strong> schwarz<br><strong>Gewicht:</strong> 82 g</p>
    HTML
  }
}
product_translations_de.each { |handle, attrs| Product.find_by(shopify_handle: handle)&.update!(attrs) }

post_translations_de = {
  'cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas' => {
    title_de: 'Die Vorteile einer geregelten Handynutzung im Klassenzimmer',
    excerpt_de: 'Die Handynutzung an Schulen mit den PhoneRelax-Taschen zu regeln hat mehrere klare Vorteile — allen voran die Förderung der Konzentration. Ohne die Ablenkung durch das Handy sind Schülerinnen und Schüler im Unterricht deutlich aufmerksamer',
    body_de: <<~HTML
      <p>Die Handynutzung an Schulen für Kinder und Jugendliche mit den PhoneRelax-Taschen zu regeln hat mehrere klare Vorteile — allen voran die <strong>Förderung der Konzentration</strong>. Ohne die Ablenkung durch das Handy sind die Schülerinnen und Schüler im Unterricht aufmerksamer, was ihre Leistungen verbessern kann. Weniger Ablenkung bedeutet mehr Konzentration: Ohne die ständige Versuchung, aufs Handy zu schauen, können sich die Schüler besser auf Aufgaben und Aktivitäten konzentrieren und ihre Aufmerksamkeitsspanne verbessern.</p>
      <p>Ein weiterer Vorteil ist die <strong>bessere soziale Interaktion</strong>: Wird die Handynutzung begrenzt, sprechen die Schüler mehr von Angesicht zu Angesicht miteinander — das stärkt ihre sozialen Kompetenzen und die Teamfähigkeit.</p>
      <p>Nachweislich wird auch <strong>Cybermobbing reduziert</strong>: Die eingeschränkte Nutzung elektronischer Geräte kann Fälle von Online-Mobbing und den Zugang zu unangemessenen Inhalten verringern und so zu einem sichereren Schulumfeld beitragen.</p>
      <p>In der Pause bleibt <strong>mehr Zeit für Bewegung</strong>: Ohne die ständige Gerätenutzung haben die Schüler mehr Zeit für körperliche Aktivitäten — gut für Gesundheit und Wohlbefinden.</p>
      <p>Ein weiterer Vorteil der begrenzten Handynutzung an Schulen ist die <strong>Entwicklung von Problemlösekompetenzen</strong>: Wer sich weniger auf die Technik verlässt, lernt, Probleme kreativer und mit vielfältigeren Mitteln zu lösen.</p>
      <p>Bei allen Vorteilen ist auch wichtig, wie das Verbot mobiler Geräte umgesetzt wird — in manchen Fällen können sie unter Aufsicht der Lehrkräfte nützliche Lernwerkzeuge für bestimmte Fächer oder Aufgaben sein.</p>
    HTML
  },
  'ventajas-de-evitar-el-uso-de-moviles-en-conciertos' => {
    title_de: 'Konzerte ohne Handys oder „Phone-Free Events“',
    excerpt_de: 'PhoneRelax-Taschen bei Konzerten einzusetzen hat mehrere große Vorteile — zum Beispiel ein intensiveres Erlebnis: Das Publikum kann die Musik, die Atmosphäre und die Verbindung zum Künstler und zu den anderen Besuchern voll genießen.',
    body_de: <<~HTML
      <p>PhoneRelax-Taschen einzusetzen, um die Handynutzung bei Konzerten zu verhindern, hat mehrere große Vorteile — zum Beispiel ein <strong>intensiveres Erlebnis</strong>: Das Publikum kann die Musik, die Atmosphäre und die Verbindung zum Künstler und zu den anderen Besuchern voll genießen.</p>
      <p>Solche Veranstaltungen sind bereits als „Phone-Free Events“ oder „handyfreie Erlebnisse“ bekannt.</p>
      <p>Einer der wichtigsten Vorteile ist der <strong>Respekt vor dem Künstler</strong>: Die Handynutzung kann sowohl das Publikum als auch den Künstler ablenken. Auf das Handy zu verzichten zeigt Respekt vor der Arbeit des Musikers und lässt alle die Show ohne Unterbrechungen genießen.</p>
      <p>Bekannt ist der Fall der Sängerin Adele, die einen Besucher ihres Konzerts bat, mit dem Filmen aufzuhören und die Show live zu genießen.</p>
      <p>Wer nicht auf den Bildschirm starrt, verbessert außerdem die <strong>zwischenmenschliche Verbindung</strong>: Man kommt eher mit den Menschen um sich herum ins Gespräch, knüpft echte Kontakte und teilt besondere Momente mit anderen Fans.</p>
      <p>Ein weiterer zentraler Punkt ist die <strong>bessere Klangqualität und Sicht auf den Künstler</strong>: Wer das Handy zum Filmen oder Fotografieren hochhält, verdeckt oft die Sicht anderer und mindert die Klangqualität — vor allem aber den direkten Blick auf den Künstler oder das Event.</p>
      <p>Und nicht zuletzt: <strong>echtere Erinnerungen schaffen</strong>. Statt das ganze Konzert auf dem Handybildschirm festzuhalten, ist es besser, den Moment zu genießen und die Erinnerungen im Kopf zu bewahren — so entstehen lebendigere, authentischere Erinnerungen, die lange bleiben.</p>
      <p>Auch wenn es verständlich ist, einige Momente des Konzerts festhalten zu wollen: Die Handynutzung zu begrenzen kann das Erlebnis deutlich bereichern — für einen selbst und für alle anderen Besucher.</p>
      <p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
    HTML
  },
  'y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas' => {
    title_de: 'Wie man die Handynutzung an weiterführenden Schulen verhindert',
    excerpt_de: 'Die PhoneRelax-Taschen mit Magnetverschluss, bei denen die Schüler ihre Handys selbst verwahren, ohne in den festgelegten Bereichen darauf zugreifen zu können, sind ein wirksames Mittel, um die Nutzung elektronischer Geräte im Schulumfeld zu regeln. Die Vorteile sind eindeutig',
    body_de: <<~HTML
      <p>Die PhoneRelax-Taschen mit Magnetverschluss, bei denen die Schüler ihre Handys selbst verwahren, ohne in den festgelegten Bereichen darauf zugreifen zu können, sind ein wirksames Mittel, um die Nutzung elektronischer Geräte im Schulumfeld zu regeln. Die Vorteile sind eindeutig:</p>
      <p><strong>Sicherheit und Kontrolle:</strong> Der Magnetverschluss verhindert den Zugriff auf das Handy, solange es verwahrt ist — mehr Sicherheit und Kontrolle über das Gerät während der Schulzeit.</p>
      <p><strong>Weniger Ablenkung:</strong> Ist das Handy nicht leicht zugänglich, sinken Versuchung und Ablenkungsrisiko im Unterricht — die Schüler können sich besser aufs Lernen konzentrieren. Es gibt sogar eine Version der PhoneRelax-Tasche, die das Signal blockiert: Selbst wenn ein Schüler vergisst, sein Handy stummzuschalten, kommen weder Anrufe noch App-Benachrichtigungen durch.</p>
      <p><strong>Einheitlichkeit und einfache Verwaltung:</strong> Wenn alle Schüler PhoneRelax-Taschen benutzen, wird die Handhabung für Lehrkräfte und Schulpersonal einfacher — ein einheitliches, klares System für alle.</p>
      <p><strong>Die Schüler verwahren ihre Handys selbst in ihren PhoneRelax-Taschen:</strong> Wer den Schülern die Verantwortung für das eigene Handy überträgt, vermeidet jedes Problem mit möglichen Geräteschäden — und entlastet Lehrkräfte und Schulpersonal von dieser Verantwortung.</p>
      <p>Einige Punkte sollten dennoch bedacht werden:</p>
      <p><strong>Besondere Bedürfnisse:</strong> Manche Schüler müssen wegen medizinischer oder familiärer Notfälle auf ihr Handy zugreifen können. Für solche Situationen sollte es immer eine gewisse Flexibilität geben.</p>
    HTML
  }
}
post_translations_de.each { |slug, attrs| Post.find_by(slug: slug)&.update!(attrs) }
puts "Traducciones DE: #{Product.where.not(name_de: [ nil, '' ]).count} productos, #{Post.where.not(title_de: [ nil, '' ]).count} artículos"

# --- Traducciones al sueco (sv). Idempotente: vacío = se muestra el español. ---
product_translations_sv = {
  'funda-phonerelax-version-sin-cobertura-movil' => {
    name_sv: 'PhoneRelax SignalBlocking-ficka (blockerar mobilsignalen)',
    description_sv: <<~HTML
      <p>PhoneRelax är en magnetisk mobilficka som förhindrar att elever eller användare distraheras av telefonen i skolor, på gymnasier, konserter eller privata evenemang. Den är mycket enkel att använda: lägg mobilen i fickan och stäng låset så att den förseglas inuti. För att ta ut telefonen håller du PhoneRelax-fickans magnetlås mot en av våra speciella öppningsmagneter och tar ut telefonen.</p>
      <p><strong>Den största fördelen med den här versionen som blockerar mobilsignalen är att användaren inte störs av notiser, ringsignaler eller vibrationer om hen glömt att ljudlöst- eller stänga av telefonen innan den lades i PhoneRelax-fickan — och slipper därmed också den stress och distraktion som de ständiga notiserna från olika appar skapar.</strong></p>
      <p><strong>Tekniska specifikationer:</strong></p>
      <p><strong>Produktmått:</strong> 12 cm bredd x 26 cm höjd x 4,5 cm djup<br><strong>Material:</strong> 30 % neopren, 40 % polyester, 20 % aluminium och 10 % plast.<br><strong>Kompatibla telefoner:</strong> alla smartphones med en skärm på upp till 6,8 tum.<br><strong>Färg:</strong> svart<br><strong>Vikt:</strong> 115 g</p>
    HTML
  },
  'iman-phonerelax' => {
    name_sv: 'PhoneRelax-magnet',
    description_sv: <<~HTML
      <p>Öppnar PhoneRelax-fickorna genom att man helt enkelt håller den rundade delen av fickans lås mot magnetens mitt.</p>
      <p>Magneten har fyra hål för att kunna skruvas fast på valfri yta — så att den inte tappas bort eller flyttar sig när PhoneRelax-fickorna öppnas.</p>
    HTML
  },
  'funda-phonerelax' => {
    name_sv: 'PhoneRelax-ficka',
    description_sv: <<~HTML
      <p>PhoneRelax är en magnetisk mobilficka som förhindrar att elever eller användare distraheras av telefonen i skolor, på gymnasier, konserter eller privata evenemang. Den är mycket enkel att använda: lägg mobilen i fickan och stäng låset så att den förseglas inuti. För att ta ut telefonen håller du PhoneRelax-fickans magnetlås mot en av våra speciella öppningsmagneter och tar ut telefonen.</p>
      <p><strong>Tekniska specifikationer:</strong></p>
      <p><strong>Produktmått:</strong> 12 cm bredd x 24 cm höjd x 4,5 cm djup<br><strong>Material:</strong> 40 % neopren, 50 % polyester och 10 % plast.<br><strong>Kompatibla telefoner:</strong> alla smartphones med en skärm på upp till 6,8 tum.<br><strong>Färg:</strong> svart<br><strong>Vikt:</strong> 82 g</p>
    HTML
  }
}
product_translations_sv.each { |handle, attrs| Product.find_by(shopify_handle: handle)&.update!(attrs) }

# Productos creados desde el admin (sin shopify_handle): se localizan por su nombre en español.
product_translations_sv_by_name = {
  'Lanyard PhoneRelax' => {
    name_sv: 'PhoneRelax-lanyard',
    description_sv: '<div>PhoneRelax-lanyard för att hänga fickan. Tillverkad i <strong>polyester</strong>, <strong>6 mm tjock</strong>.<br>Längden går att justera, så att den passar både den som vill bära fickan runt halsen och den som vill bära den snett över axeln som en väska.</div>'
  },
  'Personalización DTF funda' => {
    name_sv: 'DTF-tryck på fickan',
    description_sv: '<div>DTF-tryck på fickan med er logotyp eller ert varumärke. <strong>Minsta antal: 25 stycken.</strong> Lägg lika många tryck i varukorgen som antalet PhoneRelax-fickor i er beställning (SignalBlocking eller inte).</div>'
  },
  'Pack 25 bolsas SignalBlocking + personalización DTF + 2 imanes' => {
    name_sv: 'Paket med 25 SignalBlocking-fickor + DTF-tryck + 2 magneter',
    description_sv: '<div>Paket för skolor: 25 PhoneRelax SignalBlocking-fickor med ert DTF-tryck och 2 magneter. Pris inklusive mängdrabatten för varje produkt.</div>'
  },
  'Pack 100 bolsas SignalBlocking + personalización DTF + 5 imanes' => {
    name_sv: 'Paket med 100 SignalBlocking-fickor + DTF-tryck + 5 magneter',
    description_sv: '<div>Paket för skolor: 100 PhoneRelax SignalBlocking-fickor med ert DTF-tryck och 5 magneter. Pris inklusive mängdrabatten för varje produkt.</div>'
  },
  'Funda PhoneRelax SignalBlocking con Tarjetero (bloquea cobertura móvil)' => {
    name_sv: 'PhoneRelax SignalBlocking-ficka med kortfack (blockerar mobilsignalen)',
    description_sv: <<~HTML
      <div>PhoneRelax är en magnetisk mobilficka som förhindrar att elever eller användare distraheras av telefonen i skolor, på gymnasier, konserter eller privata evenemang. Den är mycket enkel att använda: lägg mobilen i fickan och stäng låset så att den förseglas inuti. För att ta ut telefonen håller du PhoneRelax-fickans magnetlås mot en av våra speciella öppningsmagneter och tar ut telefonen.<br><br></div><div><strong>Den här versionen har ett kortfack med genomskinligt fönster på 10 cm bredd x 8 cm höjd.<br></strong><br></div><div><strong>Den största fördelen med den här versionen som blockerar mobilsignalen är att användaren inte störs av notiser, ringsignaler eller vibrationer om hen glömt att ljudlöst- eller stänga av telefonen innan den lades i PhoneRelax-fickan — och slipper därmed också den stress och distraktion som de ständiga notiserna från olika appar skapar.<br></strong><br></div><div><strong>Tekniska specifikationer:</strong></div><div><strong>Produktmått:</strong> 12,4 cm bredd x 28,5 cm höjd x 4,5 cm djup<br><strong>Material:</strong> 30 % neopren, 40 % polyester, 20 % aluminium och 10 % plast.<br><strong>Kompatibla telefoner:</strong> alla smartphones med en skärm på upp till 6,8 tum.<br><strong>Färg:</strong> svart<br><strong>Vikt:</strong> 115 g</div>
    HTML
  }
}
product_translations_sv_by_name.each { |name, attrs| Product.find_by(name: name)&.update!(attrs) }

post_translations_sv = {
  'cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas' => {
    title_sv: 'Fördelarna med att reglera mobilanvändningen i klassrummet',
    excerpt_sv: 'Att reglera mobilanvändningen i skolan med PhoneRelax-fickorna har flera tydliga fördelar — framför allt bättre koncentration. Utan mobilen som distraktion är eleverna betydligt mer uppmärksamma på lektionerna',
    body_sv: <<~HTML
      <p>Att reglera barns och ungdomars mobilanvändning i skolan med PhoneRelax-fickorna har flera tydliga fördelar — framför allt <strong>bättre koncentration</strong>. Utan mobilen som distraktion är eleverna mer uppmärksamma på lektionerna, vilket kan förbättra deras resultat. Färre distraktioner ger mer fokus: utan den ständiga frestelsen att titta på mobilen kan eleverna koncentrera sig bättre på uppgifter och aktiviteter och förbättra sin uppmärksamhetsförmåga.</p>
      <p>En annan fördel är <strong>bättre socialt samspel</strong>: när mobilanvändningen begränsas pratar eleverna mer med varandra ansikte mot ansikte — det stärker deras sociala färdigheter och förmågan att samarbeta.</p>
      <p>Det är också visat att <strong>nätmobbningen minskar</strong>: begränsad användning av elektroniska enheter kan minska fallen av mobbning på nätet och tillgången till olämpligt innehåll, och därmed bidra till en tryggare skolmiljö.</p>
      <p>På rasterna blir det <strong>mer tid för rörelse</strong>: utan ständig skärmanvändning har eleverna mer tid för fysisk aktivitet — bra för hälsan och välbefinnandet.</p>
      <p>Ytterligare en fördel med begränsad mobilanvändning i skolan är <strong>utvecklingen av problemlösningsförmåga</strong>: den som förlitar sig mindre på tekniken lär sig att lösa problem mer kreativt och med fler olika verktyg.</p>
      <p>Trots alla fördelar är det också viktigt hur mobilförbudet genomförs — i vissa fall kan enheterna, under lärarens ledning, vara användbara läromedel i särskilda ämnen eller uppgifter.</p>
    HTML
  },
  'ventajas-de-evitar-el-uso-de-moviles-en-conciertos' => {
    title_sv: 'Konserter utan mobiler, eller «phone-free events»',
    excerpt_sv: 'Att använda PhoneRelax-fickor på konserter har flera stora fördelar — till exempel en mer uppslukande upplevelse: publiken kan njuta fullt ut av musiken, stämningen och kontakten med artisten och de andra besökarna.',
    body_sv: <<~HTML
      <p>Att använda PhoneRelax-fickor för att förhindra mobilanvändning på konserter har flera stora fördelar — till exempel en <strong>mer uppslukande upplevelse</strong>: publiken kan njuta fullt ut av musiken, stämningen och kontakten med artisten och de andra besökarna.</p>
      <p>Sådana evenemang kallas redan «phone-free events» eller «mobilfria upplevelser».</p>
      <p>En av de viktigaste fördelarna är <strong>respekten för artisten</strong>: mobilanvändningen kan distrahera både publiken och artisten. Att lägga undan mobilen visar respekt för musikerns arbete och låter alla njuta av showen utan avbrott.</p>
      <p>Känt är fallet med sångerskan Adele, som bad en besökare på sin konsert att sluta filma och i stället njuta av showen på plats.</p>
      <p>Den som inte stirrar på skärmen förbättrar dessutom <strong>kontakten med andra människor</strong>: man pratar oftare med dem runt omkring, knyter äkta kontakter och delar speciella ögonblick med andra fans.</p>
      <p>En annan central punkt är <strong>bättre ljudkvalitet och sikt mot artisten</strong>: den som håller upp mobilen för att filma eller fotografera skymmer ofta sikten för andra och försämrar ljudkvaliteten — men framför allt den direkta upplevelsen av artisten eller evenemanget.</p>
      <p>Och inte minst: <strong>äktare minnen</strong>. I stället för att fånga hela konserten på mobilskärmen är det bättre att njuta av stunden och bevara minnena i huvudet — så skapas mer levande och autentiska minnen som stannar kvar länge.</p>
      <p>Även om det är förståeligt att vilja fånga några ögonblick av konserten kan en begränsad mobilanvändning berika upplevelsen avsevärt — för en själv och för alla andra besökare.</p>
      <p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
    HTML
  },
  'y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas' => {
    title_sv: 'Så förhindrar man mobilanvändning på högstadiet och gymnasiet',
    excerpt_sv: 'PhoneRelax-fickorna med magnetlås, där eleverna själva förvarar sina mobiler utan att kunna använda dem i de bestämda utrymmena, är ett effektivt sätt att reglera användningen av elektroniska enheter i skolmiljön. Fördelarna är tydliga',
    body_sv: <<~HTML
      <p>PhoneRelax-fickorna med magnetlås, där eleverna själva förvarar sina mobiler utan att kunna använda dem i de bestämda utrymmena, är ett effektivt sätt att reglera användningen av elektroniska enheter i skolmiljön. Fördelarna är tydliga:</p>
      <p><strong>Säkerhet och kontroll:</strong> magnetlåset förhindrar åtkomst till mobilen så länge den är förvarad — mer säkerhet och kontroll över enheten under skoltid.</p>
      <p><strong>Färre distraktioner:</strong> när mobilen inte är lätt att komma åt minskar frestelsen och risken för distraktioner på lektionerna — eleverna kan koncentrera sig bättre på lärandet. Det finns till och med en version av PhoneRelax-fickan som blockerar signalen: även om en elev glömmer att sätta mobilen på ljudlöst kommer varken samtal eller appnotiser fram.</p>
      <p><strong>Enhetlighet och enkel hantering:</strong> när alla elever använder PhoneRelax-fickor blir hanteringen enklare för lärare och skolpersonal — ett enhetligt och tydligt system för alla.</p>
      <p><strong>Eleverna förvarar själva sina mobiler i sina PhoneRelax-fickor:</strong> genom att ge eleverna ansvaret för sin egen mobil undviker man alla problem med eventuella skador på enheterna — och lärare och skolpersonal slipper det ansvaret.</p>
      <p>Några saker bör ändå tänkas igenom:</p>
      <p><strong>Särskilda behov:</strong> vissa elever behöver kunna komma åt sin mobil vid medicinska eller familjära nödsituationer. För sådana situationer bör det alltid finnas en viss flexibilitet.</p>
    HTML
  }
}
post_translations_sv.each { |slug, attrs| Post.find_by(slug: slug)&.update!(attrs) }
puts "Traducciones SV: #{Product.where.not(name_sv: [ nil, '' ]).count} productos, #{Post.where.not(title_sv: [ nil, '' ]).count} artículos"
