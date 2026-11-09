import 'dart:convert';

import 'package:back_office_tribuneo_v2/domain/errors/order_error_messages.dart';
import 'package:back_office_tribuneo_v2/domain/models/entity_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_beneficiaries_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_model.dart';
import 'package:back_office_tribuneo_v2/domain/models/order_restriction_model.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/arc/arc.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/merchant_picker.dart';
import 'package:back_office_tribuneo_v2/presentation/widgets/orders/order_restriction_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// Commandes restreintes à une liste de commerçants (spec BO du 28/10/2026).

List<RestrictionMerchant> _merchants() => [
      RestrictionMerchant(
          id: 1, name: 'Boulangerie du Centre', city: 'Châtillon-sur-Seine'),
      RestrictionMerchant(id: 2, name: 'Épicerie Fine', city: 'Montbard'),
      RestrictionMerchant(
          id: 3, name: 'Arts et Fleurs', city: 'CHATILLON-SUR-SEINE'),
      RestrictionMerchant(
          id: 4,
          name: 'Cave Martin',
          city: 'Châtillon-sur-Seine',
          connected: false),
    ];

Future<void> _pumpPicker(
    WidgetTester tester, RestrictionDraft draft, List<RestrictionMerchant> merchants) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ArcTheme.light(),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('fr', 'FR')],
    home: Scaffold(
      body: SingleChildScrollView(
        child: MerchantPicker(
            merchants: merchants, draft: draft, listHeight: 500),
      ),
    ),
  ));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('modèles', () {
    test('OrderModel : restriction lue, ou null si absente', () {
      final OrderModel restricted = OrderModel.fromJson({
        'id': 7,
        'restriction': {'id': 4, 'label': 'Noël 2026', 'nb_commercants': 12},
      });
      expect(restricted.restriction?.id, 4);
      expect(restricted.restriction?.label, 'Noël 2026');
      expect(restricted.restriction?.nbCommercants, 12);
      expect(OrderModel.fromJson({'id': 7}).restriction, isNull);
      expect(OrderModel.fromJson({'id': 7, 'restriction': null}).restriction,
          isNull);
    });

    test('OrderSendModel : restriction envoyée seulement si choisie', () {
      final OrderSendModel everywhere = OrderSendModel(giftFrom: 'CSE');
      expect(everywhere.toJson().containsKey('restriction'), isFalse);

      final OrderSendModel restricted = OrderSendModel(
        giftFrom: 'CSE',
        restriction: const OrderRestrictionInput(
            label: 'Noël 2026', entityIds: [231, 245]),
      );
      expect(jsonDecode(jsonEncode(restricted.toJson()))['restriction'], {
        'label': 'Noël 2026',
        'entity_ids': [231, 245],
      });
    });

    test('OrderRestrictionModel.fromData : liste ou null', () {
      final OrderRestrictionModel? restriction =
          OrderRestrictionModel.fromData({
        'restriction': {
          'id': 4,
          'label': 'Noël 2026',
          'entity_ids': [231, '245', 260],
          'nb_commercants': 3,
          'active': false,
          'updated_date': '2026-12-20 10:12:00',
        }
      });
      expect(restriction!.entityIds, [231, 245, 260]);
      expect(restriction.active, isFalse);
      expect(restriction.summary.nbCommercants, 3);
      expect(OrderRestrictionModel.fromData({'restriction': null}), isNull);
      expect(OrderRestrictionModel.fromData({}), isNull);
    });
  });

  group('messages', () {
    test('codes de la section 6', () {
      expect(OrderErrorMessages.forCode('RESTRICTION_LABEL_REQUIRED', {}),
          'Donnez un nom à la liste.');
      expect(OrderErrorMessages.forCode('RESTRICTION_LABEL_TOO_LONG', {}),
          'Le nom de la liste ne doit pas dépasser 60 caractères.');
      expect(OrderErrorMessages.forCode('RESTRICTION_EMPTY', {}),
          'Sélectionnez au moins un commerçant.');
      expect(OrderErrorMessages.forCode('RESTRICTION_UNKNOWN_ENTITIES', {}),
          startsWith('Certains commerçants ne font plus partie du réseau.'));
      expect(OrderErrorMessages.restrictionOrderNotFound,
          "Cette commande n'existe plus.");
      expect(
          OrderErrorMessages.unknownEntityIds({
            'entity_ids': [3, '9', null]
          }),
          [3, 9]);
    });

    test('badge, infobulle et lien du site', () {
      const OrderRestrictionSummary summary = OrderRestrictionSummary(
          id: 4, label: 'Noël 2026', nbCommercants: 12);
      expect(restrictionBadgeLabel(summary),
          'Restreinte : Noël 2026 · 12 commerçants');
      expect(restrictionTooltip(summary),
          'Restreinte : Noël 2026 (12 commerçants)');
      expect(
          restrictionBadgeLabel(const OrderRestrictionSummary(
              label: 'Test', nbCommercants: 1)),
          'Restreinte : Test · 1 commerçant');
      expect(restrictionSiteUrl('2', 4),
          'https://tribuneo.com/partenaires.html?reseau=2&liste=4');
    });

    test('chèques déjà utilisés', () {
      OrderBeneficiariesModel status(List<OrderBeneficiaryModel> list) =>
          OrderBeneficiariesModel(beneficiaries: list);
      expect(
          orderHasUsedVouchers(status([
            OrderBeneficiaryModel(amount: 50, remainingAmount: 50),
            OrderBeneficiaryModel(
                amount: 50, remainingAmount: 50, assigned: true),
          ])),
          isFalse);
      expect(
          orderHasUsedVouchers(status([
            OrderBeneficiaryModel(
                amount: 50, remainingAmount: 20, assigned: true),
          ])),
          isTrue);
      expect(orderHasUsedVouchers(null), isTrue);
    });
  });

  group('saisie', () {
    test('validation avant envoi', () {
      final RestrictionDraft draft = RestrictionDraft();
      expect(draft.validate(), 'Donnez un nom à la liste.');
      draft.labelController.text = 'x' * 61;
      expect(draft.validate(),
          'Le nom de la liste ne doit pas dépasser 60 caractères.');
      draft.labelController.text = '  Noël 2026 ';
      expect(draft.validate(), 'Sélectionnez au moins un commerçant.');
      draft.setSelected(9, true);
      draft.setSelected(3, true);
      expect(draft.validate(), isNull);
      final OrderRestrictionInput input = draft.toInput();
      expect(input.label, 'Noël 2026');
      expect(input.entityIds, [3, 9]);
      draft.dispose();
    });

    test('partenaires : tri par nom (accents ignorés), sans doublon', () {
      EntityModel partner(int id, String name, {bool demat = true}) =>
          EntityModel.fromJson({
            'id': id,
            'name': name,
            'accept_demat': demat,
            'address': {'city': 'Montbard'},
            'activity_sectors': [
              {'id': 1, 'name': 'Alimentation'}
            ],
          });
      final List<RestrictionMerchant> merchants = RestrictionMerchant.sortedFrom([
        partner(1, 'Fromagerie'),
        partner(2, 'Épicerie', demat: false),
        partner(3, 'Boucherie'),
        partner(1, 'Fromagerie'),
      ]);
      expect(merchants.map((m) => m.name),
          ['Boucherie', 'Épicerie', 'Fromagerie']);
      expect(merchants[1].connected, isFalse);
      expect(merchants[0].subtitle, 'Montbard · Alimentation');
    });
  });

  group('sélecteur', () {
    testWidgets(
        'non connectés masqués par défaut, affichés avec badge sur demande',
        (tester) async {
      final RestrictionDraft draft = RestrictionDraft();
      addTearDown(draft.dispose);
      await _pumpPicker(tester, draft, _merchants());

      expect(find.text('Cave Martin'), findsNothing);
      expect(find.text('0 sélectionné · 3 affichés'), findsOneWidget);

      await tester.tap(find.text(
          'Afficher aussi les commerçants pas encore connectés à Tribuneo'));
      await tester.pump();
      expect(find.text('Cave Martin'), findsOneWidget);
      expect(find.text('Pas encore connecté'), findsOneWidget);
      expect(find.text('0 sélectionné · 4 affichés'), findsOneWidget);
    });

    testWidgets('« Tout cocher » n\'agit que sur les commerçants affichés',
        (tester) async {
      final RestrictionDraft draft = RestrictionDraft();
      addTearDown(draft.dispose);
      await _pumpPicker(tester, draft, _merchants());

      await tester.enterText(find.byType(TextField), 'chatillon');
      await tester.pump();
      expect(find.text('Épicerie Fine'), findsNothing);
      expect(find.text('0 sélectionné · 2 affichés'), findsOneWidget);

      await tester.tap(find.text('Tout cocher'));
      await tester.pump();
      // Cave Martin (non connecté, masqué) n'est pas coché.
      expect(draft.selected, {1, 3});

      // La sélection est conservée quand la recherche masque les commerçants.
      await tester.enterText(find.byType(TextField), 'montbard');
      await tester.pump();
      expect(find.text('2 sélectionnés · 1 affiché'), findsOneWidget);
      expect(draft.selected, {1, 3});

      await tester.tap(find.text('Tout décocher'));
      await tester.pump();
      expect(draft.selected, {1, 3});

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.text('Tout décocher'));
      await tester.pump();
      expect(draft.selected, isEmpty);
    });

    testWidgets('cocher une ligne', (tester) async {
      final RestrictionDraft draft = RestrictionDraft(entityIds: [2]);
      addTearDown(draft.dispose);
      await _pumpPicker(tester, draft, _merchants());
      expect(find.text('1 sélectionné · 3 affichés'), findsOneWidget);

      await tester.tap(find.text('Arts et Fleurs'));
      await tester.pump();
      expect(draft.selected, {2, 3});
    });

    testWidgets('fiche d\'une commande sans liste : valable partout',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ArcTheme.light(),
        home: Scaffold(
          body: OrderRestrictionSection(
            order: OrderModel(id: 7),
            orderStatus: null,
            onChanged: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Valable chez tous les commerçants du réseau.'),
          findsOneWidget);
      expect(find.text('Restreindre à certains commerçants'), findsOneWidget);
      expect(find.text('Modifier la liste'), findsNothing);
    });

    testWidgets('600 commerçants : seules les lignes visibles sont construites',
        (tester) async {
      final RestrictionDraft draft = RestrictionDraft();
      addTearDown(draft.dispose);
      await _pumpPicker(
          tester,
          draft,
          List.generate(
              600,
              (i) => RestrictionMerchant(
                  id: i, name: 'Commerce ${i.toString().padLeft(3, '0')}')));
      expect(find.text('0 sélectionné · 600 affichés'), findsOneWidget);
      expect(find.byType(Checkbox).evaluate().length, lessThan(30));

      await tester.tap(find.text('Tout cocher'));
      await tester.pump();
      expect(draft.selectedCount, 600);
    });
  });
}
