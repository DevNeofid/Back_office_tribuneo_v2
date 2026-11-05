import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:back_office_tribuneo_v2/presentation/utils/arc_theme.dart';
import 'package:back_office_tribuneo_v2/presentation/utils/common.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc_logo.dart';

/// Entrée du menu latéral.
class ArcNavItem {
  final String name;
  final String label;
  final IconData icon;

  /// Pastille orange (ex. « 1 » sur Prochain virement), `null` sans pastille.
  final String? badge;
  const ArcNavItem(
      {required this.name, required this.label, required this.icon, this.badge});
}

/// Groupe d'entrées ; [title] `null` pour un groupe sans libellé.
class ArcNavGroup {
  final String? title;
  final List<ArcNavItem> items;
  const ArcNavGroup(this.title, this.items);
}

/// Menu latéral navy du design system « Arc ».
class ArcSidebar extends StatelessWidget {
  final List<ArcNavGroup> groups;
  final String selected;
  final ValueChanged<String> onSelect;
  final String userName;
  final VoidCallback onSignOut;
  const ArcSidebar({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelect,
    required this.userName,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kNavy900,
      child: SafeArea(
        child: SizedBox(
          width: kSidebarWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ArcWordmark(height: 26),
                    const SizedBox(height: 10),
                    Text('BACKOFFICE',
                        style: ArcText.dataSmall(color: kNavy400)
                            .copyWith(fontSize: 10, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final group in groups) ...[
                      if (group.title != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                          child: Text(group.title!,
                              style: ArcText.label(color: kNavy400)
                                  .copyWith(fontSize: 11, letterSpacing: 0.9)),
                        ),
                      for (final item in group.items)
                        _NavTile(
                          item: item,
                          selected: item.name == selected,
                          onTap: () => onSelect(item.name),
                        ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: _UserCard(name: userName, onSignOut: onSignOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final ArcNavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile(
      {required this.item, required this.selected, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool on = widget.selected;
    final Color bg = on
        ? kNavy700
        : (_hover ? const Color(0x1AFFFFFF) : Colors.transparent);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: on,
        button: true,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(kRadiusSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusSm),
            onTap: widget.onTap,
            onHover: (h) => setState(() => _hover = h),
            child: SizedBox(
              height: 42,
              child: Row(children: [
                const SizedBox(width: 12),
                Icon(widget.item.icon,
                    size: 20, color: on ? kOrange : kNavy400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: on || _hover ? Colors.white : kNavy300)),
                ),
                if (widget.item.badge != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: kOrange, borderRadius: BorderRadius.circular(999)),
                    child: Text(widget.item.badge!,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kNavy900)),
                  ),
                const SizedBox(width: 12),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte du compte connecté : un clic n'importe où sur la carte déconnecte.
class _UserCard extends StatefulWidget {
  final String name;
  final VoidCallback onSignOut;
  const _UserCard({required this.name, required this.onSignOut});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final String name = widget.name;
    final String initials =
        name.isEmpty ? '?' : name.substring(0, name.length < 2 ? 1 : 2).toUpperCase();
    final BorderRadius radius = BorderRadius.circular(14);
    return Tooltip(
      message: 'Se déconnecter',
      child: Semantics(
        button: true,
        label: 'Se déconnecter ($name)',
        excludeSemantics: true,
        child: Material(
          color: _hover ? kNavy700 : kNavy800,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onSignOut,
            onHover: (h) => setState(() => _hover = h),
            child: _content(name, initials),
          ),
        ),
      ),
    );
  }

  Widget _content(String name, String initials) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration:
              const BoxDecoration(color: kOrange, shape: BoxShape.circle),
          child: Text(initials,
              style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14, fontWeight: FontWeight.w800, color: kNavy900)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
        const SizedBox(width: 8),
        Icon(Icons.logout_rounded,
            size: 18, color: _hover ? Colors.white : kNavy300),
        const SizedBox(width: 9),
      ]),
    );
  }
}
