import 'package:flutter/material.dart';
import 'package:back_office_tribuneo_v2/domain/usecases/partner_usecase.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/_global.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/domain/models/sector_model.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';

class SectorActivityView extends StatefulWidget {
  const SectorActivityView({Key? key}) : super(key: key);
  @override
  SectorActivityViewState createState() => SectorActivityViewState();
}

class SectorActivityViewState extends State<SectorActivityView> {
  final _formKey = GlobalKey<FormState>();
  final PartnerUseCase _partnerUseCase = PartnerUseCase();
  final TextEditingController _newSectorController = TextEditingController();
  late List<Sector> _sectors = [];
  bool _isLoading = false;

  /// Premier chargement de la liste (affichage seulement).
  bool _loadingList = true;
  bool _loadFailed = false;

  @override
  void initState() {
    refreshSector();
    super.initState();
  }

  @override
  void dispose() {
    _newSectorController.dispose();
    super.dispose();
  }

  Future<void> refreshSector() async {
    try {
      dynamic data = await _partnerUseCase.getSectors();
      if (!mounted) return;
      setState(() {
        _sectors = data;
        _loadingList = false;
        _loadFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _addNewSector() async {
    String newSectorName = _newSectorController.text.trim();
    if (newSectorName.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await _partnerUseCase.addNewSector(newSectorName);
        await refreshSector();
        _newSectorController.clear();

        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Le secteur d’activité a été ajouté"),
        ));
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text("Erreur lors de l’ajout du secteur d’activité"),
          backgroundColor: kDangerText,
        ));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSector(Sector sector) async {
    if (await _showComfirmDialog(sector)) {
      try {
        await _partnerUseCase.deleteSector(sector.id!);
        await refreshSector();
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Le secteur d’activité a été supprimé avec succès'),
        ));
      } catch (e) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression du secteur d’activité'),
          backgroundColor: kDangerText,
        ));
      }
    }
  }

  Future<bool> _showComfirmDialog(Sector sector) {
    final String name = sector.name ?? '';
    return showArcConfirm(
      navigatorKey.currentState?.context ?? context,
      title: name.isEmpty ? 'Supprimer ce secteur ?' : 'Supprimer « $name » ?',
      message: "Attention, il est possible que ce secteur d'activité soit "
          'associé à des partenaires. Voulez-vous vraiment le supprimer ?',
      confirmLabel: 'Supprimer',
      danger: true,
    );
  }

  /// Clé de tri alphabétique insensible à la casse et aux accents.
  static String _sortKey(String value) {
    const Map<String, String> accents = {
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'á': 'a',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'í': 'i',
      'ô': 'o',
      'ö': 'o',
      'ó': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ú': 'u',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };
    return value
        .toLowerCase()
        .split('')
        .map((char) => accents[char] ?? char)
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final List<Sector> sorted = [
      ..._sectors
    ]..sort((a, b) => _sortKey(a.name ?? '').compareTo(_sortKey(b.name ?? '')));

    return Form(
      key: _formKey,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ArcPageHeader(
                  eyebrow: 'Réseau', title: "Secteurs d'activité"),
              _buildAddForm(),
              const SizedBox(height: 16),
              _buildList(sorted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    final Widget field = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Nouveau secteur d'activité",
            style: ArcText.body(color: kNavy700)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: _newSectorController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isLoading) _addNewSector();
          },
          decoration: const InputDecoration(hintText: 'Ex. Fromagerie'),
        ),
      ],
    );
    final Widget button = FilledButton.icon(
      onPressed: _isLoading ? null : _addNewSector,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: kNavy600))
          : const Icon(Icons.add_rounded, size: 18),
      label: const Text('Ajouter'),
    );
    return ArcCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field, const SizedBox(height: 12), button],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [Expanded(child: field), const SizedBox(width: 12), button],
        );
      }),
    );
  }

  Widget _buildList(List<Sector> sectors) {
    final Widget body;
    if (_loadingList) {
      body = const SizedBox(
          height: 160, child: Center(child: CircularProgressIndicator()));
    } else if (_loadFailed) {
      body = Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text("Impossible de charger les secteurs d'activité.",
                style: ArcText.small(color: kDangerText)),
            TextButton.icon(
              onPressed: () {
                setState(() => _loadingList = true);
                refreshSector();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else if (sectors.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(20),
        child: ArcEmptyState(
          icon: Icons.sell_outlined,
          title: "Aucun secteur d'activité",
          message: 'Ajoutez le premier secteur avec le champ ci-dessus.',
        ),
      );
    } else {
      body = LayoutBuilder(builder: (context, constraints) {
        final int columns = constraints.maxWidth < 560 ? 1 : 2;
        final int rows = (sectors.length / columns).ceil();
        return Column(
          children: [
            for (int r = 0; r < rows; r++)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int c = 0; c < columns; c++)
                      Expanded(
                        child: r * columns + c < sectors.length
                            ? _SectorTile(
                                sector: sectors[r * columns + c],
                                lastColumn: c == columns - 1,
                                onDelete: () =>
                                    _deleteSector(sectors[r * columns + c]),
                              )
                            : _SectorTile.filler(lastColumn: c == columns - 1),
                      ),
                  ],
                ),
              ),
          ],
        );
      });
    }

    return ArcTableCard(
      toolbar: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Secteurs', style: ArcText.cardTitle().copyWith(fontSize: 16)),
            if (!_loadingList && !_loadFailed) ...[
              const SizedBox(width: 10),
              ArcCount('${sectors.length}'),
            ],
          ]),
          Text('Ordre alphabétique', style: ArcText.small(color: kText3)),
        ],
      ),
      child: body,
    );
  }
}

/// Case de la grille des secteurs : nom et bouton de suppression.
class _SectorTile extends StatelessWidget {
  final Sector? sector;
  final bool lastColumn;
  final VoidCallback? onDelete;
  const _SectorTile(
      {required Sector this.sector, required this.lastColumn, this.onDelete});
  const _SectorTile.filler({required this.lastColumn})
      : sector = null,
        onDelete = null;

  @override
  Widget build(BuildContext context) {
    final String name = sector?.name ?? '';
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: kNavy100),
          right:
              lastColumn ? BorderSide.none : const BorderSide(color: kNavy100),
        ),
      ),
      child: sector == null
          ? null
          : Row(children: [
              Expanded(
                child: SelectableText(name,
                    style: ArcText.body(color: kNavy900)
                        .copyWith(fontWeight: FontWeight.w500)),
              ),
              IconButton(
                tooltip: 'Supprimer $name',
                onPressed: onDelete,
                color: kDangerText,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ]),
    );
  }
}
