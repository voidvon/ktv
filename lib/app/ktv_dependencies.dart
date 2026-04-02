import 'package:ktv2/ktv2.dart';

import '../features/ktv/application/ktv_controller.dart';
import '../features/media_library/data/media_library_repository.dart';

KtvController createKtvController({
  MediaLibraryRepository? mediaLibraryRepository,
  PlayerController? playerController,
}) {
  return KtvController(
    mediaLibraryRepository: mediaLibraryRepository ?? MediaLibraryRepository(),
    playerController: playerController ?? createPlayerController(),
  );
}
