# frozen_string_literal: true

# Traducciones al danés (columnas _da) del contenido de BD: productos y posts.
# Idempotente: se puede reejecutar. Se aplica en local y en producción con:
#   bin/rails runner script/backfill_da_translations.rb
#
# El post de legislación (normativa-movil-aulas-espana) incluye, SOLO en su
# versión danesa, una alusión a las recientes intenciones del gobierno danés de
# prohibir el móvil en los colegios y los patios.

# ---------------------------------------------------------------------------
# PRODUCTOS (por id): name_da y description_da
# ---------------------------------------------------------------------------
INTRO = "<p>PhoneRelax er en magnetisk pose til mobiltelefoner, der er udviklet til at forhindre, at elever eller brugere bliver distraheret af mobilen i skoler, gymnasier, til koncerter eller private arrangementer. Den er meget enkel at bruge: du lægger mobiltelefonen ind og lukker låsen, så den forsegles indeni. For at tage mobilen ud skal du holde PhoneRelax-posens magnetiske lås tæt på en af vores særlige åbningsmagneter og tage mobilen ud.</p>"
SIGNAL_ADVANTAGE = "<p><strong>Den største fordel ved denne version, der blokerer mobildækningen, er, at brugeren ikke bliver distraheret af notifikationer, ringetoner eller vibrationer, hvis vedkommende har glemt at sætte mobilen på lydløs eller slukke den, før den lægges i PhoneRelax-posen. Dermed slipper brugeren også for den uro og distraktion, som de forskellige apps' konstante notifikationer skaber.</strong></p>"

products = {
  1 => {
    name: "PhoneRelax SignalBlocking-pose (blokerer mobildækning)",
    description: INTRO + "\n" + SIGNAL_ADVANTAGE + "\n" \
      "<p><strong>Tekniske specifikationer:</strong></p>\n" \
      "<p><strong>Produktets mål:</strong> 12 cm bred x 26 cm høj x 4,5 cm dyb<br>" \
      "<strong>Materiale:</strong> 30% neopren, 40% polyester, 20% aluminium og 10% plast.<br>" \
      "<strong>Kompatible telefoner:</strong> Enhver smartphone med en skærmstørrelse på op til 6,8 tommer.<br>" \
      "<strong>Farve:</strong> Sort<br><strong>Vægt:</strong> 115 g</p>"
  },
  2 => {
    name: "PhoneRelax-magnet",
    description: "<p>Gør det muligt at åbne PhoneRelax-poserne ved blot at holde den afrundede del af posens lås tæt på midten af magneten.</p>\n" \
      "<p>Magneten har fire huller, så den kan fastgøres på enhver overflade og dermed ikke bliver væk eller flytter sig, mens PhoneRelax-poserne åbnes.</p>"
  },
  3 => {
    name: "PhoneRelax-pose",
    description: INTRO + "\n" \
      "<p><strong>Tekniske specifikationer:</strong></p>\n" \
      "<p><strong>Produktets mål:</strong> 12 cm bred x 24 cm høj x 4,5 cm dyb<br>" \
      "<strong>Materiale:</strong> 40% neopren, 50% polyester og 10% plast.<br>" \
      "<strong>Kompatible telefoner:</strong> Enhver smartphone med en skærmstørrelse på op til 6,8 tommer.<br>" \
      "<strong>Farve:</strong> Sort<br><strong>Vægt:</strong> 82 g</p>"
  },
  4 => {
    name: "PhoneRelax-lanyard",
    description: "<div>PhoneRelax-lanyard til at bære posen i. Fremstillet i <strong>polyester</strong> med en <strong>tykkelse på 6 mm</strong>.<br>" \
      "Designet gør det muligt at justere lanyardens længde, så den passer både til den, der vil bære den om halsen, og til den, der vil bære den over skulderen som en taske.</div>"
  },
  5 => {
    name: "DTF-tryk på pose",
    description: "<div>DTF-tryk på posen med dit logo eller varemærke. <strong>Minimumsantal: 25 stk.</strong> Læg lige så mange trykenheder i kurven, som der er PhoneRelax-poser i din ordre (SignalBlocking eller ikke-SignalBlocking).</div>"
  },
  6 => {
    name: "PhoneRelax prøvepose",
    description: nil
  },
  7 => {
    name: "Pakke med 25 SignalBlocking-poser + DTF-tryk + 2 magneter",
    description: "<div>Pakke til institutioner: 25 PhoneRelax SignalBlocking-poser med dit DTF-tryk og 2 magneter. Pris med mængderabat på hvert produkt.</div>"
  },
  8 => {
    name: "PhoneRelax SignalBlocking-pose med kortholder (blokerer mobildækning)",
    description: INTRO + "\n" \
      "<p><strong>Denne version har en kortholder med et gennemsigtigt vindue på 10 cm i bredden x 8 cm i højden.</strong></p>\n" +
      SIGNAL_ADVANTAGE + "\n" \
      "<p><strong>Tekniske specifikationer:</strong></p>\n" \
      "<p><strong>Produktets mål:</strong> 12,4 cm bred x 28,5 cm høj x 4,5 cm dyb<br>" \
      "<strong>Materiale:</strong> 30% neopren, 40% polyester, 20% aluminium og 10% plast.<br>" \
      "<strong>Kompatible telefoner:</strong> Enhver smartphone med en skærmstørrelse på op til 6,8 tommer.<br>" \
      "<strong>Farve:</strong> Sort<br><strong>Vægt:</strong> 115 g</p>"
  },
  9 => {
    name: "Pakke med 100 SignalBlocking-poser + DTF-tryk + 5 magneter",
    description: "<div>Pakke til institutioner: 100 PhoneRelax SignalBlocking-poser med dit DTF-tryk og 5 magneter. Pris med mængderabat på hvert produkt.</div>"
  }
}

