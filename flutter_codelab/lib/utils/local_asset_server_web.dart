class LocalAssetServer {
  int get port => 0;

  Future<void> start({String path = 'assets', int port = 0}) async {
    // No-op for web
  }

  void stop() {
    // No-op for web
  }
}
