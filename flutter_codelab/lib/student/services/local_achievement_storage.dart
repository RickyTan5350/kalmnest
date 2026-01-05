// This file serves as a conditional export to select the appropriate
// storage implementation based on the platform (IO vs Web).

export 'achievement_storage_io.dart'
    if (dart.library.html) 'achievement_storage_web.dart';