products.each do |id, attrs|
  p = Product.find_by(id: id) or next
  p.name_da = attrs[:name]
  p.description_da = attrs[:description]
  p.save!(validate: false)
  puts "Producto ##{id}: name_da OK#{attrs[:description] ? ', description_da OK' : ''}"
end

# ---------------------------------------------------------------------------
# POSTS (por slug español): title_da, excerpt_da, body_da, slug_da
# ---------------------------------------------------------------------------
posts = {
  "cuales-son-las-principales-ventajas-de-prohibir-el-uso-de-telefonos-moviles-ninos-y-adolescentes-en-las-aulas" => {
    slug_da: "fordele-ved-at-styre-mobilbrug-i-klassevaerelset",
    title_da: "Fordele ved at styre mobilbrug i klasseværelset",
    excerpt_da: "At styre mobilbrug i skoler for børn og unge ved hjælp af PhoneRelax-poser har flere klare fordele, først og fremmest et bedre fagligt fokus. Uden distraktioner fra mobilen har eleverne tendens til at være mere opmærksomme.",
    body_da: <<~HTML
      <p>At styre mobilbrug i skoler for børn og unge ved hjælp af PhoneRelax-poser har flere klare fordele, først og fremmest et <strong>bedre fagligt fokus</strong>. Uden distraktioner fra mobilen har eleverne tendens til at være mere opmærksomme i timen, hvilket kan forbedre deres faglige resultater. Det er en kendsgerning, at færre distraktioner giver bedre koncentration, og uden den konstante fristelse til at tjekke mobilen kan eleverne fokusere mere på skolens opgaver og aktiviteter.</p>
      <p>En anden fordel er <strong>bedre socialt samvær</strong>: ved at begrænse mobilbrug fremmes den direkte kontakt ansigt til ansigt mellem eleverne, hvilket styrker deres sociale færdigheder og deres evne til at arbejde sammen.</p>
      <p>Det er også påvist, at det <strong>reducerer cybermobning</strong>, da en begrænsning af brugen af elektroniske enheder kan mindske tilfælde af cybermobning og adgang til upassende indhold og dermed være med til at skabe et tryggere skolemiljø.</p>
      <p>I frikvarteret giver det <strong>mere fysisk aktivitet</strong>, for uden konstant brug af enheder får eleverne mere tid til fysiske aktiviteter, hvilket er gavnligt for deres sundhed og trivsel.</p>
      <p>En fordel ved at begrænse mobilbrug i skoler og gymnasier er <strong>udviklingen af problemløsningsevner</strong>, for når eleverne ikke er så afhængige af teknologien, kan de udvikle evnen til at løse problemer mere kreativt og med flere forskellige ressourcer.</p>
      <p>Trods disse fordele er det også vigtigt at overveje, hvordan et forbud mod mobile enheder gennemføres, da de i nogle tilfælde kan være nyttige redskaber til læring, som under lærernes opsyn kan understøtte undervisningen i bestemte emner eller opgaver.</p>
    HTML
  },
  "ventajas-de-evitar-el-uso-de-moviles-en-conciertos" => {
    slug_da: "fordele-ved-at-undgaa-mobilbrug-til-koncerter",
    title_da: "Koncerter uden mobiler eller \"Phone-Free Events\"",
    excerpt_da: "At bruge PhoneRelax-poser til at undgå mobilbrug til koncerter har flere væsentlige fordele, for eksempel en mere fordybende oplevelse, hvor deltagerne fuldt ud kan nyde musikken, stemningen og forbindelsen til kunstneren og de øvrige deltagere.",
    body_da: <<~HTML
      <p>At bruge PhoneRelax-poser til at undgå mobilbrug til koncerter har flere væsentlige fordele, for eksempel en <strong>mere fordybende oplevelse</strong>, hvor deltagerne fuldt ud kan nyde musikken, stemningen og forbindelsen til kunstneren og de øvrige deltagere.</p>
      <p>Denne slags arrangementer kendes allerede som "phone free events" eller "mobilfri oplevelser".</p>
      <p>En af de vigtigste fordele er <strong>respekten for kunstneren</strong>, for brugen af mobilen kan distrahere både publikum og kunstneren. At undgå mobilbrug viser respekt for musikerens arbejde og lader alle nyde showet fuldt ud uden afbrydelser.</p>
      <p>Sagen med sangerinden Adele, der bad en tilskuer til sin koncert om at stoppe med at optage og i stedet nyde showet live, er velkendt.</p>
      <p>Når deltagerne ikke er opslugt af skærmene, <strong>forbedres den mellemmenneskelige forbindelse</strong>: det er mere sandsynligt, at man taler med personerne omkring sig, hvilket fremmer ægte menneskelige forbindelser og måske betydningsfulde øjeblikke sammen med andre fans.</p>
      <p>Et andet vigtigt punkt er <strong>bedre lyd- og udsynskvalitet til kunstneren</strong>, for når man løfter mobilen for at optage eller tage billeder, spærrer man ofte for andres udsyn og kan forringe lydkvaliteten, men frem for alt det direkte udsyn til kunstneren eller arrangementet.</p>
      <p>Og sidst, men ikke mindst, <strong>skaber det mere ægte minder</strong>, for i stedet for at fange hele koncerten på mobilens skærm er det bedre at nyde øjeblikket og gemme minderne i sit hoved og dermed skabe mere levende og ægte minder, der varer ved.</p>
      <p>Selvom det er forståeligt at ville fange nogle øjeblikke af koncerten, kan en begrænsning af mobilbrugen berige oplevelsen betydeligt både for én selv og for de øvrige deltagere.</p>
      <p><img alt="" src="/images/blog/phonerelax-para-eventos-cuerpo.jpg" style="display: block; margin-left: auto; margin-right: auto;"></p>
    HTML
  },
  "y-que-podemos-hacer-para-evitar-que-los-alumnos-usen-los-telefonos-en-las-aulas" => {
    slug_da: "saadan-undgaar-du-mobilbrug-paa-ungdomsuddannelser",
    title_da: "Sådan undgår du mobilbrug på ungdomsuddannelser",
    excerpt_da: "PhoneRelax-poserne med magnetlås, designet så eleverne selv gemmer deres mobil og ikke har adgang til den i udpegede områder, kan være et effektivt redskab til at styre brugen af elektroniske enheder i skolemiljøet. Poserne har meget klare fordele.",
    body_da: <<~HTML
      <p>PhoneRelax-poserne med magnetlås, designet så eleverne selv gemmer deres mobil og ikke har adgang til den i udpegede områder, kan være et effektivt redskab til at styre brugen af elektroniske enheder i skolemiljøet. Poserne har meget klare fordele:</p>
      <p><strong>Sikkerhed og kontrol:</strong> Ved at bruge magnetlåse, der forhindrer adgang til mobilen, mens den er gemt væk, sikres et højere niveau af sikkerhed og kontrol med enheden i skoletiden.</p>
      <p><strong>Forebyggelse af distraktioner:</strong> Når man ikke let kan få adgang til mobilerne, mindskes fristelsen og muligheden for distraktioner i klasseværelset, hvilket kan forbedre elevernes fokus på læringen. Vi har endda en version af PhoneRelax-posen, der efterlader mobilen uden dækning og dermed forhindrer, at eleven modtager opkald eller indgående notifikationer fra apps, selv hvis vedkommende har glemt at sætte mobilen på lydløs.</p>
      <p><strong>Ensartethed og nem administration:</strong> Hvis alle elever bruger PhoneRelax-poserne, bliver det lettere for lærere og skolens personale at administrere, da systemet er ensartet og klart for alle.</p>
      <p><strong>Eleverne har selv deres mobil i forvaring i PhoneRelax-poserne:</strong> Når eleverne får ansvaret for selv at gemme deres egne mobiler i PhoneRelax-poserne, undgås enhver problematik omkring mulige skader på enhederne, og lærere og skolens personale fritages dermed for dette ansvar.</p>
      <p>Det er dog vigtigt at overveje nogle aspekter:</p>
      <p><strong>Særlige behov:</strong> Nogle elever kan have særlige behov for at få adgang til deres mobil på grund af medicinske eller familiemæssige nødsituationer. Der bør altid være en vis fleksibilitet til at håndtere disse situationer.</p>
    HTML
  },
  "normativa-movil-aulas-espana" => {
    slug_da: "regler-for-mobilbrug-i-klassevaerelset",
    title_da: "Regler for mobilbrug i klasseværelset: Spanien og Danmark",
    excerpt_da: "Mobilbrug i klasseværelset bliver stadig mere begrænset i Spanien, men reglerne afhænger af den enkelte region. Vi ser også på den danske regerings planer om at forbyde mobiler i folkeskolen og i frikvartererne.",
    body_da: <<~HTML
      <p>Brugen af mobilen i timerne er blevet et af de store emner i skoleverdenen. I de senere år er de fleste skolemyndigheder gået fra anbefaling til <strong>begrænsning</strong>, og mange skoler leder efter den bedste måde at føre det ud i livet på i hverdagen.</p>
      <h2>Hvem regulerer mobilbrug i skolerne i Spanien?</h2>
      <p>I Spanien er uddannelse et <strong>ansvar, der er overdraget til de selvstyrende regioner</strong>. Det betyder, at der ikke findes én enkelt statslig lov, der forbyder mobilen i alle skoler på samme måde: hver region fastsætter sine egne regler, og inden for den ramme fastlægger hver skole reglerne i sit ordensreglement.</p>
      <p>Det spanske skoleråd (Consejo Escolar del Estado) har udtalt sig til fordel for at begrænse brugen af enheder i klasseværelserne, og den enighed har efterhånden bredt sig til de fleste regioner.</p>
      <h2>Tendensen: fra anbefaling til forbud</h2>
      <p>Retningen er klar: flere og flere regioner begrænser eller forbyder mobilen i skolerne. Galicien var blandt de første til at begrænse den i klasseværelserne, og i de seneste skoleår er størstedelen af landet kommet til, med regler der spænder fra totalt forbud til udelukkende pædagogisk og overvåget brug.</p>
      <h2>Og hvad med Danmark?</h2>
      <p>Danmark bevæger sig i samme retning. Den <strong>danske regering har bebudet planer om at forbyde mobiltelefoner i folkeskoler og fritidsordninger</strong> — også <strong>i frikvartererne og på skolens udearealer</strong> — efter anbefalinger om at gøre skoledagen mere skærmfri og styrke børnenes trivsel og samvær. Det understreger en international tendens: mobilfri skoler er ikke længere undtagelsen, men er hurtigt ved at blive normen. De konkrete regler kan ændre sig, så det anbefales at følge de gældende retningslinjer fra ministeriet og den enkelte kommune.</p>
      <h2>Folkeskole og ungdomsuddannelse: forskellige regler</h2>
      <p>Selvom hver spansk region har sine nuancer, er det mest almindelige mønster:</p>
      <ul>
        <li><strong>Børnehaveklasse og de yngste klasser:</strong> generelt forbud mod mobilbrug i hele skoletiden, inklusive frikvartererne.</li>
        <li><strong>De ældste klasser og ungdomsuddannelser:</strong> forbud som hovedregel, med mulige <strong>undtagelser til pædagogisk brug</strong>, når læreren beslutter det og altid under opsyn.</li>
      </ul>
      <h2>Udfordringen er ikke reglen, men at håndhæve den</h2>
      <p>At vedtage reglen er den lette del; udfordringen er at overholde den uden at gøre lærerne til vagter. De mest almindelige løsninger — at slukke mobilen, lægge den i tasken eller aflevere den i en kasse i klassen — rejser tvivl: hvem er ansvarlig, hvis en mobil bliver beskadiget eller forsvinder? Hvordan undgår man, at eleven tjekker den i smug?</p>
      <h2>Sådan løser PhoneRelax det</h2>
      <p>Med de magnetiske <strong>PhoneRelax</strong>-poser gemmer hver elev sin egen mobil i en pose, der forsegles og kun åbnes ved at holde den tæt på skolens magnet. På den måde:</p>
      <ul>
        <li>Er det <strong>eleven selv, der har sin mobil i forvaring</strong>: skolen er ikke ansvarlig for eventuelle skader.</li>
        <li>Efterlader <strong>SignalBlocking</strong>-versionen mobilen uden dækning eller wifi og forhindrer notifikationer eller brug i smug, hvilket er særlig nyttigt ved prøver.</li>
        <li>Er det et <strong>ensartet og enkelt</strong> system for hele skolen, nemt at bruge hver dag.</li>
      </ul>
      <h2>Før du beslutter dig</h2>
      <p>De konkrete regler afhænger af den enkelte region eller kommune og kan ændre sig fra år til år, så det er en god idé at tjekke reglerne for dit område og afspejle dem i skolens reglement. Leder du efter en praktisk måde at overholde dem på, hjælper <a href="/da/skoler">PhoneRelax til skoler</a> dig med at skabe distraktionsfrie klasseværelser. Skal du udstyre flere klasseværelser? <a href="/da/tilbud">Bed om et tilbud</a>.</p>
    HTML
  }
}

posts.each do |es_slug, attrs|
  post = Post.find_by(slug: es_slug) or next
  post.update!(attrs)
  puts "Post '#{es_slug}' -> /da/blogs/news/#{post.slug_da}"
end

puts "Hecho."
