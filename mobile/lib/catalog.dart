import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'models.dart';

const rarityColors = [
  ColorValue(0xFF4B69FF),
  ColorValue(0xFF8847FF),
  ColorValue(0xFFD32CE6),
  ColorValue(0xFFEB4B4B),
  ColorValue(0xFFE4AE39),
];

class ColorValue {
  const ColorValue(this.value);
  final int value;
}

const rarityLabels = ['Phổ thông', 'Cao cấp', 'Đặc biệt', 'Huyền thoại', 'Thần thoại'];

int priceRarity(int price) {
  if (price <= 40) return 0;
  if (price <= 65) return 1;
  if (price <= 100) return 2;
  if (price <= 130) return 3;
  return 4;
}

String priceLabel(num thousands) {
  final n = thousands.round();
  if (n == 0) return '0đ';
  return '$n.000đ';
}

String foldVi(String value) {
  const accents =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  const plain =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
  final lower = value.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = accents.indexOf(ch);
    buf.write(i >= 0 ? plain[i] : ch);
  }
  return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String shortPlaceName(String name) {
  return name.replaceFirst(
    RegExp(r'^(Thành phố |Tỉnh |Quận |Huyện |Thị xã )', caseSensitive: false),
    '',
  );
}

class Catalog {
  Catalog({required this.foods, required this.provinces});

  final List<Food> foods;
  final List<Province> provinces;

  late final List<Province> sortedProvinces = [
    ...provinces,
  ]..sort((a, b) {
      if (a.id == '01') return -1;
      if (b.id == '01') return 1;
      return a.name.compareTo(b.name);
    });

  Province? provinceById(String id) {
    for (final p in provinces) {
      if (p.id == id) return p;
    }
    return null;
  }

  District? districtById(Province? province, String id) {
    if (province == null) return null;
    for (final d in province.districts) {
      if (d.id == id) return d;
    }
    return null;
  }

  Food? matchCatalogFood(String name) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final food in foods) {
      if (food.name.toLowerCase() == needle) return food;
    }
    for (final food in foods) {
      final n = food.name.toLowerCase();
      if (n.contains(needle) || needle.contains(n)) return food;
    }
    return null;
  }

  Food placeToFood(Place place) {
    final matched = matchCatalogFood(place.dishName);
    final price = place.price != 0 ? place.price : (matched?.price ?? 50);
    final province = provinceById(place.provinceId);
    final district = districtById(province, place.districtId);
    return Food(
      name: place.dishName,
      sub: [
        place.restaurant,
        place.address,
        district?.name,
        province?.name,
      ].where((s) => s != null && s.isNotEmpty).join(' • '),
      price: price,
      rarity: priceRarity(price),
      image: place.image ?? matched?.image ?? -1,
      photo: place.photo,
      veg: matched?.veg ?? false,
      quip: place.notes.isNotEmpty ? place.notes : (matched?.quip ?? ''),
      customId: 'place-${place.id}',
      placeId: place.id,
      restaurant: place.restaurant,
      address: place.address,
      provinceName: province?.name,
      districtName: district?.name,
      stars: place.stars,
      eatAgain: place.eatAgain,
    );
  }

  String mapsUrl(Place place) {
    final province = provinceById(place.provinceId);
    final district = districtById(province, place.districtId);
    final query = [
      place.restaurant,
      place.address,
      district?.name,
      province?.name,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
  }

  static Future<Catalog> load() async {
    final foodsRaw = jsonDecode(await rootBundle.loadString('assets/data/foods.json')) as List;
    final vietRaw = jsonDecode(await rootBundle.loadString('assets/data/vietnam.json')) as List;
    final foods = foodsRaw.map((item) {
      final map = item as Map<String, dynamic>;
      final price = (map['price'] as num).toInt();
      return Food(
        name: map['name'] as String,
        sub: map['sub'] as String,
        price: price,
        rarity: priceRarity(price),
        image: (map['image'] as num).toInt(),
        veg: map['veg'] as bool? ?? false,
        quip: map['quip'] as String? ?? '',
      );
    }).toList();
    final provinces = vietRaw.map((item) => Province.fromJson(item as Map<String, dynamic>)).toList();
    return Catalog(foods: foods, provinces: provinces);
  }
}

class FoodSelector {
  FoodSelector._(this._population, this._weights);

  final List<Food> _population;
  final List<double> _weights;

  static FoodSelector? create(List<Food> population, int target) {
    if (population.isEmpty) return null;
    final min = population.map((f) => f.price).reduce(minInt);
    final max = population.map((f) => f.price).reduce(maxInt);
    final clamped = target.clamp(min, max);
    final counts = <int, int>{};
    for (final f in population) {
      counts[f.price] = (counts[f.price] ?? 0) + 1;
    }
    final logs = population.map((f) => log(maxD(f.price.toDouble(), 1) / 50)).toList();
    const spread = 0.35;
    final prior = List<double>.generate(population.length, (i) {
      final x = logs[i] / spread;
      return -0.5 * x * x - log(counts[population[i].price]!.toDouble());
    });

    List<double> weights(double tilt) {
      final logits = List<double>.generate(logs.length, (i) => prior[i] + tilt * logs[i]);
      final anchor = logits.reduce(maxD);
      final raw = logits.map((x) => exp(x - anchor)).toList();
      final sum = raw.fold<double>(0, (a, b) => a + b);
      return raw.map((x) => x / sum).toList();
    }

    double mean(List<double> w) {
      var s = 0.0;
      for (var i = 0; i < population.length; i++) {
        s += population[i].price * w[i];
      }
      return s;
    }

    late List<double> raw;
    if (clamped == min || clamped == max) {
      final n = counts[clamped]!;
      raw = population.map((f) => f.price == clamped ? 1 / n : 0.0).toList();
    } else {
      var lo = -1.0;
      var hi = 1.0;
      while (mean(weights(lo)) > clamped) {
        lo *= 2;
      }
      while (mean(weights(hi)) < clamped) {
        hi *= 2;
      }
      for (var i = 0; i < 80; i++) {
        final mid = (lo + hi) / 2;
        if (mean(weights(mid)) < clamped) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      raw = weights((lo + hi) / 2);
    }
    return FoodSelector._(population, raw);
  }

  Food choose(List<Food> items, [Random? random]) {
    final rng = random ?? Random();
    final w = items.map((f) {
      final i = _population.indexWhere((item) => item.key == f.key);
      return i < 0 ? 0.0 : _weights[i];
    }).toList();
    final sum = w.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return items[rng.nextInt(items.length)];
    var remaining = rng.nextDouble() * sum;
    for (var i = 0; i < items.length; i++) {
      remaining -= w[i];
      if (remaining < 0) return items[i];
    }
    return items.last;
  }
}

int minInt(int a, int b) => a < b ? a : b;
int maxInt(int a, int b) => a > b ? a : b;
double maxD(double a, double b) => a > b ? a : b;
