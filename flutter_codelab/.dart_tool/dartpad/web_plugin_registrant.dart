// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:audio_session/audio_session_web.dart';
import 'package:desktop_drop/desktop_drop_web.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter_inappwebview_web/web/main.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:just_audio_web/just_audio_web.dart';
import 'package:package_info_plus/src/package_info_plus_web.dart';
import 'package:printing/printing_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:video_player_web/video_player_web.dart';
import 'package:wakelock_plus/src/wakelock_plus_web_plugin.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  AudioSessionWeb.registerWith(registrar);
  DesktopDropWeb.registerWith(registrar);
  FilePickerWeb.registerWith(registrar);
  InAppWebViewFlutterPlugin.registerWith(registrar);
  FlutterSecureStorageWeb.registerWith(registrar);
  JustAudioPlugin.registerWith(registrar);
  PackageInfoPlusWebPlugin.registerWith(registrar);
  PrintingPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  VideoPlayerPlugin.registerWith(registrar);
  WakelockPlusWebPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
