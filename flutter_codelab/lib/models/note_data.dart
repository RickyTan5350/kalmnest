class NoteData {
  final String title;
  final String path;
  final bool visibility;
  final String topic;
  
  

  NoteData({
    required this.title,
    required this.path,
    required this.visibility,
    required this.topic,
  
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'file_path': path,
      'visibility': visibility,
      'topic': topic,
    };
  }
}