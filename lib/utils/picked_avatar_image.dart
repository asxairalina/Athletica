import 'dart:typed_data';

class PickedAvatarImage {
  final Uint8List bytes;
  final String? fileName;

  const PickedAvatarImage({
    required this.bytes,
    this.fileName,
  });
}
