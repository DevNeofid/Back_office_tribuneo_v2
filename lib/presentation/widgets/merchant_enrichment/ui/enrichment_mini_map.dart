import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/common.dart';
import '../../arc/arc.dart';
import 'enrichment_dialog.dart';

/// Point géographique.
typedef GeoPoint = ({double lat, double lng});

/// Fond affiché sous les tuiles (chargement, hors ligne).
const Color _mapPaper = Color(0xffF3F0E8);

/// Ombre des contrôles et pastilles posés sur la carte.
const List<BoxShadow> _mapShadow = [
  BoxShadow(color: Color(0x331F2240), blurRadius: 6, offset: Offset(0, 2)),
];

/// Tuiles « Plan IGN » de la Géoplateforme (service public, sans clé) et
/// projection Web Mercator.
abstract final class IgnTiles {
  static const double tileSize = 256;
  static const int minZoom = 5, maxZoom = 19;

  static String url(int z, int x, int y) =>
      'https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0'
      '&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&STYLE=normal&TILEMATRIXSET=PM'
      '&FORMAT=image/png&TILEMATRIX=$z&TILEROW=$y&TILECOL=$x';

  static double worldSize(int z) => math.pow(2, z).toDouble() * tileSize;

  /// Position en pixels du monde au zoom [z].
  static Offset project(GeoPoint p, int z) {
    final double scale = worldSize(z);
    final double latRad = p.lat * math.pi / 180;
    return Offset(
        (p.lng + 180) / 360 * scale,
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            scale);
  }

  static GeoPoint unproject(Offset world, int z) {
    final double scale = worldSize(z);
    final double n = math.pi * (1 - 2 * world.dy / scale);
    final double lat =
        math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
    return (lat: lat, lng: world.dx / scale * 360 - 180);
  }

  static double metersPerPixel(double lat, int z) =>
      156543.03392 * math.cos(lat * math.pi / 180) / math.pow(2, z);

  /// Carte complète sur le Géoportail, dans un nouvel onglet.
  static String geoportail(GeoPoint p) =>
      'https://www.geoportail.gouv.fr/carte?c=${p.lng},${p.lat}&z=18&permalink=yes';

  static String format(GeoPoint p) =>
      '${p.lat.toStringAsFixed(6)}, ${p.lng.toStringAsFixed(6)}';
}

/// Fond de carte centré sur [center] (pixels du monde au zoom [zoom]), avec
/// des éléments posés par position géographique.
class _TileLayer extends StatelessWidget {
  final int zoom;
  final Offset center;
  final List<({GeoPoint at, Widget child, Offset anchor})> overlays;

  /// Retrait de l'attribution IGN par rapport aux bords.
  final double attributionInset;
  const _TileLayer(
      {required this.zoom,
      required this.center,
      this.overlays = const [],
      this.attributionInset = 8});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        const double t = IgnTiles.tileSize;
        final double width = size.maxWidth, height = size.maxHeight;
        final double left = center.dx - width / 2, top = center.dy - height / 2;
        final int maxIndex = math.pow(2, zoom).toInt() - 1;
        final int x0 = (left / t).floor(), x1 = ((left + width) / t).floor();
        final int y0 = (top / t).floor(), y1 = ((top + height) / t).floor();
        return Stack(clipBehavior: Clip.hardEdge, children: [
          const Positioned.fill(child: ColoredBox(color: _mapPaper)),
          for (var tx = x0; tx <= x1; tx++)
            for (var ty = y0; ty <= y1; ty++)
              if (tx >= 0 && ty >= 0 && tx <= maxIndex && ty <= maxIndex)
                Positioned(
                  key: ValueKey('tile-$zoom-$tx-$ty'),
                  left: tx * t - left,
                  top: ty * t - top,
                  width: t,
                  height: t,
                  child: Image.network(
                    IgnTiles.url(zoom, tx, ty),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    // Hors ligne ou service indisponible : fond neutre.
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: _mapPaper),
                  ),
                ),
          for (final o in overlays)
            Positioned(
                left: IgnTiles.project(o.at, zoom).dx - left - o.anchor.dx,
                top: IgnTiles.project(o.at, zoom).dy - top - o.anchor.dy,
                child: IgnorePointer(child: o.child)),
          Positioned(
            right: attributionInset,
            bottom: attributionInset,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: const Text('© IGN – Plan IGN',
                  style: TextStyle(fontSize: 10, color: kText2)),
            ),
          ),
        ]);
      });
}

/// Repère dessiné (pas d'icône : aucune dépendance à la police d'icônes).
class MapPin extends StatelessWidget {
  final Color color;
  final double size;
  const MapPin({super.key, this.color = kRed, this.size = 36});

