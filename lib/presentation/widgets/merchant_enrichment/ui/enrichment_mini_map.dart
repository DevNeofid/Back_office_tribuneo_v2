import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../utils/common.dart';
import 'enrichment_dialog.dart';

/// Mini-carte statique d'une position proposée : tuiles « Plan IGN » de la
/// Géoplateforme (service public, sans clé), repère au centre et, pour une
/// position approximative, cercle de tolérance.
///
/// Affichage seul : aucune action, la position n'est jamais déplaçable.
class EnrichmentMiniMap extends StatelessWidget {
  final double lat, lng;

  /// Précision du géocodage (`housenumber`, `street`, `locality`,
  /// `municipality`) : règle le zoom et le cercle.
  final String? precision;
  final double height;

  const EnrichmentMiniMap(
      {super.key,
      required this.lat,
      required this.lng,
      this.precision,
      this.height = 200});

  static const double _tile = 256;

  /// Coordonnées affichables (Web Mercator).
  static bool displayable(dynamic lat, dynamic lng) =>
      lat is num &&
      lng is num &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 85 &&
      lng.abs() <= 180;

  int get _zoom => switch (precision) {
        'housenumber' => 17,
        'street' => 16,
        'locality' => 15,
        'municipality' => 13,
        _ => 15,
      };

  /// Rayon de tolérance en mètres ; `null` pour une adresse précise.
  double? get _toleranceMeters => switch (precision) {
        'housenumber' => null,
        'street' => 150,
        'locality' => 500,
        'municipality' => 2000,
        _ => 500,
      };

  static String tileUrl(int z, int x, int y) =>
      'https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile&VERSION=1.0.0'
      '&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&STYLE=normal&TILEMATRIXSET=PM'
      '&FORMAT=image/png&TILEMATRIX=$z&TILEROW=$y&TILECOL=$x';

  /// Carte complète sur le Géoportail, dans un nouvel onglet.
  String get geoportailUrl =>
      'https://www.geoportail.gouv.fr/carte?c=$lng,$lat&z=18&permalink=yes';

  @override
  Widget build(BuildContext context) {
    final int z = _zoom;
    final double scale = math.pow(2, z).toDouble() * _tile;
    final double latRad = lat * math.pi / 180;
    // Position du point en pixels du monde à ce zoom.
    final double px = (lng + 180) / 360 * scale;
    final double py =
        (1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2 *
            scale;
    final double metersPerPixel =
        156543.03392 * math.cos(latRad) / math.pow(2, z);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            decoration:
                BoxDecoration(color: kLGrey, border: Border.all(color: kLBlue)),
            child: LayoutBuilder(builder: (context, size) {
              final double width = size.maxWidth;
              final double left = px - width / 2, top = py - height / 2;
              final int maxIndex = math.pow(2, z).toInt() - 1;
              final int x0 = (left / _tile).floor(),
                  x1 = ((left + width) / _tile).floor();
              final int y0 = (top / _tile).floor(),
                  y1 = ((top + height) / _tile).floor();
              final double? tolerance = _toleranceMeters;
              final double radius = tolerance == null
                  ? 0
                  : (tolerance / metersPerPixel).clamp(12.0, height * 0.45);
              return Stack(clipBehavior: Clip.hardEdge, children: [
                for (var tx = x0; tx <= x1; tx++)
                  for (var ty = y0; ty <= y1; ty++)
                    if (tx >= 0 && ty >= 0 && tx <= maxIndex && ty <= maxIndex)
                      Positioned(
                        left: tx * _tile - left,
                        top: ty * _tile - top,
                        width: _tile,
                        height: _tile,
                        child: Image.network(
                          tileUrl(z, tx, ty),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          // Hors ligne ou service indisponible : fond neutre.
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: kLGrey),
                        ),
                      ),
                if (tolerance != null)
                  Positioned(
                    left: width / 2 - radius,
                    top: height / 2 - radius,
                    width: radius * 2,
                    height: radius * 2,
                    child: IgnorePointer(
                      child: Container(
                        key: const ValueKey('mini-map-tolerance'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kOrange.withValues(alpha: 0.18),
                          border: Border.all(
                              color: kOrange.withValues(alpha: 0.8), width: 2),
                        ),
                      ),
                    ),
                  ),
                // Pointe du repère sur la position.
                Positioned(
                  left: width / 2 - 18,
                  top: height / 2 - 36,
                  child: const Icon(Icons.location_on,
                      key: ValueKey('mini-map-marker'),
                      size: 36,
                      color: kRed,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)]),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: const Text('© IGN – Plan IGN',
                        style: TextStyle(fontSize: 10, color: kGrey)),
                  ),
                ),
              ]);
            }),
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            if (_toleranceMeters != null)
              Text(
                  'Cercle : zone probable (environ ${_toleranceMeters!.round()} m), pas l’emplacement exact.',
                  style: const TextStyle(fontSize: 12, color: kGrey)),
            EnrichmentSourceLink(geoportailUrl),
          ],
        ),
      ],
    );
  }
}
