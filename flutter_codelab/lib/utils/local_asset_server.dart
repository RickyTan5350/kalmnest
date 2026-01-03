// Conditional export
export 'local_asset_server_io.dart'
    if (dart.library.js_interop) 'local_asset_server_web.dart';
