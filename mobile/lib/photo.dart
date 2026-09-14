import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

const maxPhotoChars = 1100000;

Uint8List? decodeDishPhoto(String? photo) {
  if (photo == null || photo.isEmpty) return null;
  final comma = photo.indexOf(',');
  if (!photo.startsWith('data:image') || comma < 0) return null;
  try {
    return base64Decode(photo.substring(comma + 1));
  } catch (_) {
    return null;
  }
}

Future<String?> pickDishPhoto(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 720,
    maxHeight: 720,
    imageQuality: 68,
  );
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  final photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
  if (photo.length > maxPhotoChars) {
    throw Exception('Ảnh quá nặng, hãy chọn ảnh nhỏ hơn');
  }
  return photo;
}
