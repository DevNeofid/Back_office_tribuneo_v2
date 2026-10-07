import 'package:back_office_tribuneo_v2/domain/models/bank_account_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _account(String code, String label,
        {bool isDefault = false,
        bool isRefund = false,
        String? iban = 'FR7616807001430431903016646',
        String? accountingNumber = '5120010'}) =>
    {
      'code': code,
      'label': label,
      'holder': 'CCI',
      'iban': iban,
      'bic': 'CCBPFRPPGRE',
      'accounting_number': accountingNumber,
      'journal': 'BP',
      'is_default': isDefault,
      'is_refund': isRefund,
    };

void main() {
  // Réseau à deux comptes avec consigne sur les remboursements (KDO4).
  final BankAccountsModel kdo4 = BankAccountsModel.fromJson({
    'accounts': [
      _account('main', 'Compte principal', isDefault: true),
      _account('second', 'Compte chèques cadeaux', isRefund: true),
    ],
    'payment_locked': false,
    'refund_locked': true,
  });

  // Réseau à un seul compte (VDPC).
  final BankAccountsModel vdpc = BankAccountsModel.fromJson({
    'accounts': [
      _account('main', 'Compte principal',
          isDefault: true, isRefund: true, accountingNumber: null),
    ],
    'payment_locked': false,
    'refund_locked': false,
  });

  group('selects', () {
    test('un seul compte : aucun select', () {
      expect(vdpc.paymentSelectRequired, isFalse);
      expect(vdpc.refundSelectRequired, isFalse);
    });

    test('plusieurs comptes : select si pas de verrou', () {
      expect(kdo4.paymentSelectRequired, isTrue);
      expect(kdo4.refundSelectRequired, isFalse);
    });

    test('plusieurs comptes, verrou paiement', () {
      final accounts = BankAccountsModel.fromJson({
        'accounts': [_account('a', 'A'), _account('b', 'B')],
        'payment_locked': true,
        'refund_locked': false,
      });
      expect(accounts.paymentSelectRequired, isFalse);
      expect(accounts.refundSelectRequired, isTrue);
    });

    test('liste vide : aucun select', () {
      final accounts = BankAccountsModel.fromJson({'accounts': []});
      expect(accounts.paymentSelectRequired, isFalse);
      expect(accounts.refundSelectRequired, isFalse);
    });
  });

  group('labelForCode', () {
    test('code connu : libellé', () {
      expect(kdo4.labelForCode('second'), 'Compte chèques cadeaux');
    });

    test('null (ancien enregistrement) : compte par défaut', () {
      expect(kdo4.labelForCode(null), 'Compte principal');
    });

    test('code supprimé côté Neofid : code brut', () {
      expect(kdo4.labelForCode('old'), 'old');
    });
  });

  test('compte de remboursement', () {
    expect(kdo4.refundAccount?.code, 'second');
  });

  group('selectLabel', () {
    test('libellé — IBAN groupé — compte 512', () {
      expect(kdo4.byCode('main')!.selectLabel,
          'Compte principal — FR76 1680 7001 4304 3190 3016 646 — 5120010');
    });

    test('sans compte 512', () {
      expect(vdpc.accounts.single.selectLabel,
          'Compte principal — FR76 1680 7001 4304 3190 3016 646');
    });

    test('sans IBAN', () {
      final account = BankAccountModel.fromJson(
          _account('x', 'X', iban: null, accountingNumber: null));
      expect(account.selectLabel, 'X');
    });
  });
}
