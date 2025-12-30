class ApiFile {
  final String fileId;
  final String type; // 'pdf', 'png', etc.
  final String? url; // The clickable URL from your Laravel accessor

  ApiFile({
    required this.fileId,
    required this.type,
    this.url,
  });

  // Factory to convert JSON from Laravel into a Dart object
  factory ApiFile.fromJson(Map<String, dynamic> json) {
    return ApiFile(
      fileId: json['file_id'],
      type: json['type'],
      // Ensure we handle cases where url might be missing
      url: json['url'], 
    );
  }
}