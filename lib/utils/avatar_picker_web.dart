import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_avatar_image.dart';

/// Web: выбор файла через HTML input[type=file] без Flutter-плагинов.
Future<PickedAvatarImage?> pickAvatarFromGallery() async {
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
  final completer = Completer<PickedAvatarImage?>();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onError.listen((_) {
      if (!completer.isCompleted) completer.completeError('Ошибка чтения файла');
    });

    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is Uint8List && result.isNotEmpty) {
        if (!completer.isCompleted) {
          completer.complete(
            PickedAvatarImage(bytes: result, fileName: file.name),
          );
        }
      } else if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    reader.readAsArrayBuffer(file);
  });

  uploadInput.click();
  return completer.future;
}

Future<PickedAvatarImage?> pickAvatarFromCamera() async {
  return pickAvatarFromGallery();
}
