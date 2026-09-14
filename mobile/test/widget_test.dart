import 'package:flutter_test/flutter_test.dart';
import 'package:baongocangi/catalog.dart';
import 'package:baongocangi/food_art.dart';

void main() {
  test('price labels and Vietnamese folding', () {
    expect(priceLabel(0), '0đ');
    expect(priceLabel(50), '50.000đ');
    expect(foldVi('Lê Văn Hưu'), 'le van huu');
    expect(priceRarity(35), 0);
    expect(priceRarity(90), 2);
  });

  test('food atlas cells match the web sprites', () {
    final hd = atlasFor(1)!;
    expect(hd.asset, 'assets/images/food-hd-0.webp');
    expect(hd.cols, 2);
    expect(hd.index, 1);

    final expanded = atlasFor(36)!;
    expect(expanded.asset, 'assets/images/food-expanded-0.webp');
    expect(expanded.cols, 4);
    expect(expanded.index, 0);

    expect(atlasFor(-1), isNull);
  });
}