  /// Pointe du repère, par rapport à son coin haut gauche.
  static Offset anchor(double size) => Offset(size * 0.35, size);

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size * 0.7,
      height: size,
      child: CustomPaint(painter: _PinPainter(color)));
}

class _PinPainter extends CustomPainter {
  final Color color;
  _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height, r = w / 2;
    final Path pin = Path()
      ..moveTo(w / 2, h)
      ..quadraticBezierTo(w * 0.12, h * 0.62, 0, r)
      ..arcTo(Rect.fromCircle(center: Offset(r, r), radius: r), math.pi,
          math.pi, false)
      ..quadraticBezierTo(w * 0.88, h * 0.62, w / 2, h)
      ..close();
    canvas.drawShadow(pin, Colors.black, 3, false);
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(
        pin,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(Offset(r, r), r * 0.38, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}

/// Zone probable d'une position approximative, en mètres ; `null` pour une
/// adresse précise.
double? _toleranceMeters(String? precision) => switch (precision) {
      'housenumber' => null,
      'street' => 150,
      'locality' => 500,
      'municipality' => 2000,
      _ => 500,
    };

int _zoomFor(String? precision) => switch (precision) {
      'housenumber' => 17,
      'street' => 16,
      'locality' => 15,
      'municipality' => 13,
      _ => 15,
    };

List<({GeoPoint at, Widget child, Offset anchor})> _markers(
    {required GeoPoint proposed,
    required String? precision,
    required int zoom,
    required double maxRadius,
    GeoPoint? chosen}) {
  final double? tolerance = _toleranceMeters(precision);
  final double radius = tolerance == null
      ? 0
      : (tolerance / IgnTiles.metersPerPixel(proposed.lat, zoom))
          .clamp(12.0, maxRadius);
  return [
    if (tolerance != null)
      (
        at: proposed,
        anchor: Offset(radius, radius),
        child: Container(
          key: const ValueKey('mini-map-tolerance'),
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kOrange.withValues(alpha: 0.18),
            border: Border.all(color: kOrange.withValues(alpha: 0.8), width: 2),
          ),
        ),
      ),
    (
      at: proposed,
      anchor: MapPin.anchor(chosen == null ? 36 : 28),
      child: MapPin(
          key: const ValueKey('mini-map-marker'),
          color: chosen == null ? kRed : kRed.withValues(alpha: 0.7),
          size: chosen == null ? 36 : 28),
    ),
    if (chosen != null)
      (
        at: chosen,
        anchor: MapPin.anchor(40),
        child: const MapPin(
            key: ValueKey('map-chosen-marker'), color: kNavy600, size: 40),
      ),
  ];
}

/// Mini-carte statique de la position proposée (repère au centre, cercle de
/// tolérance si elle est approximative). Un clic ouvre la grande carte.
class EnrichmentMiniMap extends StatelessWidget {
  final double lat, lng;

  /// Précision du géocodage (`housenumber`, `street`, `locality`,
  /// `municipality`) : règle le zoom et le cercle.
  final String? precision;
  final double height;

  /// Position choisie à la main, affichée en plus de la proposition.
  final GeoPoint? chosen;
  final VoidCallback? onOpen;

  /// La grande carte permet de poser un point (libellé de l'invite).
  final bool canPlace;

  const EnrichmentMiniMap(
      {super.key,
      required this.lat,
      required this.lng,
      this.precision,
      this.height = 200,
      this.chosen,
      this.onOpen,
      this.canPlace = false});

  /// Coordonnées affichables (Web Mercator).
  static bool displayable(dynamic lat, dynamic lng) =>
      lat is num &&
      lng is num &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 85 &&
      lng.abs() <= 180;

