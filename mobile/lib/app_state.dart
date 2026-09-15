import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api.dart';
import 'catalog.dart';
import 'models.dart';

enum PoolMode { catalog, eaten, both }

class AddressOption {
  AddressOption({required this.address, required this.count, required this.dishes});
  final String address;
  final int count;
  final List<String> dishes;
}

class AppState extends ChangeNotifier {
  AppState();

  late Catalog catalog;
  late ApiClient api;
  SharedPreferences? _prefs;

  String playerName = '';
  String apiBase = ApiClient.defaultBaseUrl();
  bool soundOn = true;
  bool? apiOk;
  String apiError = '';

  List<Place> places = [];
  int budget = 50;
  bool veg = false;
  PoolMode poolMode = PoolMode.catalog;
  bool eatAgainOnly = true;
  String spinProvince = '';
  String spinDistrict = '';
  String spinArea = '';
  List<String> spinAddresses = [];

  bool spinning = false;
  Food? result;
  int spins = 0;
  List<Food> reel = [];
  int reelStopIndex = 0;

  final _spinPlayer = AudioPlayer();
  final _winPlayer = AudioPlayer();
  final _uuid = const Uuid();

  Future<void> boot() async {
    catalog = await Catalog.load();
    _prefs = await SharedPreferences.getInstance();
    playerName = _prefs?.getString('baongocangi-name') ?? '';
    soundOn = _prefs?.getString('baongocangi-sound') != 'off';
    apiBase = ApiClient.defaultBaseUrl();
    api = ApiClient(baseUrl: apiBase);
    reel = catalog.foods.take(12).toList();
    reelStopIndex = 0;
    await _spinPlayer.setReleaseMode(ReleaseMode.loop);
    await refreshPlaces();
    notifyListeners();
  }

  Future<void> saveName(String name) async {
    playerName = name.trim();
    await _prefs?.setString('baongocangi-name', playerName);
    notifyListeners();
    await refreshPlaces();
  }

  Future<void> toggleSound() async {
    soundOn = !soundOn;
    await _prefs?.setString('baongocangi-sound', soundOn ? 'on' : 'off');
    if (!soundOn) {
      await _spinPlayer.stop();
      await _winPlayer.stop();
    }
    notifyListeners();
  }

