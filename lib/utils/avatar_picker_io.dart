import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'picked_avatar_image.dart';

final ImagePicker _picker = ImagePicker();

Future<PickedAvatarImage?> pickAvatarFromGallery() async {
  final picked = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  if (bytes.isEmpty) return null;

  return PickedAvatarImage(bytes: bytes, fileName: picked.name);
}

Future<PickedAvatarImage?> pickAvatarFromCamera() async {
  if (kIsWeb) return null;

  final picked = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );
  if (picked == null) return null;

  final bytes = await picked.readAsBytes();
  if (bytes.isEmpty) return null;

  return PickedAvatarImage(bytes: bytes, fileName: picked.name);
}