  @override
  Widget build(BuildContext context) {
    final GeoPoint proposed = (lat: lat, lng: lng);
    final int zoom = _zoomFor(precision);
    final double? tolerance = _toleranceMeters(precision);
    final String? hint = onOpen == null
        ? null
        : canPlace
            ? 'Cliquer pour agrandir et ajuster le point'
            : 'Cliquer pour agrandir';
    Widget map = Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderStrong),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: _TileLayer(
            zoom: zoom,
            center: IgnTiles.project(chosen ?? proposed, zoom),
            overlays: _markers(
                proposed: proposed,
                precision: precision,
                zoom: zoom,
                maxRadius: height * 0.45,
                chosen: chosen),
          ),
        ),
        if (hint != null)
          Positioned(left: 8, top: 8, right: 52, child: _MapHint(hint)),
        // Contrôles regroupés en haut à droite : agrandir (et ajuster).
        if (hint != null)
          Positioned(
            right: 8,
            top: 8,
            child: _ControlGroup(buttonSize: 30, children: [
              _ControlButton(
                  tooltip: hint,
                  icon: Icons.open_in_full_rounded,
                  size: 30,
                  onPressed: onOpen!),
            ]),
          ),
        // Légende en pastille, en bas à gauche.
        Positioned(
          left: 8,
          bottom: 8,
          child: _LegendPill(entries: [
            (
              chosen == null ? kRed : kRed.withValues(alpha: 0.7),
              tolerance == null
                  ? 'Proposée'
                  : 'Proposée · ± ${tolerance.round()} m'
            ),
            if (chosen != null) (kNavy600, 'Choisie'),
          ]),
        ),
      ]),
    );
    if (onOpen != null) {
      map = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
            key: const ValueKey('mini-map'), onTap: onOpen, child: map),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        map,
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            if (tolerance != null)
              Text(
                  'Cercle : zone probable (environ ${tolerance.round()} m), pas l’emplacement exact.',
                  style: const TextStyle(fontSize: 12, color: kText3)),
            EnrichmentSourceLink(IgnTiles.geoportail(chosen ?? proposed)),
          ],
        ),
      ],
    );
  }
}

/// Invite « Cliquer pour agrandir… », en pastille blanche.
class _MapHint extends StatelessWidget {
  final String text;
  const _MapHint(this.text);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            boxShadow: _mapShadow,
          ),
          child: Text(text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: kNavy800, fontWeight: FontWeight.w600)),
        ),
      );
}

/// Légende de la carte en pastille : un point coloré par repère.
class _LegendPill extends StatelessWidget {
  final List<(Color, String)> entries;
  const _LegendPill({required this.entries});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: entries[i].$1, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(entries[i].$2,
                  style: const TextStyle(fontSize: 10, color: kText2)),
            ],
          ]),
        ),
      );
}

/// Groupe vertical de contrôles (fond blanc, coins arrondis, séparateurs).
class _ControlGroup extends StatelessWidget {
  final List<Widget> children;
  final double buttonSize;
  const _ControlGroup({required this.children, required this.buttonSize});

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(buttonSize > 32 ? 10 : 8),
          boxShadow: _mapShadow,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              SizedBox(
                  width: buttonSize,
                  child: const Divider(height: 1, color: kNavy100)),
            children[i],
          ],
        ]),
      );
}

/// Bouton carré d'un [_ControlGroup].
class _ControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  const _ControlButton(
      {super.key,
      required this.tooltip,
      required this.icon,
      required this.size,
      required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: size > 32 ? 20 : 16,
          style: IconButton.styleFrom(
            foregroundColor: kNavy600,
            minimumSize: Size.square(size),
            shape: const RoundedRectangleBorder(),
          ),
          icon: Icon(icon),
        ),
      );
}

/// Résultat de la grande carte : [point] choisi, ou `null` pour revenir à la
/// position proposée.
class MapPick {
  final GeoPoint? point;
  const MapPick(this.point);
}

/// Grande carte navigable : glisser pour se déplacer, molette ou +/− pour
/// zoomer. Avec [editable], un clic pose le point à enregistrer.
///
/// Retourne un [MapPick] quand l'utilisateur valide, `null` s'il annule.
class EnrichmentMapDialog extends StatefulWidget {
  final GeoPoint proposed;
  final String? precision;
  final GeoPoint? chosen;
  final bool editable;

  const EnrichmentMapDialog(
      {super.key,
      required this.proposed,
      this.precision,
      this.chosen,
      this.editable = true});

  @override
  State<EnrichmentMapDialog> createState() => _EnrichmentMapDialogState();
}

class _EnrichmentMapDialogState extends State<EnrichmentMapDialog> {
  late int _zoom = math.max(_zoomFor(widget.precision), 17);
  late GeoPoint? _chosen = widget.chosen;
  late Offset _center =
      IgnTiles.project(widget.chosen ?? widget.proposed, _zoom);
  Size _size = Size.zero;

  /// Zoom d'un cran autour de [focus] (position locale), au centre sinon.
  void _zoomBy(int delta, [Offset? focus]) {
    final int next = (_zoom + delta).clamp(IgnTiles.minZoom, IgnTiles.maxZoom);
    if (next == _zoom) return;
    final Offset fromCenter =
        (focus ?? _size.center(Offset.zero)) - _size.center(Offset.zero);
    final double factor = math.pow(2, next - _zoom).toDouble();
    setState(() {
      _center = (_center + fromCenter) * factor - fromCenter;
      _zoom = next;
    });
  }

  void _recenter() => setState(
      () => _center = IgnTiles.project(_chosen ?? widget.proposed, _zoom));

