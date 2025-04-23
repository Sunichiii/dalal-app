import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MediaUploadService {
  static const String _uploadUrl = 'http://localhost:8000/api/uploadmedia';
  static const String _getMediaUrl = 'http://localhost:8000/api/media';

  static Future<String> uploadMedia({
    required File mediaFile,
    required String sender,
    required String groupId,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          mediaFile.path,
          contentType: MediaType('image', 'png'), // Adjust based on file type
        ),
      );

      request.fields.addAll({
        'sender': sender,
        'groupId': groupId,
        'mediaType': mediaFile.path.endsWith('.mp4') ? 'video' : 'image',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final mediaId = jsonResponse['mediaId'];
        return '$_getMediaUrl/$mediaId'; // Return the GET endpoint URL
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }
}