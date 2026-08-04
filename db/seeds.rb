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

# --- Artículo de blog: normativa del móvil en las aulas en España (es/pt/en). Idempotente. ---
normativa = Post.find_or_initialize_by(slug: 'normativa-movil-aulas-espana')
normativa.assign_attributes(
  image_url: '/images/blog/alumnos-con-telefono.jpg',
  published_on: '2026-07-15',
  title: 'Normativa sobre el uso del móvil en las aulas en España',
  excerpt: 'El uso del móvil en las aulas está cada vez más restringido en España, pero la normativa depende de cada comunidad autónoma. Te contamos quién regula, las diferencias entre Primaria y Secundaria, y cómo aplicar la norma en el día a día del centro.',
  slug_pt: 'regras-telemovel-salas-de-aula-espanha',
  title_pt: 'Regras sobre o uso do telemóvel nas salas de aula em Espanha',
  excerpt_pt: 'O uso do telemóvel nas salas de aula está cada vez mais restringido em Espanha, mas a regulamentação depende de cada comunidade autónoma. Explicamos quem regula, as diferenças entre o Primário e o Secundário e como aplicar a regra no dia a dia da escola.',
  slug_en: 'mobile-phone-rules-classrooms-spain',
  title_en: 'Mobile phone rules in classrooms in Spain',
  excerpt_en: 'Mobile phone use in classrooms is increasingly restricted in Spain, but the rules depend on each autonomous community. We explain who regulates it, the differences between primary and secondary, and how to apply the rule day to day.',
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
    <p>O uso do telemóvel na aula tornou-se um dos grandes debates da comunidade educativa em Espanha. Nos últimos anos, a maioria das administrações educativas passou da recomendação à <strong>restrição</strong>, e muitas escolas procuram a melhor forma de a aplicar no dia a dia.</p>
    <h2>Quem regula o uso do telemóvel nas escolas?</h2>
    <p>Em Espanha, a educação é uma <strong>competência transferida para as comunidades autónomas</strong>. Ou seja, não existe uma única lei estatal que proíba o telemóvel em todas as escolas da mesma forma: cada comunidade estabelece a sua própria regulamentação e, dentro desse enquadramento, cada escola concretiza as regras no seu regulamento interno.</p>
    <p>O <strong>Conselho Escolar do Estado</strong> pronunciou-se a favor de limitar o uso de dispositivos nas aulas, e esse consenso foi-se transferindo para a maioria das comunidades.</p>
    <h2>A tendência: da recomendação à proibição</h2>
    <p>A direção é clara: cada vez mais comunidades restringem ou proíbem o telemóvel nas escolas. A Galiza foi das primeiras a limitá-lo nas salas de aula e, nos últimos anos letivos, juntou-se a maior parte do território, com regras que vão da proibição total ao uso exclusivamente pedagógico e supervisionado.</p>
    <h2>Primário e Secundário: regras diferentes</h2>
    <p>Embora cada comunidade tenha as suas particularidades, o padrão mais habitual é:</p>
    <ul>
      <li><strong>Pré-escolar e Primário:</strong> proibição geral do uso do telemóvel durante todo o dia, incluindo os intervalos.</li>
      <li><strong>Secundário:</strong> proibição como regra, com possíveis <strong>exceções para uso pedagógico</strong> quando indicado pelo professor e sempre sob a sua supervisão.</li>
    </ul>
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
    <p>A regulamentação concreta depende de cada comunidade autónoma e pode mudar de um ano letivo para outro, por isso convém consultar a da sua região e refleti-la no regulamento da escola. Se procura uma forma prática de a cumprir, a <a href="/pt/colegios">PhoneRelax para escolas</a> ajuda a criar salas de aula sem distrações. Precisa de equipar várias salas? <a href="/pt/presupuesto">Peça orçamento</a>.</p>
  HTML_PT
  body_en: <<~HTML_EN
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
    <p>The specific rules depend on each autonomous community and can change from one school year to the next, so it's worth checking your region's and reflecting it in your school's regulations. If you're looking for a practical way to comply, <a href="/en/colegios">PhoneRelax for schools</a> helps you create distraction-free classrooms. Need to equip several classrooms? <a href="/en/presupuesto">Request a quote</a>.</p>
  HTML_EN
)
normativa.save!
puts "Artículo normativa: es/pt/en OK (posts: #{Post.count})"

# Tarifas de transporte por país (solo si aún no existen): base actual de la
# tienda — España 5,95 €, resto de la UE 13,95 € — editable desde el admin.
Order::EU_COUNTRIES.each do |country|
  ShippingRate.find_or_create_by!(country: country) do |rate|
    rate.base_cost = country == "España" ? BigDecimal("5.95") : BigDecimal("13.95")
  end
end
puts "Tarifas de envío: #{ShippingRate.count} países"
