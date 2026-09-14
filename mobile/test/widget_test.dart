import 'package:flutter_test/flutter_test.dart';
import 'package:baongocangi/catalog.dart';
import 'package:baongocangi/food_art.dart';
import 'package:baongocangi/photo.dart';

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
    expect(hd.rows, 2);
    expect(hd.index, 1);

    final expanded = atlasFor(36)!;
    expect(expanded.asset, 'assets/images/food-expanded-0.webp');
    expect(expanded.cols, 4);
    expect(expanded.rows, 3);
    expect(expanded.index, 0);

    final lunch = atlasFor(72)!;
    expect(lunch.asset, 'assets/images/food-lunch-0.webp');
    expect(lunch.cols, 4);
    expect(lunch.index, 0);

    final common = atlasFor(120)!;
    expect(common.asset, 'assets/images/food-common-0.webp');
    expect(common.cols, 4);

    expect(atlasFor(-1), isNull);
  });

  test('dish photos decode from data URLs', () {
    const photo = 'data:image/jpeg;base64,AQID';
    expect(decodeDishPhoto(null), isNull);
    expect(decodeDishPhoto('not-an-image'), isNull);
    expect(decodeDishPhoto(photo), [1, 2, 3]);
  });
}