  Future<void> refreshPlaces() async {
    try {
      final remote = await api.fetchPlaces();
      places = remote;
      apiOk = true;
      apiError = '';
      await _prefs?.setString('baongocangi-places', jsonEncode(places.map((p) => {
            ...p.toDraft(),
            'id': p.id,
            'createdAt': p.createdAt,
          }).toList()));
    } catch (error) {
      apiOk = false;
      apiError = error.toString();
      final raw = _prefs?.getString('baongocangi-places');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List;
          places = list.map((item) => Place.fromJson(item as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Set<String> get selectedAddressKeys => spinAddresses.map(foldVi).toSet();
  bool get addressesPicked => selectedAddressKeys.isNotEmpty;

  List<AddressOption> get addressOptions {
    final seen = <String, AddressOption>{};
    for (final place in places) {
      if (eatAgainOnly && !place.eatAgain) continue;
      if (spinProvince.isNotEmpty && place.provinceId != spinProvince) continue;
      if (spinDistrict.isNotEmpty && place.districtId != spinDistrict) continue;
      if (spinArea.trim().isNotEmpty) {
        final hay = foldVi('${place.address} ${place.restaurant} ${place.dishName}');
        final parts = foldVi(spinArea).split(' ').where((p) => p.isNotEmpty);
        if (parts.any((part) => !hay.contains(part))) continue;
      }
      final address = place.address.trim();
      if (address.isEmpty) continue;
      final key = foldVi(address);
      final current = seen[key];
      if (current != null) {
        seen[key] = AddressOption(
          address: current.address,
          count: current.count + 1,
          dishes: [
            ...current.dishes,
            if (!current.dishes.contains(place.dishName)) place.dishName,
          ],
        );
      } else {
        seen[key] = AddressOption(address: address, count: 1, dishes: [place.dishName]);
      }
    }
    final list = seen.values.toList()
      ..sort((a, b) => a.address.compareTo(b.address));
    return list;
  }

  List<Food> get eligible {
    late List<Food> population;
    if (addressesPicked) {
      population = places
          .where((p) => (!eatAgainOnly || p.eatAgain) && selectedAddressKeys.contains(foldVi(p.address)))
          .map(catalog.placeToFood)
          .toList();
    } else if (poolMode == PoolMode.eaten) {
      population = places.where((p) => !eatAgainOnly || p.eatAgain).map(catalog.placeToFood).toList();
    } else if (poolMode == PoolMode.both) {
      population = [
        ...catalog.foods,
        ...places.where((p) => !eatAgainOnly || p.eatAgain).map(catalog.placeToFood),
      ];
    } else {
      population = catalog.foods;
    }
    if (!veg) return population;
    return population.where((f) => f.veg).toList();
  }

  FoodSelector? get selector => FoodSelector.create(eligible, budget);

  void setBudget(int value) {
    budget = value;
    notifyListeners();
  }

  void setVeg(bool value) {
    veg = value;
    notifyListeners();
  }

  void setPool(PoolMode mode) {
    poolMode = mode;
    notifyListeners();
  }

  void setEatAgainOnly(bool value) {
    eatAgainOnly = value;
    notifyListeners();
  }

  void setProvince(String id) {
    spinProvince = id;
    spinDistrict = '';
    spinAddresses = [];
    notifyListeners();
  }

  void setDistrict(String id) {
    spinDistrict = id;
    spinAddresses = [];
    notifyListeners();
  }

  void setArea(String value) {
    spinArea = value;
    notifyListeners();
  }

  void toggleAddress(String address) {
    final key = foldVi(address);
    if (spinAddresses.any((item) => foldVi(item) == key)) {
      spinAddresses = spinAddresses.where((item) => foldVi(item) != key).toList();
    } else {
      spinAddresses = [...spinAddresses, address];
    }
    notifyListeners();
  }

  void selectAllAddresses() {
    spinAddresses = addressOptions.map((o) => o.address).toList();
    notifyListeners();
  }

  void clearAddresses() {
    spinAddresses = [];
    notifyListeners();
  }

  Future<Food?> openCase() async {
    final pool = eligible;
    final pick = selector;
    if (spinning || pool.isEmpty || pick == null) return null;
    spinning = true;
    result = null;
    notifyListeners();
    final winner = pick.choose(pool);
    final before = 24 + Random().nextInt(8);
    const after = 5;
    final built = <Food>[];
    final recent = <String>[];
    for (var i = 0; i < before + 1 + after; i++) {
      final alts = pool.where((f) => !recent.contains(f.key)).toList();
      final food = i == before ? winner : pick.choose(alts.isEmpty ? pool : alts);
      built.add(food);
      recent.add(food.key);
      if (recent.length > 8) recent.removeAt(0);
    }
    reel = built;
    reelStopIndex = before;
    if (soundOn) {
      await _spinPlayer.stop();
      await _spinPlayer.play(AssetSource('sounds/doraemon_song.mp3'));
    }
    notifyListeners();
    return winner;
  }

  Future<void> finishSpin(Food winner) async {
    await _spinPlayer.stop();
    if (soundOn) {
      await _winPlayer.play(AssetSource('sounds/success.mp3'));
    }
    spinning = false;
    result = winner;
    spins += 1;
    notifyListeners();
  }

  void dismissResult() {
    result = null;
    notifyListeners();
  }

  Future<void> savePlace(Map<String, dynamic> draft, {String? id}) async {
    try {
      if (id != null) {
        final updated = await api.updatePlace(id, draft);
        places = places.map((p) => p.id == id ? updated : p).toList();
      } else {
        final created = await api.createPlace(draft);
        places = [created, ...places];
      }
      apiOk = true;
      apiError = '';
    } catch (error) {
      apiError = error.toString();
      apiOk = false;
      if (id != null) {
        places = places.map((p) {
          if (p.id != id) return p;
          return Place.fromJson({...p.toDraft(), 'id': p.id, 'createdAt': p.createdAt, ...draft});
        }).toList();
      } else {
        places = [
          Place.fromJson({
            ...draft,
            'id': _uuid.v4(),
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          }),
          ...places,
        ];
      }
    }
    notifyListeners();
  }

  Future<void> deletePlace(String id) async {
    final previous = places;
    places = places.where((p) => p.id != id).toList();
    notifyListeners();
    try {
      await api.deletePlace(id);
    } catch (error) {
      places = previous;
      apiError = error.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _spinPlayer.dispose();
    _winPlayer.dispose();
    super.dispose();
  }
}
