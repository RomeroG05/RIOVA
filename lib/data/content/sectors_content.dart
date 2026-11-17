import 'package:latlong2/latlong.dart';

import '../../core/illustrations/scene_painter.dart';
import '../models/place.dart';

// Contenido de los 13 sectores, basado en el periódico
// «Todo lo que necesita conocer sobre los afluentes que recorren nuestra
// ciudad» — Taller de Proyectos Urbano Arquitectónicos II, Loja, enero 2026.
// Los textos se adaptaron a un lenguaje para niños; las fotos están en
// assets/places/<id>/.
//
// Posiciones: punto del cauce real (OpenStreetMap) más cercano al lugar de
// referencia que cita el periódico. Reemplazar por la coordenada medida si se
// instalan tótems físicos.

const periodicalCredit =
    'Fotos e información: periódico «Todo lo que necesita conocer sobre los afluentes que recorren nuestra ciudad», '
    'Taller de Proyectos Urbano Arquitectónicos II, Loja, enero 2026.';

RiverProblem _problem(ProblemKind k, String summary, String detail) =>
    RiverProblem(
      kind: k,
      title: k.title,
      summary: summary,
      detail: detail,
      help: k.help,
      icon: k.icon,
      color: k.color,
    );

List<PlacePhoto> _photos(String id, List<(String, bool)> items) => [
  for (final (i, (caption, drawing)) in items.indexed)
    PlacePhoto('assets/places/$id/${i + 1}.webp', caption, drawing: drawing),
];

const _sauce = Species(
  name: 'Sauce',
  emoji: '🌳',
  tag: 'Nativo',
  text: 'Sus raíces sujetan la orilla.',
);
const _aliso = Species(
  name: 'Aliso',
  emoji: '🌲',
  tag: 'Nativo',
  text: 'Da frescura y protege los taludes.',
);
const _faique = Species(
  name: 'Faique',
  emoji: '🌵',
  tag: 'Nativo',
  text: 'Árbol espinoso del bosque seco.',
);
const _eucalipto = Species(
  name: 'Eucalipto',
  emoji: '🌿',
  tag: 'Introducido',
  text: 'Crece rápido, pero bebe mucha agua.',
);
const _colibri = Species(
  name: 'Colibrí',
  emoji: '🐦',
  tag: 'Ave',
  text: 'Visita las flores de la ribera.',
  isFauna: true,
);
const _mirlo = Species(
  name: 'Mirlo',
  emoji: '🐦‍⬛',
  tag: 'Ave',
  text: 'Canta en los árboles junto al río.',
  isFauna: true,
);

// ───────────── Sectores ─────────────

