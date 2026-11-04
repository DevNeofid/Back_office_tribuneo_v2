import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../utils/common.dart';
import 'enrichment_dialog.dart';

/// Point géographique.
typedef GeoPoint = ({double lat, double lng});

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
  const _TileLayer(
      {required this.zoom, required this.center, this.overlays = const []});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
        const double t = IgnTiles.tileSize;
        final double width = size.maxWidth, height = size.maxHeight;
        final double left = center.dx - width / 2, top = center.dy - height / 2;
        final int maxIndex = math.pow(2, zoom).toInt() - 1;
        final int x0 = (left / t).floor(), x1 = ((left + width) / t).floor();
        final int y0 = (top / t).floor(), y1 = ((top + height) / t).floor();
        return Stack(clipBehavior: Clip.hardEdge, children: [
          const Positioned.fill(child: ColoredBox(color: kLGrey)),
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
                        const ColoredBox(color: kLGrey),
                  ),
                ),
          for (final o in overlays)
            Positioned(
                left: IgnTiles.project(o.at, zoom).dx - left - o.anchor.dx,
                top: IgnTiles.project(o.at, zoom).dy - top - o.anchor.dy,
                child: IgnorePointer(child: o.child)),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: const Text('© IGN – Plan IGN',
                  style: TextStyle(fontSize: 10, color: kGrey)),
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
          color: chosen == null ? kRed : kBlue.withValues(alpha: 0.7),
          size: chosen == null ? 36 : 28),
    ),
    if (chosen != null)
      (
        at: chosen,
        anchor: MapPin.anchor(40),
        child: const MapPin(
            key: ValueKey('map-chosen-marker'), color: kRed, size: 40),
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
    Widget map = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        decoration: BoxDecoration(border: Border.all(color: kLBlue)),
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
          if (onOpen != null)
            Positioned(
              left: 8,
              top: 8,
              child: _MapHint(canPlace
                  ? 'Cliquer pour agrandir et ajuster le point'
                  : 'Cliquer pour agrandir'),
            ),
        ]),
      ),
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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            if (tolerance != null)
              Text(
                  'Cercle : zone probable (environ ${tolerance.round()} m), pas l’emplacement exact.',
                  style: const TextStyle(fontSize: 12, color: kGrey)),
            EnrichmentSourceLink(IgnTiles.geoportail(chosen ?? proposed)),
          ],
        ),
      ],
    );
  }
}

class _MapHint extends StatelessWidget {
  final String text;
  const _MapHint(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: kBlueEnd, fontWeight: FontWeight.w600)),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              widget.editable
                  ? 'Glissez pour vous déplacer, molette ou +/− pour zoomer. '
                      'Cliquez sur la carte pour poser le point à l’emplacement exact du commerce.'
                  : 'Glissez pour vous déplacer, molette ou +/− pour zoomer.',
              style: const TextStyle(fontSize: 13, color: kGrey)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
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
                    right: 10,
                    top: 10,
                    child: _MapControls(
                      onZoomIn: () => _zoomBy(1),
                      onZoomOut: () => _zoomBy(-1),
                      onRecenter: _recenter,
                    ),
                  ),
                ]);
              }),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 4, children: [
            _Legend(color: chosen == null ? kRed : kBlue, text: 'Proposée'),
            if (chosen != null)
              _Legend(
                  color: kRed,
                  text: 'Choisie : ${IgnTiles.format(chosen)}',
                  key: const ValueKey('map-chosen-text')),
          ]),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        if (widget.editable && chosen != null)
          TextButton(
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
    Widget button(String tooltip, IconData icon, VoidCallback onPressed,
            {Key? key}) =>
        IconButton(
            key: key,
            tooltip: tooltip,
            onPressed: onPressed,
            color: kBlueEnd,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            icon: Icon(icon));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        button('Zoomer', Icons.add, onZoomIn,
            key: const ValueKey('map-zoom-in')),
        const SizedBox(width: 32, child: Divider(height: 1)),
        button('Dézoomer', Icons.remove, onZoomOut,
            key: const ValueKey('map-zoom-out')),
        const SizedBox(width: 32, child: Divider(height: 1)),
        button('Recentrer sur la position', Icons.my_location, onRecenter,
            key: const ValueKey('map-recenter')),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MapPin(color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: kBlueEnd))),
        ],
      );
}
