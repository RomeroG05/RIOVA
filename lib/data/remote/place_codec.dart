import 'package:latlong2/latlong.dart';

import '../models/place.dart';

/// Conversión entre [Place] y documentos de Firestore (`sectors/{id}`).
///
/// La app trae todo el contenido empaquetado (funciona sin internet). Lo que
/// el equipo edite en Firestore se superpone a esa base: cada campo que falte
/// o tenga un tipo inválido conserva el valor local, así un documento a medio
/// editar nunca rompe la app. Las fotos (assets) y la ilustración no se
/// pueden cambiar desde Firestore; sí sus pies de foto.
abstract final class PlaceCodec {
  static Map<String, Object?> toMap(Place p) => {
    'id': p.id,
    'code': p.code,
    'order': p.totem,
    'name': p.name,
    'shortName': p.shortName,
    'zone': p.zone.name,
    'river': p.river.name,
    'lat': p.position.latitude,
    'lng': p.position.longitude,
    'totem': p.totem,
    'qr': p.qrPayload,
    'landmark': p.landmark,
    'headline': p.headline,
    'tagline': p.tagline,
    'description': p.description,
    'story': p.story,
    'fact': p.fact,
    'factTags': p.factTags,
    'photos': [
      for (final ph in p.photos)
        {'asset': ph.asset, 'caption': ph.caption, 'drawing': ph.drawing},
    ],
    'voices': [
      for (final v in p.voices) {'who': v.who, 'quote': v.quote},
    ],
    'problems': [
      for (final pr in p.problems)
        {'kind': pr.kind.name, 'summary': pr.summary, 'detail': pr.detail},
    ],
    'timeline': [
      for (final t in p.timeline) {'title': t.title, 'text': t.text},
    ],
    'species': [
      for (final s in p.species)
        {
          'name': s.name,
          'emoji': s.emoji,
          'tag': s.tag,
          'text': s.text,
          'fauna': s.isFauna,
        },
    ],
    'quiz': quizToMap(p.quiz),
  };

  static Map<String, Object?> quizToMap(QuizQuestion q) => {
    'question': q.question,
    'options': q.options,
    'answer': q.answer,
    'explanation': q.explanation,
  };

  /// Aplica un documento remoto sobre [base].
  static Place merge(Place base, Map<String, Object?> d) {
    String str(String k, String fallback) {
      final v = d[k];
      return v is String && v.trim().isNotEmpty ? v : fallback;
    }

    List<String> strings(String k, List<String> fallback) {
      final v = d[k];
      if (v is! List) return fallback;
      final out = v
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList();
      return out.isEmpty ? fallback : out;
    }

    List<T> list<T>(
      String k,
      List<T> fallback,
      T? Function(Map<String, Object?> m) parse,
    ) {
      final v = d[k];
      if (v is! List) return fallback;
      final out = <T>[];
      for (final item in v) {
        if (item is Map) {
          final parsed = parse(item.cast<String, Object?>());
          if (parsed != null) out.add(parsed);
        }
      }
      return out.isEmpty ? fallback : out;
    }

    final lat = d['lat'], lng = d['lng'];
    final position =
        lat is num && lng is num && lat.abs() <= 90 && lng.abs() <= 180
        ? LatLng(lat.toDouble(), lng.toDouble())
        : base.position;

    // Los pies de foto se aplican por posición; los archivos son los locales.
    final remotePhotos = d['photos'];
    final photos = [
      for (final (i, ph) in base.photos.indexed)
        () {
          if (remotePhotos is List &&
              i < remotePhotos.length &&
              remotePhotos[i] is Map) {
            final caption = (remotePhotos[i] as Map)['caption'];
            if (caption is String && caption.trim().isNotEmpty) {
              return PlacePhoto(ph.asset, caption, drawing: ph.drawing);
            }
          }
          return ph;
        }(),
    ];

    return Place(
      id: base.id,
      code: str('code', base.code),
      name: str('name', base.name),
      shortName: str('shortName', base.shortName),
      zone: base.zone,
      river: base.river,
      position: position,
      totem: base.totem,
      landmark: d['landmark'] is bool ? d['landmark']! as bool : base.landmark,
      headline: str('headline', base.headline),
      tagline: str('tagline', base.tagline),
      description: str('description', base.description),
      story: strings('story', base.story),
      fact: str('fact', base.fact),
      factTags: strings('factTags', base.factTags),
      scene: base.scene,
      photos: photos,
      voices: list('voices', base.voices, (m) {
        final who = m['who'], quote = m['quote'];
        return who is String && quote is String && quote.trim().isNotEmpty
            ? Voice(who, quote)
            : null;
      }),
      problems: list('problems', base.problems, (m) {
        final kind = ProblemKind.values.asNameMap()[m['kind']];
        final summary = m['summary'], detail = m['detail'];
        if (kind == null || summary is! String || detail is! String) {
          return null;
        }
        return RiverProblem(
          kind: kind,
          title: kind.title,
          summary: summary,
          detail: detail,
          help: kind.help,
          icon: kind.icon,
          color: kind.color,
        );
      }),
      timeline: list('timeline', base.timeline, (m) {
        final title = m['title'], text = m['text'];
        return title is String && text is String
            ? TimelineStep(title, text)
            : null;
      }),
      species: list('species', base.species, (m) {
        final name = m['name'], text = m['text'];
        if (name is! String || text is! String) return null;
        return Species(
          name: name,
          emoji: m['emoji'] is String ? m['emoji']! as String : '🌿',
          tag: m['tag'] is String ? m['tag']! as String : '',
          text: text,
          isFauna: m['fauna'] == true,
        );
      }),
      quiz: quizFromMap(d['quiz'], base.quiz),
    );
  }

  static QuizQuestion quizFromMap(Object? raw, QuizQuestion fallback) {
    if (raw is! Map) return fallback;
    final q = raw['question'], opts = raw['options'], ans = raw['answer'];
    if (q is! String || opts is! List || ans is! num) return fallback;
    final options = opts.whereType<String>().toList();
    if (options.length < 2 || ans < 0 || ans >= options.length) return fallback;
    return QuizQuestion(
      question: q,
      options: options,
      answer: ans.toInt(),
      explanation: raw['explanation'] is String
          ? raw['explanation']! as String
          : fallback.explanation,
    );
  }
}
