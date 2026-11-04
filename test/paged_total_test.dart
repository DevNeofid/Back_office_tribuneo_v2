import 'package:back_office_tribuneo_v2/presentation/utils/paged_total.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int total(int api, int start, int received, [int limit = 10]) =>
      resolvePagedTotal(
          apiTotal: api, startIndex: start, received: received, limit: limit);

  test('incomplete page is the last one, whatever the API announces', () {
    // VDPC « Toutes les infos partenaires » : 9 lignes, total annoncé 75.
    expect(total(75, 0, 9), 9);
    expect(total(75, 20, 3), 23);
    expect(total(0, 0, 0), 0);
  });

  test('full page: API total, never below what was received', () {
    expect(total(75, 0, 10), 75);
    expect(total(5, 0, 10), 10);
  });

  test('full page without API total: one more row to fetch the next page', () {
    expect(total(0, 0, 10), 11);
    expect(total(0, 30, 10), 41);
  });
}