  void _place(Offset local) {
    if (!widget.editable) return;
    final Offset world = _center + local - _size.center(Offset.zero);
    setState(() => _chosen = IgnTiles.unproject(world, _zoom));
  }

  @override
  Widget build(BuildContext context) {
    final double height =
        (MediaQuery.sizeOf(context).height * 0.6).clamp(260.0, 620.0);
    final GeoPoint? chosen = _chosen;
    return EnrichmentDialog(
      maxWidth: 1000,
      scrollable: false,
      onClose: () => Navigator.pop(context),
      title:
          Text(widget.editable ? 'Ajuster la position' : 'Position proposée'),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                widget.editable
                    ? 'Glissez pour vous déplacer, molette ou +/− pour zoomer. '
                        'Cliquez sur la carte pour poser le point à l’emplacement exact du commerce.'
                    : 'Glissez pour vous déplacer, molette ou +/− pour zoomer.',
                style: const TextStyle(fontSize: 13, color: kText2)),
            const SizedBox(height: 8),
            Wrap(spacing: 16, runSpacing: 4, children: [
              _Legend(
                  color: chosen == null ? kRed : kRed.withValues(alpha: 0.7),
                  text: 'Proposée'),
              if (chosen != null)
                const _Legend(color: kNavy600, text: 'Choisie'),
            ]),
            const SizedBox(height: 10),
            Container(
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kBorderStrong),
              ),
              child: LayoutBuilder(builder: (context, size) {
                _size = size.biggest;
                return Stack(children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is! PointerScrollEvent) return;
                        // La molette zoome la carte au lieu de faire défiler.
                        GestureBinding.instance.pointerSignalResolver.register(
                            event,
                            (e) => _zoomBy(
                                (e as PointerScrollEvent).scrollDelta.dy < 0
                                    ? 1
                                    : -1,
                                e.localPosition));
                      },
                      child: MouseRegion(
                        cursor: widget.editable
                            ? SystemMouseCursors.precise
                            : SystemMouseCursors.grab,
                        child: GestureDetector(
                          key: const ValueKey('map-surface'),
                          onTapUp: (d) => _place(d.localPosition),
                          onPanUpdate: (d) =>
                              setState(() => _center -= d.delta),
                          child: _TileLayer(
                            zoom: _zoom,
                            center: _center,
                            attributionInset: 12,
                            overlays: _markers(
                                proposed: widget.proposed,
                                precision: widget.precision,
                                zoom: _zoom,
                                maxRadius: height,
                                chosen: chosen),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _MapControls(
                      onZoomIn: () => _zoomBy(1),
                      onZoomOut: () => _zoomBy(-1),
                      onRecenter: _recenter,
                    ),
                  ),
                  // Coordonnées du point posé, en pastille.
                  if (chosen != null)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      right: 150,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: IgnorePointer(
                          child: Container(
                            key: const ValueKey('map-chosen-text'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _mapShadow,
                            ),
                            child: Text('Choisie : ${IgnTiles.format(chosen)}',
                                style: ArcText.dataSmall(color: kInk)
                                    .copyWith(fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                ]);
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        if (widget.editable && chosen != null)
          OutlinedButton(
              onPressed: () => Navigator.pop(context, const MapPick(null)),
              child: const Text('Garder la position proposée')),
        if (widget.editable)
          FilledButton(
              onPressed: chosen == null
                  ? null
                  : () => Navigator.pop(context, MapPick(chosen)),
              child: const Text('Utiliser ce point')),
      ],
    );
  }
}

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn, onZoomOut, onRecenter;
  const _MapControls(
      {required this.onZoomIn,
      required this.onZoomOut,
      required this.onRecenter});

  @override
  Widget build(BuildContext context) {
    // Icônes déjà présentes ailleurs dans l'application : elles figurent dans
    // la police d'icônes en cache des navigateurs.
    return _ControlGroup(buttonSize: 40, children: [
      _ControlButton(
          key: const ValueKey('map-zoom-in'),
          tooltip: 'Zoomer',
          icon: Icons.add,
          size: 40,
          onPressed: onZoomIn),
      _ControlButton(
          key: const ValueKey('map-zoom-out'),
          tooltip: 'Dézoomer',
          icon: Icons.remove,
          size: 40,
          onPressed: onZoomOut),
      _ControlButton(
          key: const ValueKey('map-recenter'),
          tooltip: 'Recentrer sur la position',
          icon: Icons.my_location,
          size: 40,
          onPressed: onRecenter),
    ]);
  }
}

/// Point coloré et libellé de la légende de la grande carte.
class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: kText2))),
        ],
      );
}
