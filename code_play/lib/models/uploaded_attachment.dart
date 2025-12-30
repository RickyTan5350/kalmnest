import 'package:file_picker/file_picker.dart';

class UploadedAttachment {
  final PlatformFile localFile;
  final String? serverFileId;
  final String? publicUrl;
  final bool isUploading;
  final bool isFailed;

  UploadedAttachment({
    required this.localFile,
    this.serverFileId,
    this.publicUrl,
    this.isUploading = false,
    this.isFailed = false,
  });
}