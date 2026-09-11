# frozen_string_literal: true

# Traducciones al italiano (columnas _it) del contenido de BD: productos y posts.
# Idempotente. Aplicar en local y en producción con:
#   bin/rails runner script/backfill_it_translations.rb
#
# El post de legislación (normativa-movil-aulas-espana) tiene, en su versión
# ITALIANA, una versión propia centrada en Italia: las circolari Valditara
# (2024 infanzia/primaria/secondaria di primo grado; giugno 2025 esteso alle
# scuole superiori).

# ---------------------------------------------------------------------------
# PRODUCTOS (por id): name_it y description_it
# ---------------------------------------------------------------------------
INTRO = "<p>PhoneRelax è una custodia magnetica per telefoni cellulari pensata per evitare che studenti o utenti si distraggano con il telefono a scuola, alle superiori, ai concerti o agli eventi privati. Il funzionamento è molto semplice: devi inserire il telefono all'interno e chiudere la serratura così resta sigillato dentro. Per estrarre il telefono è necessario avvicinare la serratura magnetica della custodia PhoneRelax a uno dei nostri speciali magneti di apertura ed estrarre il telefono.</p>"
SIGNAL_ADVANTAGE = "<p><strong>Il principale vantaggio di questa versione che blocca la copertura mobile è che l'utente non sarà distratto da notifiche, suonerie o vibrazioni se ha dimenticato di silenziare o spegnere il telefono prima di inserirlo nella busta PhoneRelax; così l'utente non avrà nemmeno l'ansia e la distrazione generate dalle continue notifiche delle diverse applicazioni.</strong></p>"

products = {
  1 => {
    name: "Custodia PhoneRelax SignalBlocking (blocca la copertura mobile)",
    description: INTRO + "\n" + SIGNAL_ADVANTAGE + "\n" \
      "<p><strong>Specifiche tecniche:</strong></p>\n" \
      "<p><strong>Dimensioni del prodotto:</strong> 12 cm largh. x 26 cm alt. x 4,5 cm prof.<br>" \
      "<strong>Materiale:</strong> 30% neoprene, 40% poliestere, 20% alluminio e 10% plastica.<br>" \
      "<strong>Telefoni compatibili:</strong> Qualsiasi smartphone con uno schermo fino a 6,8 pollici.<br>" \
      "<strong>Colore:</strong> Nero<br><strong>Peso:</strong> 115 g</p>"
  },
  2 => {
    name: "Magnete PhoneRelax",
    description: "<p>Consente di aprire le buste PhoneRelax semplicemente avvicinando la parte arrotondata della serratura della busta al centro del magnete.</p>\n" \
      "<p>Il magnete dispone di quattro fori pensati per fissarlo a qualsiasi superficie ed evitare così che si perda o si sposti durante l'apertura delle buste PhoneRelax.</p>"
  },
  3 => {
    name: "Custodia PhoneRelax",
    description: INTRO + "\n" \
      "<p><strong>Specifiche tecniche:</strong></p>\n" \
      "<p><strong>Dimensioni del prodotto:</strong> 12 cm largh. x 24 cm alt. x 4,5 cm prof.<br>" \
      "<strong>Materiale:</strong> 40% neoprene, 50% poliestere e 10% plastica.<br>" \
      "<strong>Telefoni compatibili:</strong> Qualsiasi smartphone con uno schermo fino a 6,8 pollici.<br>" \
      "<strong>Colore:</strong> Nero<br><strong>Peso:</strong> 82 g</p>"
  },
  4 => {
    name: "Lanyard PhoneRelax",
    description: "<div>Lanyard PhoneRelax per appendere la busta. Realizzato in <strong>poliestere</strong> con uno <strong>spessore di 6 mm</strong>.<br>" \
      "Questo design permette di regolare la lunghezza del lanyard per adattarlo sia a chi vuole portarlo al collo sia a chi vuole portarlo a tracolla come una borsa.</div>"
  },
  5 => {
    name: "Personalizzazione DTF custodia",
    description: "<div>Personalizzazione DTF della custodia con il tuo logo o marchio. <strong>Quantità minima: 25 unità.</strong> Aggiungi al carrello tante unità di personalizzazione quante sono le buste PhoneRelax del tuo ordine (SignalBlocking o non SignalBlocking).</div>"
  },
  6 => {
    name: "Busta campione PhoneRelax",
    description: nil
  },
  7 => {
    name: "Pacchetto 25 buste SignalBlocking + personalizzazione DTF + 2 magneti",
    description: "<div>Pacchetto per istituti: 25 buste PhoneRelax SignalBlocking con la tua personalizzazione DTF e 2 magneti. Prezzo con gli sconti sulle quantità di ogni prodotto.</div>"
  },
  8 => {
    name: "Custodia PhoneRelax SignalBlocking con portacarte (blocca la copertura mobile)",
    description: INTRO + "\n" \
      "<p><strong>Questa versione include un portacarte con finestra trasparente di 10 cm di larghezza x 8 cm di altezza.</strong></p>\n" +
      SIGNAL_ADVANTAGE + "\n" \
      "<p><strong>Specifiche tecniche:</strong></p>\n" \
      "<p><strong>Dimensioni del prodotto:</strong> 12,4 cm largh. x 28,5 cm alt. x 4,5 cm prof.<br>" \
      "<strong>Materiale:</strong> 30% neoprene, 40% poliestere, 20% alluminio e 10% plastica.<br>" \
      "<strong>Telefoni compatibili:</strong> Qualsiasi smartphone con uno schermo fino a 6,8 pollici.<br>" \
      "<strong>Colore:</strong> Nero<br><strong>Peso:</strong> 115 g</p>"
  },
  9 => {
    name: "Pacchetto 100 buste SignalBlocking + personalizzazione DTF + 5 magneti",
    description: "<div>Pacchetto per istituti: 100 buste PhoneRelax SignalBlocking con la tua personalizzazione DTF e 5 magneti. Prezzo con gli sconti sulle quantità di ogni prodotto.</div>"
  }
}

