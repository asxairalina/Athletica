import 'picked_avatar_image.dart';

import 'avatar_picker_io.dart'
    if (dart.library.html) 'avatar_picker_web.dart' as picker_impl;

Future<PickedAvatarImage?> pickAvatarFromGallery() =>
    picker_impl.pickAvatarFromGallery();

Future<PickedAvatarImage?> pickAvatarFromCamera() =>
    picker_impl.pickAvatarFromCamera();