/// Contenido empaquetado con la app (base inmutable).
final List<Place> bundledPlaces = List.unmodifiable(<Place>[
  // ═════════════ ZONA SUR: donde el río ingresa a la ciudad ═════════════
  Place(
    id: 'capuli2',
    code: 'A1',
    name: 'Sector Capulí II',
    shortName: 'Capulí II',
    zone: Zone.sur,
    river: River.malacatos,
    position: const LatLng(-4.04895, -79.19751),
    totem: 1,
    headline: 'El Capulí: de zona rural olvidada a barrio en crecimiento',
    tagline: '“Río Malacatos, nuestra fuente de vida”.',
    description: 'Barrio entre la ciudad y el campo, junto al río Malacatos y la quebrada Namanda, en la vía a Vilcabamba.',
    story: [
      'Hasta los años 90, El Capulí era una zona verde de huertos y campo. Hoy es un barrio que crece a lo largo de la vía a Vilcabamba, junto al río Malacatos.',
      'Antes, el río regaba los huertos y las familias lo usaban para bañarse y lavar. Sus vecinos todavía cuidan huertos, corrales y áreas verdes.',
      'Las montañas que lo rodean tienen pendientes muy fuertes, así que algunas casas están en zonas con riesgo de deslizamientos.',
    ],
    fact: 'En 2008, El Capulí fue declarado área de reserva urbana para conservar los espacios naturales cercanos a la ciudad.',
    factTags: ['Vida de campo', 'Huertos', 'Quebrada Namanda'],
    scene: SceneSpec.nature,
    photos: _photos('capuli2', [
      (
        'Vista aérea: el Malacatos (en azul) entra al sur de Loja entre huertos y casas',
        false,
      ),
      ('Antes, las familias lavaban la ropa en el río', false),
      ('El cauce del Malacatos en El Capulí', false),
      ('Sendero y árboles junto a la orilla', false),
      ('Ilustración: agricultura y ganadería junto al río', true),
    ]),
    voices: const [
      Voice(
        'Sra. María',
        'La basura y desechos siempre llegan a donde tengo mis cultivos y se llena de mal olor.',
      ),
      Voice(
        'Sr. Joaquín',
        'Antes mi mujer bañaba a mis hijos en el río, ahora ya no se puede por la suciedad.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.contaminacion,
        'Desagües y basura llegan al río.',
        'Algunos desagües vierten agua sucia directamente al río y se forman islas de sedimentos. La basura llega hasta los cultivos de la orilla.',
      ),
      _problem(
        ProblemKind.erosion,
        'Laderas muy empinadas que se deslizan.',
        'El terreno tiene pendientes de hasta 81 %. En época de lluvias hay deslaves cerca de las casas más bajas.',
      ),
      _problem(
        ProblemKind.olores,
        'Agua contaminada y mal olor.',
        'En algunos tramos el agua huele mal y ya no se puede usar para bañarse, como se hacía antes.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Antes de 1990',
        'El Capulí era una zona verde de campo, sin casas planificadas. El río regaba los huertos.',
      ),
      TimelineStep(
        '1997 – 2009',
        'La ciudad amplió su límite urbano e incluyó al barrio. En 2008 fue declarado reserva urbana.',
      ),
      TimelineStep(
        'Hoy',
        'Un barrio que mezcla ciudad y campo, con servicios básicos pero un río que necesita cuidado.',
      ),
    ],
    species: const [
      Species(
        name: 'Capulí',
        emoji: '🍒',
        tag: 'Árbol frutal',
        text: 'Da frutitos dulces y le da nombre al barrio.',
      ),
      _faique,
      Species(
        name: 'Tórtola orejuda',
        emoji: '🕊️',
        tag: 'Ave',
        text: 'Camina buscando semillas en el suelo.',
        isFauna: true,
      ),
      _colibri,
    ],
    quiz: const QuizQuestion(
      question:
          '¿Para qué usaban el río Malacatos las familias de El Capulí antes?',
      options: [
        'Para regar sus huertos y para bañarse y lavar.',
        'Para pasear en barcos grandes.',
        'Para nada, nadie se acercaba al río.',
      ],
      answer: 0,
      explanation: 'El río era una fuente de vida: regaba los cultivos y servía para las tareas de la casa.',
    ),
  ),
  Place(
    id: 'capuli1',
    code: 'A2',
    name: 'Sector Capulí I',
    shortName: 'Capulí I',
    zone: Zone.sur,
    river: River.malacatos,
    position: const LatLng(-4.03827, -79.20063),
    totem: 2,
    headline: 'La indiferencia: recuperar el vínculo con el río Malacatos',
    tagline: 'Un sendero junto al río que espera volver a la vida.',
    description: 'Tramo del Malacatos junto a la Universidad Nacional de Loja y su Jardín Botánico, con un sendero dañado por las crecidas.',
    story: [
      'Junto a la Universidad Nacional de Loja, el río Malacatos tiene un sendero y zonas para descansar que hoy casi nadie usa.',
      'Tras un desborde, parte de la orilla quedó convertida en escombrera, y el sendero perdió tramos por la fuerza del agua.',
      'Aun así, los vecinos dicen que es un barrio seguro y unido, y sueñan con recuperar sus espacios junto al río.',
    ],
    fact: 'El Capulí está en una zona de gran biodiversidad: aquí se mezclan los bosques andinos y el bosque seco del sur del Ecuador.',
    factTags: ['Universidad Nacional', 'Jardín Botánico', 'Sendero'],
    scene: SceneSpec.river,
    photos: _photos('capuli1', [
      (
        'Poza estancada junto al cauce, con agua anaranjada por vertidos de una construcción',
        false,
      ),
      ('Bancas y espacios de descanso sin uso', false),
      ('El sendero junto al río, dañado por la corriente', false),
    ]),
    voices: const [
      Voice(
        'Vecino del sector',
        'Es un barrio seguro, no hay robos y hay cohesión entre la comunidad.',
      ),
      Voice(
        'Vecina del sector',
        'Cuando llueve demasiado, las quebradas suelen causar daños a las casas de al lado.',
      ),
      Voice(
        'Vecino del sector',
        'En ciertas épocas del año el río es un peligro si uno quiere pasear cerca.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.contaminacion,
        'Aguas servidas, escombros y bacterias.',
        'El río recibe desechos orgánicos, basura, restos de construcción y aguas servidas. Se ha detectado la bacteria E. coli, peligrosa para la salud.',
      ),
      _problem(
        ProblemKind.abandono,
        'Áreas de descanso sin mantenimiento.',
        'Las bancas y zonas de encuentro están abandonadas, por eso las familias buscan otros barrios para jugar y pasear.',
      ),
      _problem(
        ProblemKind.erosion,
        'La orilla se desgasta.',
        'La extracción de piedras del río y la tala de árboles hacen que el agua se lleve la orilla y destruya el sendero.',
      ),
    ],
    timeline: const [
      TimelineStep('1974', 'La mayor parte del sector era campo y vegetación.'),
      TimelineStep(
        '2017',
        'El Municipio detectó casas que vertían aguas servidas al río y planificó una planta de tratamiento.',
      ),
      TimelineStep(
        '2025',
        'Las crecidas dañaron el sendero. Los vecinos esperan recuperar el río y sus parques.',
      ),
    ],
    species: const [
      Species(
        name: 'Ojo de poeta',
        emoji: '🌼',
        tag: 'Enredadera',
        text: 'Flor naranja con centro oscuro.',
      ),
      Species(
        name: 'Cedro',
        emoji: '🌳',
        tag: 'Árbol nativo',
        text: 'Madera valiosa y sombra fresca.',
      ),
      _sauce,
      Species(
        name: 'Campanilla',
        emoji: '🌻',
        tag: 'Arbusto',
        text: 'Flores amarillas para los colibríes.',
      ),
    ],
    quiz: const QuizQuestion(
      question: '¿Qué pasa con el sendero cuando el río crece por las lluvias?',
      options: [
        'La corriente destruye partes del sendero y deja escombros.',
        'El sendero se hace más largo.',
        'Nada, el sendero es de metal.',
      ],
      answer: 0,
      explanation: 'Sin árboles que protejan la orilla, la fuerza del agua se lleva el camino.',
    ),
  ),
  Place(
    id: 'tebaida',
    code: 'A3',
    name: 'Parque Lineal La Tebaida',
    shortName: 'La Tebaida',
    zone: Zone.sur,
    river: River.malacatos,
    position: const LatLng(-4.01818, -79.20266),
    totem: 3,
    landmark: true,
    headline: 'Inundaciones, erosión y contaminación generan alarma',
    tagline: 'El gran parque junto al río Malacatos que une a tres barrios.',
    description: 'Parque lineal con senderos, canchas y sauces junto al Malacatos; une los barrios La Tebaida, La Argelia y Los Geranios.',
    story: [
      'El Parque Lineal La Tebaida es el gran espacio verde del sur de Loja. Las familias vienen a pasear, correr, jugar y montar en bici junto al río.',
      'Pero cuando llueve fuerte, el río se desborda y cubre los senderos de lodo, ramas y basura.',
      'Para controlar el caudal se construyó un “desarenador”, una pequeña represa; aun así, no logra frenar las crecidas más fuertes.',
    ],
    fact: 'El parque tiene un “desarenador”: una pequeña represa que ayuda a regular el caudal del río Malacatos.',
    factTags: ['Familias', 'Ciclistas', 'Sauces'],
    scene: SceneSpec.park,
    photos: _photos('tebaida', [
      ('El parque lineal cubierto de lodo tras una crecida', false),
      ('Recorrido por los senderos del parque', false),
      ('Collage: la vida y los problemas del parque', true),
      ('Sauces, eucaliptos y palmas: los árboles del parque', true),
    ]),
    voices: const [
      Voice(
        'Visitante',
        'Siempre venimos al parque a dar un paseo con nuestro pequeño.',
      ),
      Voice(
        'Visitante',
        'El río me da mucha tranquilidad, menos cuando llueve.',
      ),
      Voice(
        'Joven del barrio',
        'Nos gusta planificar un partidito, lo malo es el lodo y la basura que no nos deja jugar tranquilos.',
      ),
      Voice(
        'Vecina',
        'El aspecto del río ha cambiado para mal, se llena de basura y ramas.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.inundacion,
        'El parque se inunda con cada lluvia intensa.',
        'Cada desborde cubre el parque de lodo y basura, daña los senderos y obliga a hacer costosas limpiezas.',
      ),
      _problem(
        ProblemKind.basura,
        'Plásticos, fundas y escombros en el cauce.',
        'Algunas personas arrojan basura al río y, como casi no se limpia, se queda estancada.',
      ),
      _problem(
        ProblemKind.olores,
        'El mal olor aleja a las visitas.',
        'Los vertidos sin tratar hacen que algunos días el río huela mal.',
      ),
      _problem(
        ProblemKind.erosion,
        'Orillas sin árboles.',
        'La tala en las riberas debilita la tierra y las crecidas socavan los senderos.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Antes',
        'El río corría entre campos y potreros del sur de la ciudad.',
      ),
      TimelineStep(
        'Parque lineal',
        'Se construyó el parque para acercar a las personas al río, con senderos, juegos y canchas.',
      ),
      TimelineStep(
        'Hoy',
        'Es el área verde más usada del sector, pero necesita limpieza y cuidado para no inundarse.',
      ),
    ],
    species: const [
      _sauce,
      _eucalipto,
      Species(
        name: 'Palma de abanico',
        emoji: '🌴',
        tag: 'Introducida',
        text: 'Sus hojas parecen abanicos.',
      ),
      Species(
        name: 'Aves del parque',
        emoji: '🐦',
        tag: 'Fauna',
        text: 'Los árboles atraen muchas aves.',
        isFauna: true,
      ),
    ],
    quiz: const QuizQuestion(
      question:
          '¿Qué ocurre en el parque cuando llueve muy fuerte en los Andes?',
      options: [
        'El río puede desbordarse y cubrir los senderos de lodo y basura.',
        'El río desaparece.',
        'El agua se queda quieta y limpia.',
      ],
      answer: 0,
      explanation: 'Con lluvias intensas el río recibe mucha agua de golpe; si está lleno de basura, se desborda.',
    ),
  ),
  Place(
    id: 'supermaxi',
    code: 'A4',
    name: 'Sector Supermaxi',
    shortName: 'Supermaxi',
    zone: Zone.sur,
    river: River.malacatos,
    position: const LatLng(-4.01268, -79.20308),
    totem: 4,
    headline: 'Lluvias en Loja: el río Malacatos se desborda y causa estragos',
    tagline: '“El río tiene memoria”.',
    description: 'Zona de comercio junto al Malacatos: Supermaxi, Mall Don Daniel, el Mercado La Tebaida y el hospital municipal.',
    story: [
      'Aquí la ciudad se llena de tiendas, el mercado, un centro comercial y un hospital. Mucha gente pasa cada día junto al río.',
      'Río arriba, el Malacatos corre libre; después aparece un talud a un lado y, al final, el río queda encerrado entre muros.',
      'Entre marzo y mayo llueve mucho y el río puede rebasar su cauce, como pasó en marzo de 2025.',
    ],
    fact: 'Entre marzo y mayo llueve más en Loja; por eso en esos meses el Malacatos crece y puede desbordarse.',
    factTags: ['Comercio', 'Mercado', 'Ciclovía'],
    scene: const SceneSpec(city: true, willows: 3, path: true, seed: 19),
    photos: _photos('supermaxi', [
      ('Puente peatonal sobre el Malacatos (el río va en azul)', false),
      ('Sendero junto al río', false),
      ('El río entre comercios y edificios', false),
      ('La calle frente al Supermaxi', false),
      ('Collage: juegos, deporte y comercio a orillas del río', true),
    ]),
    voices: const [
      Voice(
        'Vecino',
        'Antes la gente venía al río a descansar, ahora viene al mall… el ruido cambió.',
      ),
      Voice('Peatón', '¡Qué horrible olor! Caminaré más rápido.'),
      Voice(
        'Niña',
        '¡Mira! Aquí el río corre libre, sin muros… parece un lugar feliz. ¿Y por qué más adelante está tan encerrado?',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.inundacion,
        'El río rebasa su capacidad en invierno.',
        'Las lluvias de marzo a mayo hacen crecer el río; se dañan calles, áreas verdes y casas cercanas.',
      ),
      _problem(
        ProblemKind.muros,
        'Un río encerrado entre taludes.',
        'Para proteger las casas se construyeron taludes y muros; el río perdió su espacio y sus orillas naturales.',
      ),
      _problem(
        ProblemKind.inseguridad,
        'Esquinas solitarias y con malos olores.',
        'En ciertas horas, algunas esquinas junto al río se sienten inseguras y la gente prefiere otra ruta.',
      ),
    ],
    timeline: const [
      TimelineStep(
        '1990',
        'El Malacatos era natural y abierto, con casas alineadas a lo largo del río.',
      ),
      TimelineStep(
        '2010',
        'La ciudad se hizo más densa y se construyeron taludes para proteger las casas.',
      ),
      TimelineStep(
        '2024',
        'Zona de comercio y servicios; el río quedó oculto detrás de muros en algunos tramos.',
      ),
    ],
    species: const [
      Species(
        name: 'Sauce llorón',
        emoji: '🌳',
        tag: 'Ribereño',
        text: 'Sus ramas cuelgan hacia el agua.',
      ),
      _aliso,
      Species(
        name: 'Chilca',
        emoji: '🌿',
        tag: 'Arbusto nativo',
        text: 'Crece sola en las orillas.',
      ),
      Species(
        name: 'Acacia',
        emoji: '🌼',
        tag: 'Árbol',
        text: 'Flores amarillas en racimos.',
      ),
    ],
    quiz: const QuizQuestion(
      question: '¿Por qué mucha gente visita el tramo del río cerca del Mercado La Tebaida?',
      options: [
        'Porque hay comercio y espacios para jugar y pasear.',
        'Porque hay cascadas gigantes.',
        'Porque es un lugar para pescar ballenas.',
      ],
      answer: 0,
      explanation: 'El mercado, las tiendas, los senderos y los juegos atraen a muchas personas.',
    ),
  ),

  // ═════════════ ZONA CENTRO: el cauce creciente ═════════════
  Place(
    id: 'el_leon',
    code: 'B1',
    name: 'Sector El León',
    shortName: 'El León',
    zone: Zone.centro,
    river: River.malacatos,
    position: const LatLng(-4.00146, -79.20455),
    totem: 5,
    headline: 'El León bajo el agua: el costo ambiental del progreso',
    tagline: 'Un barrio muy activo que convive con el río cada invierno.',
    description: 'Sector del centro junto al Monumento El León, con muchas casas, comercios y tráfico a orillas del Malacatos.',
    story: [
      'El León pasó de ser un lugar tranquilo con campos y huertos a un barrio lleno de comercio y tránsito.',
      'Desde hace más de veinte años, cuando llueve fuerte, el río arrastra palos, troncos y arena que se atascan en los puentes y lo hacen desbordarse.',
      'Casi no quedan espacios libres: solo el 7 % del sector son áreas para recrearse.',
    ],
    fact: 'Cuando llueve fuerte, el río arrastra palos, troncos y arena que se atascan bajo los puentes y provocan desbordes.',
    factTags: ['Centro', 'Comercio', 'Puentes'],
    scene: const SceneSpec(city: true, willows: 2, bridge: true, seed: 13),
    photos: _photos('el_leon', [
      ('Cuatro miradas al Malacatos en El León', false),
      ('Ilustración: un río para jugar y pasear', true),
      ('Ilustración: un desagüe que vierte agua al río', true),
      ('Cómic: lo que perciben los vecinos', true),
    ]),
    voices: const [
      Voice(
        'Moradora',
        'Antes el sector era más tranquilo; hoy es un punto activo de la ciudad, con menos espacios para detenerse y estar.',
      ),
      Voice(
        'Comerciante',
        'Cada temporada de lluvias el río se desborda y afecta a nuestros negocios.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.inundacion,
        'Desbordes cada invierno desde hace 20 años.',
        'Las lluvias intensas hacen crecer el río; el agua y el lodo llegan a casas, comercios y calles.',
      ),
      _problem(
        ProblemKind.basura,
        'Troncos y basura atascados en los puentes.',
        'Lo que arrastra el río se acumula bajo los puentes y frena el paso del agua.',
      ),
      _problem(
        ProblemKind.contaminacion,
        'Descargas residuales en el río.',
        'Aguas sucias y desechos sólidos han deteriorado la calidad del agua.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Antes',
        'Un lugar tranquilo, con campos y huertos junto al río.',
      ),
      TimelineStep(
        'Hace 20 años',
        'Comienzan inundaciones frecuentes en temporada invernal.',
      ),
      TimelineStep(
        'Hoy',
        'Barrio de uso mixto (40 %): viviendas, comercios y servicios muy cerca del río.',
      ),
    ],
    species: const [
      Species(
        name: 'Jacaranda',
        emoji: '💜',
        tag: 'Ornamental',
        text: 'Se llena de flores moradas.',
      ),
      _faique,
      _sauce,
      _aliso,
    ],
    quiz: const QuizQuestion(
      question:
          '¿Qué se acumula bajo los puentes y hace que el río se desborde?',
      options: [
        'Palos, troncos, arena y basura que arrastra el río.',
        'Peces muy grandes.',
        'Hojas de papel de los colegios.',
      ],
      answer: 0,
      explanation: 'Esos materiales forman un tapón y el agua busca salir por los lados.',
    ),
  ),
  Place(
    id: 'puerta',
    code: 'B2',
    name: 'Parque Bolívar – Puerta de la Ciudad',
    shortName: 'Puerta de la Ciudad',
    zone: Zone.centro,
    river: River.malacatos,
    position: const LatLng(-3.99239, -79.20566),
    totem: 6,
    landmark: true,
    headline: 'Amenaza de inundación: el día que el río se cobró la ciudad',
    tagline:
        'El corazón de Loja, donde el Malacatos llega al encuentro del Zamora.',
    description: 'Tramo del Malacatos entre el Parque Bolívar y la Puerta de la Ciudad, en pleno centro histórico.',
    story: [
      'El lunes 10 de marzo de 2025 cayó un aguacero récord: 76,6 litros por metro cuadrado en solo 24 horas.',
      'El río Malacatos se desbordó, llenó las calles de lodo y el puente de la calle Imbabura colapsó.',
      'La basura que se tira al río viaja hasta los puentes y forma “micro-represas”. Por eso, cuidar el río es tarea de todos.',
    ],
    fact: 'El 10 de marzo de 2025 cayeron 76,6 litros de lluvia por metro cuadrado en 24 horas: ¡un récord que desbordó el Malacatos!',
    factTags: ['Centro histórico', 'Puente Bolívar', '10 de marzo 2025'],
    scene: SceneSpec.valley,
    photos: _photos('puerta', [
      ('El Parque Bolívar en una postal antigua', false),
      ('Ilustración: ayer y hoy del río en el centro', true),
      ('Caricatura: ¡la contaminación contra el río Malacatos!', true),
    ]),
    voices: const [
      Voice(
        'Wilson Cabrera, 33 años',
        'Los emprendedores nos vemos afectados cuando se desborda el río, porque se dañan nuestros productos.',
      ),
      Voice(
        'Brithany, 17 años',
        'El olor que sale del río es muy fuerte por los residuos que se botan allí.',
      ),
      Voice(
        'Katherine Ruiz, 22 años',
        'Me da inseguridad caminar por las aceras junto al río; debería haber más iluminación.',
      ),
      Voice(
        'Vecino',
        'No todo es culpa del municipio: las personas también tenemos que cuidar el río.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.inundacion,
        'El desborde del 10 de marzo de 2025.',
        'Una lluvia récord desbordó el río: calles con más de 50 cm de lodo y el puente de la calle Imbabura derrumbado.',
      ),
      _problem(
        ProblemKind.basura,
        'El “efecto represa” de la basura.',
        'Plásticos, palos y escombros se atoran bajo los puentes y tapan el río; en una tormenta, el agua se desborda.',
      ),
      _problem(
        ProblemKind.inseguridad,
        'Orillas oscuras y descuidadas.',
        'La falta de luz, la maleza y los escombros hacen que algunos tramos se sientan inseguros.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Antes',
        'El río era parte de la vida del centro; el Parque Bolívar era punto de encuentro.',
      ),
      TimelineStep(
        'Crecimiento',
        'La ciudad se hizo densa y el río perdió espacio entre calles y edificios.',
      ),
      TimelineStep(
        '10 de marzo de 2025',
        'Una lluvia récord desbordó el Malacatos y dañó el puente de la calle Imbabura.',
      ),
    ],
    species: const [
      Species(
        name: 'Molle',
        emoji: '🌳',
        tag: 'Nativo',
        text: 'Árbol resistente de hojas finas.',
      ),
      Species(
        name: 'Ceibo',
        emoji: '🌺',
        tag: 'Nativo',
        text: 'Flores rojas que atraen aves.',
      ),
      Species(
        name: 'Palma fénix',
        emoji: '🌴',
        tag: 'Introducida',
        text: 'Adorna parques y avenidas.',
      ),
      Species(
        name: 'Aves urbanas',
        emoji: '🐦',
        tag: 'Fauna',
        text: 'El 66 % de la fauna vista aquí son aves.',
        isFauna: true,
      ),
    ],
    quiz: const QuizQuestion(
      question: '¿Qué es el “efecto represa” de la basura?',
      options: [
        'La basura se atora bajo los puentes y tapa el río, que luego se desborda.',
        'Una represa hecha de botellas para guardar agua.',
        'Un juego de los niños en el parque.',
      ],
      answer: 0,
      explanation:
          'Cada botella cuenta: juntas pueden bloquear el paso del agua.',
    ),
  ),
  Place(
    id: 'mayorista',
    code: 'B3',
    name: 'Sector El Mayorista',
    shortName: 'El Mayorista',
    zone: Zone.centro,
    river: River.zamora,
    position: const LatLng(-3.98712, -79.20281),
    totem: 7,
    headline: 'Entre memorias y el abandono',
    tagline: 'El gran mercado de Loja, a orillas del río Zamora.',
    description: 'Sector del Mercado Mayorista Gran Colombia, junto a la Av. Orillas del Zamora, muy cerca de la Puerta de la Ciudad.',
    story: [
      'En los años 60 aquí había una plaza de ganado rodeada de cultivos, regados por los ríos Zamora y Malacatos.',
      'Luego se canalizó el río Zamora y se construyó la Av. Orillas del Zamora: los campos se volvieron ciudad y comercio.',
      'Hoy el Mayorista es un lugar lleno de vida comercial, pero las lluvias derrumbaron muros del río y faltan árboles y espacios verdes.',
    ],
    fact: 'En los años 60, aquí funcionaba una plaza de ganado rodeada de cultivos junto al río Zamora.',
    factTags: ['Mercado Gran Colombia', 'Av. Orillas del Zamora'],
    scene: const SceneSpec(city: true, willows: 2, seed: 23),
    photos: _photos('mayorista', [
      ('El río Zamora junto al Mayorista', false),
      ('Muros del río derrumbados por las lluvias', false),
      ('Escombros en la orilla del río', false),
      ('Caminando junto al río', false),
      ('Collage histórico del sector', true),
    ]),
    voices: const [
      Voice('Niño del barrio', '¡Oh, mi pelota ha caído al río!'),
      Voice('Vecina', 'Qué triste… hay tantos escombros en la orilla del río.'),
      Voice('Peatón', 'No puedo caminar, ¡las veredas ya no existen!'),
      Voice(
        'Visitante del parque',
        'Hay tanto espacio verde y ni un solo árbol grande que dé sombra.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.muros,
        'Muros caídos que desvían el agua.',
        'Las fuertes lluvias derrumbaron los muros que canalizan el río; sus restos afectan puentes y caminos.',
      ),
      _problem(
        ProblemKind.contaminacion,
        'Aguas servidas y desechos del comercio.',
        'El río recibe aguas sucias y basura del comercio, y se ha vuelto un foco de contaminación.',
      ),
      _problem(
        ProblemKind.abandono,
        'Pocas áreas verdes y caminos intransitables.',
        'Las veredas junto al río están destruidas y casi no hay sombra ni espacios para estar.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Años 60',
        'Plaza de ganado y cultivos junto al río, sobre el antiguo “Carretero Norte”.',
      ),
      TimelineStep(
        'Canalización',
        'Se semicanalizó el río Zamora y se abrió la Av. Orillas del Zamora.',
      ),
      TimelineStep(
        'Hoy',
        'Centro comercial de la ciudad, con un río que pide recuperar sus orillas.',
      ),
    ],
    species: const [
      Species(
        name: 'Guararo',
        emoji: '🌳',
        tag: 'Nativo',
        text: 'Árbol de flores moradas.',
      ),
      Species(
        name: 'Capulí',
        emoji: '🍒',
        tag: 'Nativo',
        text: 'Frutos dulces para las aves.',
      ),
      _aliso,
      Species(
        name: 'Álamo',
        emoji: '🌲',
        tag: 'Introducido',
        text: 'Alto y de hojas que se mueven con el viento.',
      ),
    ],
    quiz: const QuizQuestion(
      question: '¿Qué había en el sector Mayorista en los años 60?',
      options: [
        'Una plaza de ganado rodeada de cultivos.',
        'Un aeropuerto.',
        'Una playa con arena.',
      ],
      answer: 0,
      explanation: 'Los terrenos fértiles junto al río se usaban para cultivar y criar animales.',
    ),
  ),

  // ═════════════ ZONA NORTE: donde el río busca su salida ═════════════
  Place(
    id: 'jipiro',
    code: 'C1',
    name: 'Parque Jipiro',
    shortName: 'Parque Jipiro',
    zone: Zone.norte,
    river: River.zamora,
    position: const LatLng(-3.97275, -79.20108),
    totem: 8,
    landmark: true,
    headline: 'Jipiro: entre la belleza y la amenaza fluvial',
    tagline: 'El parque más querido de Loja, con su laguna y sus aves.',
    description: 'Parque Recreacional Jipiro, atravesado por el río Jipiro, afluente del Zamora; su laguna es refugio de aves.',
    story: [
      'El Parque Jipiro es uno de los lugares favoritos de las familias lojanas. Lo atraviesa el río Jipiro, que desemboca en el Zamora.',
      'Antes, este terreno era una finca agropecuaria de la familia Álvarez; hoy es un gran espacio público.',
      'En invierno, las crecidas inundan las zonas bajas del parque y la laguna acumula sedimentos y basura.',
    ],
    fact: 'El Parque Jipiro está atravesado por el río Jipiro, un afluente del Zamora; su laguna es refugio de aves.',
    factTags: ['Laguna', 'Aves', 'Familias'],
    scene: SceneSpec.jipiro,
    photos: _photos('jipiro', [
      ('Agua de la crecida dentro del Parque Jipiro', false),
      ('La laguna después de una crecida', false),
      ('Cómic: voces del parque', true),
    ]),
    voices: const [
      Voice(
        'Usuarios del parque',
        'Esperamos soluciones para las inundaciones que se repiten cada invierno.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.inundacion,
        'Crecidas que inundan las zonas bajas.',
        'Cuando el Zamora y su afluente crecen, el agua entra al parque y pone en riesgo a los visitantes.',
      ),
      _problem(
        ProblemKind.contaminacion,
        'La laguna se llena de residuos.',
        'Tras cada crecida la laguna acumula sedimentos, basura y agua contaminada, y las aves pierden su refugio.',
      ),
    ],
    timeline: const [
      TimelineStep('Antes', 'Una finca agropecuaria de la familia Álvarez.'),
      TimelineStep(
        'Parque Recreacional',
        'Se creó el parque y el barrio creció alrededor del espacio público.',
      ),
      TimelineStep(
        '2025',
        'Loja tiene unos 250 000 habitantes y Jipiro sigue siendo su gran pulmón verde.',
      ),
    ],
    species: const [
      Species(
        name: 'Guayacán',
        emoji: '🌼',
        tag: 'Nativo',
        text: 'Se cubre de flores amarillas.',
      ),
      Species(
        name: 'Sangre de drago',
        emoji: '🌳',
        tag: 'Nativo',
        text: 'Su savia roja es medicinal.',
      ),
      Species(
        name: 'Cedro',
        emoji: '🌲',
        tag: 'Nativo',
        text: 'Da sombra y refugio a la fauna.',
      ),
      Species(
        name: 'Aves acuáticas',
        emoji: '🦆',
        tag: 'Fauna',
        text: 'Viven en la laguna del parque.',
        isFauna: true,
      ),
    ],
    quiz: const QuizQuestion(
      question: '¿Qué río atraviesa el Parque Jipiro?',
      options: [
        'El río Jipiro, afluente del Zamora.',
        'El río Amazonas.',
        'Ningún río.',
      ],
      answer: 0,
      explanation: 'El río Jipiro lleva sus aguas al Zamora, el río más caudaloso del valle.',
    ),
  ),
  Place(
    id: 'la_paz',
    code: 'C2',
    name: 'Barrio La Paz',
    shortName: 'La Paz',
    zone: Zone.norte,
    river: River.zamora,
    position: const LatLng(-3.96976, -79.20592),
    totem: 9,
    headline: 'El río Zamora: un eje natural que une',
    tagline: 'Barrios que crecieron junto al río y su sendero ecológico.',
    description: 'Barrios La Paz, Las Pitas y La Inmaculada, a lo largo del río Zamora y su sendero ecológico.',
    story: [
      'Hace más de 70 años, aquí había terrenos agrícolas y casas dispersas. Hoy es un corredor urbano que crece junto al río Zamora.',
      'El río y su sendero ecológico unen los barrios y regulan el clima. Los vecinos aún conservan vegetación en la orilla.',
      'Pero el sendero necesita luz, limpieza y bancas: sin eso, cada vez menos personas lo recorren.',
    ],
    fact: 'En La Paz y Las Pitas, los vecinos conservan vegetación junto al río que funciona como barrera natural ante las crecidas.',
    factTags: ['Sendero ecológico', 'Las Pitas', 'La Inmaculada'],
    scene: const SceneSpec(willows: 5, path: true, seed: 31),
    photos: _photos('la_paz', [
      ('Ilustración: el sendero ecológico junto al Zamora', true),
      ('Vista satelital de La Paz, Las Pitas y La Inmaculada', false),
    ]),
    voices: const [
      Voice(
        'Vecina',
        'Trato de venir a trotar en las mañanas, porque en la noche todo es oscuro y peligroso.',
      ),
      Voice(
        'Vecino',
        'Cada lluvia se lleva otro pedazo del talud y nadie viene a reforzarlo.',
      ),
      Voice(
        'Vecina',
        'No hay ni un bote cerca para tirar los desechos; la mayoría bota su basura al río.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.erosion,
        'Cada lluvia se lleva parte del talud.',
        'La orilla se desgasta con las crecidas y el sendero se llena de lodo.',
      ),
      _problem(
        ProblemKind.basura,
        'Basura sin basureros cerca.',
        'Al no haber basureros, algunas personas tiran sus desechos al río.',
      ),
      _problem(
        ProblemKind.inseguridad,
        'Sendero oscuro y sin conexión.',
        'Sin alumbrado, con puentes en mal estado y mal olor, pocos se animan a recorrerlo.',
      ),
    ],
    timeline: const [
      TimelineStep('1970', 'Campos agrícolas y viviendas dispersas.'),
      TimelineStep(
        '2003 – 2014',
        'Nuevas vías y equipamientos conectan el sector con el centro.',
      ),
      TimelineStep(
        '2024',
        'Un barrio denso que necesita parques y corredores verdes junto al río.',
      ),
    ],
    species: const [
      Species(
        name: 'Sauce llorón',
        emoji: '🌳',
        tag: 'Ribereño',
        text: 'Estabiliza los taludes.',
      ),
      _aliso,
      Species(
        name: 'Higuera',
        emoji: '🌿',
        tag: 'Árbol',
        text: 'Sus frutos alimentan a las aves.',
      ),
      _mirlo,
    ],
    quiz: const QuizQuestion(
      question:
          '¿Qué hace la vegetación que los vecinos conservan en la orilla?',
      options: [
        'Funciona como barrera natural frente a las crecidas.',
        'Hace que el río se seque.',
        'Atrae más basura.',
      ],
      answer: 0,
      explanation:
          'Las plantas y sus raíces frenan el agua y sujetan la tierra.',
    ),
  ),
  Place(
    id: 'amable_maria',
    code: 'C3',
    name: 'Barrio Amable María',
    shortName: 'Amable María',
    zone: Zone.norte,
    river: River.zamora,
    position: const LatLng(-3.96175, -79.21263),
    totem: 10,
    headline: 'Río, residencia y verde natural: borde y conflicto urbano',
    tagline: 'Un corredor verde que divide… y también une barrios.',
    description: 'Barrio junto al río Zamora y su sendero ecológico, en el norte de la ciudad.',
    story: [
      'El río Zamora pasa entre Amable María y los barrios vecinos. Su corredor verde es ideal para caminar, trotar o pasear mascotas.',
      'Pero cuando llueve fuerte, las alcantarillas no alcanzan y el agua se empoza en las partes bajas del barrio.',
      'La quebrada de Bellavista arrastra lodo y piedras a las calles en temporada de lluvias.',
    ],
    fact: 'Las calles y los techos no absorben agua: la lluvia corre rápido hacia el río en lugar de filtrarse en la tierra.',
    factTags: ['Sendero', 'Quebrada Bellavista'],
    scene: const SceneSpec(willows: 4, seed: 35),
    photos: _photos('amable_maria', [
      ('Calle mojada después de la lluvia', false),
      ('Vista satelital: el río Zamora entre barrios', false),
      ('Ilustración: calle inundada por la lluvia', true),
    ]),
    voices: const [
      Voice(
        'Vecino, 70 años',
        'Esta zona se inunda cuando las lluvias son fuertes, porque las alcantarillas no abastecen y se tapan.',
      ),
      Voice(
        'Vecina',
        'Todas las mañanas salgo al sendero a caminar, es la hora más segura.',
      ),
      Voice(
        'Ganadera, 53 años',
        'En mis terrenos no se encharca, porque al tener mucho verde el agua se absorbe.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.inundacion,
        'Alcantarillas que colapsan con cada lluvia.',
        'El agua baja por las calles, se empoza en las partes bajas y llega a las casas.',
      ),
      _problem(
        ProblemKind.contaminacion,
        'Aguas residuales sin tratar.',
        'Llegan descargas sin tratamiento al río y producen malos olores.',
      ),
      _problem(
        ProblemKind.erosion,
        'Sedimentos de la quebrada Bellavista.',
        'La quebrada arrastra lodo y piedras a las vías, afectando a carros y peatones.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Mediados del siglo XX',
        'Zonas naturales que absorbían la lluvia.',
      ),
      TimelineStep(
        'Crecimiento',
        'Casas y comercios cubrieron el suelo y el agua corre más rápido al río.',
      ),
      TimelineStep(
        'Hoy',
        'Un corredor verde con gran potencial para la recreación, si se cuida.',
      ),
    ],
    species: const [
      Species(
        name: 'Acacia blanca',
        emoji: '🌼',
        tag: 'Árbol',
        text: 'Aporta color, sombra y calma.',
      ),
      Species(
        name: 'Álamo',
        emoji: '🌲',
        tag: 'Árbol',
        text: 'Alto y movido por el viento.',
      ),
      Species(
        name: 'Fresno',
        emoji: '🌳',
        tag: 'Árbol',
        text: 'Crece hasta 40 m de alto.',
      ),
      _sauce,
    ],
    quiz: const QuizQuestion(
      question: '¿Por qué los terrenos con mucho verde no se encharcan tanto?',
      options: [
        'Porque la tierra con plantas absorbe el agua de lluvia.',
        'Porque allí nunca llueve.',
        'Porque el pasto empuja el agua al cielo.',
      ],
      answer: 0,
      explanation: 'El suelo verde es como una esponja; el cemento, no.',
    ),
  ),
  Place(
    id: 'comil',
    code: 'C4',
    name: 'Sector Comil – La Banda',
    shortName: 'Comil',
    zone: Zone.norte,
    river: River.zamora,
    position: const LatLng(-3.94968, -79.21962),
    totem: 11,
    headline: 'Río de memoria y vida lojana',
    tagline: 'Donde antes había una “playita” junto al río.',
    description: 'Barrio La Banda, junto al Colegio Militar (Comil) y al río Zamora, con huertas, ganadería y un sendero ecológico.',
    story: [
      'La Banda era famosa por sus huertas y cañaverales: las familias cultivaban maíz, fréjol y hortalizas con agua del río.',
      'Cerca del Colegio Militar había caminos empedrados y potreros hasta la orilla. Los niños jugaban y cruzaban el río por pequeños puentes.',
      'Entre 1950 y 1980 se canalizó el río. Hoy hay escombros y basura, y los vecinos extrañan el río de antes.',
    ],
    fact: 'Antes, en La Banda había una “playita” junto al río donde el agua bajaba suave y los niños jugaban.',
    factTags: ['Colegio Militar', 'Huertas', 'Memoria'],
    scene: const SceneSpec(willows: 4, path: true, seed: 39),
    photos: _photos('comil', [
      ('El Zamora junto al barrio La Banda', false),
      ('El río y su orilla de tierra', false),
      ('Puente y fábricas junto al río', false),
      ('El Zamora sigue su viaje al norte', false),
      ('Agua turquesa entre piedras', false),
    ]),
    voices: const [
      Voice(
        'Don Alberto, 69 años',
        'Antes teníamos una playita aquí abajo, donde el agua bajaba suave. Con el deslave se la llevó toda.',
      ),
      Voice(
        'Doña Teresa, 62 años',
        'Cuando llegué, el río era clarito. Se podía ver el fondo. Ahora da tristeza.',
      ),
      Voice(
        'Sra. Beatriz, 54 años',
        'Ya no hay árboles como antes que frenaban el agua. Todo eso se ha ido perdiendo.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.basura,
        'El río usado como botadero.',
        'Algunas personas tiran basura y escombros al río, y eso produce malos olores.',
      ),
      _problem(
        ProblemKind.contaminacion,
        'Espuma, jabones y aguas residuales.',
        'Hay descargas directas de aguas sucias, aunque el barrio tiene alcantarillado.',
      ),
      _problem(
        ProblemKind.muros,
        'Canalización y pérdida de vegetación.',
        'Los muros de hormigón quitaron la vegetación de la orilla y el agua corre más rápido cuando llueve.',
      ),
    ],
    timeline: const [
      TimelineStep(
        'Antes de 1950',
        'Huertas, cañaverales y una “playita” donde jugaban los niños.',
      ),
      TimelineStep(
        '1950 – 1980',
        'Primeras obras de canalización para controlar inundaciones.',
      ),
      TimelineStep(
        'Hoy',
        'Barrio residencial que recuerda con cariño al río limpio de antes.',
      ),
    ],
    species: const [
      Species(
        name: 'Planta paraguas',
        emoji: '☂️',
        tag: 'Planta',
        text: '¡Sus hojas gigantes sirven de paraguas!',
      ),
      Species(
        name: 'Molle',
        emoji: '🌳',
        tag: 'Nativo',
        text: 'Árbol resistente del valle.',
      ),
      _faique,
      Species(
        name: 'Guararo',
        emoji: '🌸',
        tag: 'Nativo',
        text: 'Flores que alegran la ribera.',
      ),
    ],
    quiz: const QuizQuestion(
      question:
          '¿Qué cultivaban antes las familias de La Banda con el agua del río?',
      options: [
        'Maíz, fréjol y hortalizas.',
        'Hielo.',
        'Nada, el río no se usaba.',
      ],
      answer: 0,
      explanation: 'Las tierras junto al río eran muy fértiles.',
    ),
  ),
  Place(
    id: 'sauces1',
    code: 'C5',
    name: 'Barrio Sauces Norte I',
    shortName: 'Sauces Norte I',
    zone: Zone.norte,
    river: River.zamora,
    position: const LatLng(-3.93902, -79.22289),
    totem: 12,
    headline: 'De lote baldío a corazón popular: la historia que no se cuenta',
    tagline: '“Antes aquí no había nada… ahora tenemos de todo”.',
    description: 'Barrio nacido de un programa de vivienda de 1986, junto al río Zamora en el norte de Loja.',
    story: [
      'Hace unas décadas, Sauces Norte era un terreno polvoriento con lotes baldíos. Hoy es un barrio con vida propia.',
      'Sus canchas reúnen a familias, jóvenes y adultos mayores: el deporte también construye comunidad.',
      'El río que lo atraviesa recibe llantas, plásticos y basura. A un lado pasan los buses; al otro, el ganado pasta en la orilla.',
    ],
    fact: 'El barrio Sauces Norte nació en 1986 como un programa de vivienda de la Junta Nacional de Vivienda.',
    factTags: ['Programa de vivienda', 'Canchas', 'Comunidad'],
    scene: const SceneSpec(willows: 3, city: true, seed: 43),
    photos: _photos('sauces1', [
      ('Panorámica de Sauces Norte', false),
      ('Foto aérea de 1962: aquí aún había campos', false),
      ('La zona hoy, llena de casas', false),
      ('Árbol grande en el barrio', false),
      ('Cómic: ¿cómo se siente vivir en Sauces Norte?', true),
    ]),
    voices: const [
      Voice(
        'Morador',
        'Antes aquí no había nada, ni calles, ni luz, ni agua. Ahora tenemos de todo, aunque falta mejorar muchas cosas.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.basura,
        'Llantas, plásticos y desechos en el río.',
        'El mal manejo de la basura llena las orillas y el cauce, y afecta la salud de los vecinos.',
      ),
      _problem(
        ProblemKind.inundacion,
        'Calles que se inundan.',
        'Sin un buen drenaje, el agua de lluvia baja por la avenida y se acumula entre las casas.',
      ),
    ],
    timeline: const [
      TimelineStep('1962', 'Campos y caminos de tierra.'),
      TimelineStep('1986', 'Nace el programa de vivienda Sauces Norte.'),
      TimelineStep(
        '2024',
        'Un barrio conectado por la vía Sauces Norte – Solamar – Jimbilla.',
      ),
    ],
    species: const [
      Species(
        name: 'Nogal',
        emoji: '🌰',
        tag: 'Árbol',
        text: 'Da nueces y mucha sombra.',
      ),
      Species(
        name: 'Higuerón',
        emoji: '🌳',
        tag: 'Árbol',
        text: 'Árbol grande de raíces fuertes.',
      ),
      _aliso,
      _faique,
    ],
    quiz: const QuizQuestion(
      question: '¿En qué año nació el programa de vivienda Sauces Norte?',
      options: ['En 1986.', 'En 1492.', 'En 2050.'],
      answer: 0,
      explanation: 'Lo promovió la Junta Nacional de Vivienda en las afueras de la ciudad.',
    ),
  ),
  Place(
    id: 'sauces2',
    code: 'C6',
    name: 'Barrio Sauces Norte II',
    shortName: 'Sauces Norte II',
    zone: Zone.norte,
    river: River.zamora,
    position: const LatLng(-3.92693, -79.22458),
    totem: 13,
    headline: 'Un barrio en zona de alto riesgo por inundaciones',
    tagline: 'Campos, cultivos y la planta que limpia el agua de Loja.',
    description: 'Barrio productivo del norte, con cultivos, ganado y la planta de tratamiento de aguas residuales junto al Zamora.',
    story: [
      'Aquí todavía manda el verde: hay cultivos de plátano, café y caña, y ganado junto al río.',
      'En el barrio está la planta de tratamiento de aguas residuales, pero aún no alcanza a limpiar toda el agua sucia que llega al río.',
      'El 13 de marzo de 2025, fuertes lluvias inundaron ocho sectores del norte de Loja, entre ellos Sauces Norte.',
    ],
    fact: 'En Sauces Norte está la planta que limpia las aguas residuales de Loja, pero gran parte del agua sucia aún llega al río sin tratar.',
    factTags: ['Planta de tratamiento', 'Cultivos', 'Ganado'],
    scene: const SceneSpec(willows: 3, seed: 47),
    photos: _photos('sauces2', [
      ('Ganado pastando junto al río', false),
      ('Campos y cultivos del barrio', false),
      ('Una de las vías de tierra del barrio', false),
      ('Corte: el río, la vía y el puente', true),
    ]),
    voices: const [
      Voice(
        'Morador',
        'Hace 10 años se inundaron las aulas de la escuela del barrio; el agua bajaba por la carretera como un río.',
      ),
    ],
    problems: [
      _problem(
        ProblemKind.contaminacion,
        'Agua sin tratar que llega al río.',
        'Los colectores llevan aguas residuales a la planta, pero no se alcanza a tratar todo el caudal y el río se sigue contaminando.',
      ),
      _problem(
        ProblemKind.inundacion,
        'Barrio en zona de alto riesgo.',
        'Con las lluvias fuertes, el agua baja por las calles y el río puede desbordarse.',
      ),
      _problem(
        ProblemKind.basura,
        'Sin recolección de basura.',
        'Parte del barrio no tiene alcantarillado ni recolección, y los desechos terminan en el entorno natural.',
      ),
    ],
    timeline: const [
      TimelineStep('Antes', 'Tierras de cultivo y pastoreo junto al río.'),
      TimelineStep(
        'Hace 20 años',
        'Los vecinos conviven con lodo en invierno y polvo en verano.',
      ),
      TimelineStep(
        '13 de marzo de 2025',
        'Lluvias intensas inundaron ocho sectores del norte, entre ellos Sauces Norte.',
      ),
    ],
    species: const [
      Species(
        name: 'Plátano',
        emoji: '🍌',
        tag: 'Cultivo',
        text: 'Se cultiva junto al río.',
      ),
      Species(
        name: 'Café',
        emoji: '☕',
        tag: 'Cultivo',
        text: 'Crece en el clima templado del valle.',
      ),
      Species(
        name: 'Caña de azúcar',
        emoji: '🎋',
        tag: 'Cultivo',
        text: 'Dulce y muy alta.',
      ),
      _sauce,
    ],
    quiz: const QuizQuestion(
      question: '¿Para qué sirve la planta de tratamiento de aguas residuales?',
      options: [
        'Para limpiar el agua sucia antes de devolverla al río.',
        'Para fabricar lluvia.',
        'Para criar peces de colores.',
      ],
      answer: 0,
      explanation: 'Mientras más agua se trate, más limpio llega el Zamora a la Amazonía.',
    ),
  ),
]);

/// Contenido en uso: empieza igual al empaquetado y se actualiza con lo que
/// el equipo edite en Firestore (ver `Cloud.syncContent`).
final List<Place> places = [...bundledPlaces];
