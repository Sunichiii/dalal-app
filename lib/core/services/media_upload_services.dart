import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MediaUploadService {
  static const String _uploadUrl = 'https://media.bishalpantha.com.np/api/uploadmedia';
  static const String _mediaBaseUrl = 'https://media.bishalpantha.com.np';

  static Future<String> uploadMedia({
    required File file,
    required String sender,
    required String groupId,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..files.add(await http.MultipartFile.fromPath(
        'file', file.path,
        contentType: file.path.endsWith('.mp4')
            ? MediaType('video', 'mp4')
            : MediaType('image', 'jpeg'),
      ))
      ..fields.addAll({
        'sender': sender,
        'groupId': groupId,
        'mediaType': file.path.endsWith('.mp4') ? 'video' : 'image',
      });

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final mediaId = jsonDecode(responseBody)['mediaId'];
      return '$_mediaBaseUrl/api/media/$mediaId';
    } else {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }
}
