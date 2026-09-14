class District {
  const District({required this.id, required this.name});
  final String id;
  final String name;

  factory District.fromJson(Map<String, dynamic> json) => District(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class Province {
  const Province({required this.id, required this.name, required this.districts});
  final String id;
  final String name;
  final List<District> districts;

  factory Province.fromJson(Map<String, dynamic> json) => Province(
        id: json['id'] as String,
        name: json['name'] as String,
        districts: (json['districts'] as List)
            .map((item) => District.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class Food {
  const Food({
    required this.name,
    required this.sub,
    required this.price,
    required this.rarity,
    required this.image,
    required this.quip,
    this.veg = false,
    this.customId,
    this.placeId,
    this.restaurant,
    this.address,
    this.provinceName,
    this.districtName,
    this.stars,
    this.eatAgain,
    this.photo,
  });

  final String name;
  final String sub;
  final int price;
  final int rarity;
  final int image;
  final String quip;
  final bool veg;
  final String? customId;
  final String? placeId;
  final String? restaurant;
  final String? address;
  final String? provinceName;
  final String? districtName;
  final int? stars;
  final bool? eatAgain;
  final String? photo;

  String get key => customId ?? '$name-$image';
}

class Place {
  const Place({
    required this.id,
    required this.dishName,
    required this.restaurant,
    required this.address,
    required this.provinceId,
    required this.districtId,
    required this.stars,
    required this.eatAgain,
    required this.price,
    required this.notes,
    required this.createdAt,
    this.image,
    this.photo,
  });

  final String id;
  final String dishName;
  final String restaurant;
  final String address;
  final String provinceId;
  final String districtId;
  final int stars;
  final bool eatAgain;
  final int price;
  final String notes;
  final int createdAt;
  final int? image;
  final String? photo;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as String,
        dishName: json['dishName'] as String,
        restaurant: json['restaurant'] as String,
        address: json['address'] as String,
        provinceId: json['provinceId'] as String,
        districtId: json['districtId'] as String,
        stars: (json['stars'] as num).toInt(),
        eatAgain: json['eatAgain'] as bool? ?? true,
        price: (json['price'] as num?)?.toInt() ?? 50,
        notes: json['notes'] as String? ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        image: (json['image'] as num?)?.toInt(),
        photo: json['photo'] as String?,
      );

  Map<String, dynamic> toDraft() => {
        'dishName': dishName,
        'restaurant': restaurant,
        'address': address,
        'provinceId': provinceId,
        'districtId': districtId,
        'stars': stars,
        'eatAgain': eatAgain,
        'price': price,
        'notes': notes,
        'image': image,
        'photo': photo,
      };
}

class ChatTurn {
  const ChatTurn({required this.role, required this.text});
  final String role;
  final String text;
}