products.each do |id, attrs|
  p = Product.find_by(id: id) or next
  p.name_it = attrs[:name]
  p.description_it = attrs[:description]
  p.save!(validate: false)
  puts "Producto ##{id}: name_it OK#{attrs[:description] ? ', description_it OK' : ''}"
end

# ---------------------------------------------------------------------------
# POSTS (por slug español): title_it, excerpt_it, body_it, slug_it
# ---------------------------------------------------------------------------
posts = {
  "cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas" => {
    slug_it: "vantaggi-gestire-uso-cellulare-in-aula",
    title_it: "Vantaggi di gestire l'uso del cellulare in aula",
    excerpt_it: "Gestire l'uso del cellulare nelle scuole per bambini e adolescenti tramite le buste PhoneRelax ha diversi vantaggi evidenti, tra cui principalmente un maggiore focus sullo studio. Senza le distrazioni del telefono, gli studenti tendono a prestare più attenzione.",
    body_it: <<~HTML
      <p>Gestire l'uso del cellulare nelle scuole per bambini e adolescenti tramite le buste PhoneRelax ha diversi vantaggi evidenti, tra cui principalmente un <strong>maggiore focus sullo studio</strong>. Senza le distrazioni del telefono, gli studenti tendono a prestare più attenzione in classe, il che può migliorare il loro rendimento scolastico. È un dato di fatto che meno distrazioni significano maggiore concentrazione, e senza la tentazione costante di controllare il telefono gli studenti possono concentrarsi di più sui compiti e sulle attività scolastiche, migliorando la loro capacità di attenzione.</p>
      <p>Un altro vantaggio è il <strong>miglioramento dell'interazione sociale</strong>: limitando l'uso del telefono si favorisce l'interazione faccia a faccia tra gli studenti, rafforzando le loro abilità sociali e la capacità di lavorare in gruppo.</p>
      <p>È stato dimostrato anche che <strong>riduce il cyberbullismo</strong>, poiché limitare l'uso dei dispositivi elettronici può diminuire i casi di cyberbullismo e l'accesso a contenuti inappropriati, contribuendo a creare un ambiente scolastico più sicuro.</p>
      <p>In cortile produce <strong>più tempo di attività fisica</strong>, perché senza l'uso costante dei dispositivi gli studenti possono avere più tempo per le attività fisiche, il che è positivo per la loro salute e il loro benessere.</p>
      <p>Un vantaggio della limitazione dell'uso del cellulare nelle scuole è lo <strong>sviluppo delle capacità di problem solving</strong>: non dipendendo così tanto dalla tecnologia, gli studenti possono sviluppare la capacità di risolvere i problemi in modo più creativo e con risorse più varie.</p>
      <p>Nonostante questi vantaggi, è importante considerare anche come viene applicato il divieto dei dispositivi mobili, poiché in alcuni casi possono essere strumenti utili per l'apprendimento che, sotto la supervisione degli insegnanti, possono favorire lo studio in determinate materie o attività.</p>
    HTML
  },
  "ventajas-de-evitar-el-uso-de-moviles-en-conciertos" => {
    slug_it: "vantaggi-evitare-cellulare-ai-concerti",
    title_it: "Concerti senza telefono o \"Phone-Free Events\"",
    excerpt_it: "Usare le buste PhoneRelax per evitare l'uso del telefono ai concerti ha diversi vantaggi significativi, per esempio un'esperienza più immersiva, perché i partecipanti possono godersi appieno la musica, l'atmosfera e la connessione con l'artista e gli altri spettatori.",
    body_it: <<~HTML
      <p>Usare le buste PhoneRelax per evitare l'uso del telefono ai concerti ha diversi vantaggi significativi, per esempio un'<strong>esperienza più immersiva</strong>, perché i partecipanti al concerto possono godersi appieno la musica, l'atmosfera e la connessione con l'artista e gli altri spettatori.</p>
      <p>Questo tipo di eventi è già noto come "phone free events" o "esperienze senza telefono".</p>
      <p>Uno dei principali vantaggi è il <strong>rispetto verso l'artista</strong>, perché usare il telefono può distrarre sia il pubblico sia l'artista. Evitare l'uso del telefono mostra rispetto per il lavoro del musicista e permette a tutti di godersi appieno lo spettacolo senza interruzioni.</p>
      <p>È noto il caso della cantante Adele che ha chiesto a uno spettatore del suo concerto di smettere di registrare e di godersi lo show dal vivo.</p>
      <p>Inoltre, non essendo assorbiti dagli schermi, i partecipanti <strong>migliorano la connessione interpersonale</strong>: è più probabile che interagiscano con le persone intorno a loro, favorendo connessioni umane autentiche e magari condividendo momenti significativi con altri fan.</p>
      <p>Un altro punto fondamentale è il <strong>miglioramento della qualità del suono e della visuale sull'artista</strong>, perché alzando il telefono per registrare o fare foto spesso si blocca la visuale delle altre persone e si può ridurre la qualità del suono, ma soprattutto la visuale diretta dell'artista o dell'evento.</p>
      <p>E infine, ma non meno importante, <strong>crea ricordi più autentici</strong>: invece di catturare tutto il concerto sullo schermo del telefono, è meglio godersi il momento e conservare i ricordi nella propria mente per creare ricordi più vividi e autentici, destinati a durare.</p>
      <p>Anche se è comprensibile voler catturare alcuni momenti del concerto, limitare l'uso del telefono può arricchire notevolmente l'esperienza sia per sé stessi sia per gli altri partecipanti.</p>
      <p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
    HTML
  },
  "y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas" => {
    slug_it: "come-evitare-uso-cellulare-scuole-superiori",
    title_it: "Come evitare l'uso del cellulare nelle scuole superiori",
    excerpt_it: "Le buste con chiusura magnetica PhoneRelax, pensate perché siano gli studenti stessi a riporre i propri telefoni e a non avervi accesso nelle zone designate, possono essere uno strumento efficace per gestire l'uso dei dispositivi elettronici a scuola. Ecco i loro vantaggi.",
    body_it: <<~HTML
      <p>Le buste con chiusura magnetica PhoneRelax, pensate perché siano gli studenti stessi a riporre i propri telefoni e a non avervi accesso nelle zone designate, possono essere uno strumento efficace per gestire l'uso dei dispositivi elettronici negli ambienti scolastici. Queste buste offrono vantaggi molto chiari:</p>
      <p><strong>Sicurezza e controllo:</strong> Utilizzando chiusure magnetiche che impediscono l'accesso al telefono mentre è riposto, si garantisce un maggiore livello di sicurezza e controllo sul dispositivo durante l'orario scolastico.</p>
      <p><strong>Prevenzione delle distrazioni:</strong> Non potendo accedere facilmente ai telefoni, si riduce la tentazione e la possibilità di distrazioni in aula, migliorando la concentrazione degli studenti. Disponiamo persino di una versione della busta PhoneRelax che lascia il telefono senza copertura mobile, evitando che, anche se lo studente dimentica di silenziare il telefono, possa ricevere chiamate o notifiche in arrivo dalle applicazioni.</p>
      <p><strong>Uniformità e facilità di gestione:</strong> Se tutti gli studenti usano le buste PhoneRelax si semplifica la gestione per insegnanti e personale scolastico, mantenendo un sistema uniforme e chiaro per tutti.</p>
      <p><strong>Custodia dei telefoni da parte degli studenti nelle loro buste PhoneRelax:</strong> Affidando agli studenti la responsabilità di riporre i propri telefoni nelle buste PhoneRelax si evita qualsiasi problema legato a possibili danni ai dispositivi, sollevando così da tale responsabilità insegnanti e personale scolastico.</p>
      <p>Tuttavia, è importante considerare alcuni aspetti:</p>
      <p><strong>Esigenze specifiche:</strong> Alcuni studenti possono avere esigenze particolari di accesso al telefono per emergenze mediche o familiari. Dovrebbe sempre esserci una certa flessibilità per gestire queste situazioni.</p>
    HTML
  },
  "normativa-movil-aulas-espana" => {
    slug_it: "regole-cellulare-in-aula-italia",
    title_it: "Regole sull'uso del cellulare in aula in Italia",
    excerpt_it: "L'uso del cellulare in aula è sempre più regolamentato. In Italia il Ministero dell'Istruzione e del Merito ha vietato lo smartphone in tutte le scuole con le circolari Valditara. Ecco cosa prevede la normativa e come applicarla ogni giorno.",
    body_it: <<~HTML
      <p>L'uso del cellulare in classe è diventato uno dei grandi temi del mondo della scuola. Negli ultimi anni si è passati dalla raccomandazione al <strong>divieto</strong>, e molte scuole cercano il modo migliore per applicarlo nella pratica quotidiana.</p>
      <h2>Chi regola l'uso del cellulare nelle scuole in Italia?</h2>
      <p>A differenza di altri Paesi in cui la competenza è regionale, in Italia le regole arrivano dal <strong>Ministero dell'Istruzione e del Merito</strong> con circolari valide su tutto il territorio nazionale, che ogni istituto recepisce e specifica nel proprio regolamento.</p>
      <h2>Dalla raccomandazione al divieto</h2>
      <p>Già nel <strong>2007</strong> la direttiva Fioroni vietava l'uso del cellulare durante le lezioni. Negli ultimi anni la linea si è fatta molto più netta con le circolari del ministro Valditara.</p>
      <h2>Cosa prevede la normativa attuale</h2>
      <ul>
        <li><strong>Scuola dell'infanzia, primaria e secondaria di primo grado:</strong> dall'anno scolastico 2024/2025, divieto di smartphone <strong>anche per uso didattico</strong> (circolare del luglio 2024).</li>
        <li><strong>Scuola secondaria di secondo grado:</strong> con la circolare del <strong>16 giugno 2025</strong>, il divieto è stato <strong>esteso alle scuole superiori</strong> dall'anno scolastico 2025/2026. Il divieto è generale e riguarda <strong>l'intera permanenza a scuola</strong>, non solo le ore di lezione.</li>
      </ul>
      <p>Le uniche eccezioni riguardano gli usi inclusivi legati a disabilità o DSA previsti nel PEI o nel PDP. Le modalità di custodia dei dispositivi e le sanzioni sono lasciate all'<strong>autonomia dei singoli istituti</strong>.</p>
      <h2>La sfida non è la norma, è applicarla</h2>
      <p>Approvare la regola è la parte facile; la sfida è farla rispettare senza trasformare i docenti in sorveglianti. Le soluzioni più comuni — spegnere il telefono, lasciarlo nello zaino o depositarlo in una scatola in aula — sollevano dubbi: chi è responsabile se un telefono si danneggia o sparisce? Come si evita che lo studente lo usi di nascosto?</p>
      <h2>Come lo risolve PhoneRelax</h2>
      <p>Con le buste magnetiche <strong>PhoneRelax</strong>, ogni studente ripone il proprio telefono in una busta che si sigilla e si apre solo avvicinandola al magnete della scuola. Così:</p>
      <ul>
        <li>È <strong>lo studente stesso a custodire il telefono</strong>: la scuola non è responsabile di eventuali danni.</li>
        <li>La versione <strong>SignalBlocking</strong> lascia il telefono senza copertura né wifi, evitando notifiche o l'uso di nascosto, particolarmente utile durante le verifiche.</li>
        <li>È un sistema <strong>uniforme e semplice</strong> per tutto l'istituto, facile da applicare ogni giorno.</li>
      </ul>
      <h2>Prima di decidere</h2>
      <p>Le disposizioni possono aggiornarsi di anno in anno, quindi conviene consultare le indicazioni del Ministero e del proprio istituto e recepirle nel regolamento scolastico. Se cerchi un modo pratico per rispettarle, <a href="/it/scuole">PhoneRelax per le scuole</a> ti aiuta a creare aule senza distrazioni. Devi attrezzare più aule? <a href="/it/preventivo">Richiedi un preventivo</a>.</p>
    HTML
  }
}

posts.each do |es_slug, attrs|
  post = Post.find_by(slug: es_slug) or next
  post.update!(attrs)
  puts "Post '#{es_slug}' -> /it/blogs/news/#{post.slug_it}"
end

puts "Hecho."
