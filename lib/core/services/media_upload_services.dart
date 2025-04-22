import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MediaUploadService {
  // Keep your local testing URLs
  static const String _backendUrl = 'http://192.168.1.69:8000/api/uploadmedia';
  static const String _serverBaseUrl = 'http://192.168.1.69:8000';

  // Add your production domain
  static const String _productionDomain = 'https://media.bishalpantha.com.np';
  static const Duration _timeout = Duration(seconds: 30);

  static String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ext == 'mp4' ? 'video/mp4' : 'image/$ext';
  }

  static Future<String> uploadMedia({
    required File mediaFile,
    required String sender,
    required String groupId,
    required void Function(double progress) onProgress,
  }) async {
    try {
      final mimeType = _getMimeType(mediaFile.path);
      final request = http.MultipartRequest('POST', Uri.parse(_backendUrl))
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          mediaFile.path,
          filename: mediaFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ))
        ..fields.addAll({
          'sender': sender,
          'groupId': groupId,
          'mediaType': mimeType.startsWith('video') ? 'video' : 'image',
        });

      final response = await request.send().timeout(_timeout);
      final contentLength = response.contentLength ?? 1;
      int bytesUploaded = 0;
      final responseBytes = <int>[];

      await for (final chunk in response.stream) {
        bytesUploaded += chunk.length;
        responseBytes.addAll(chunk);
        onProgress(bytesUploaded / contentLength);
      }

      final responseBody = utf8.decode(responseBytes);
      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode} - $responseBody');
      }

      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      if (!jsonResponse.containsKey('filePath')) {
        throw Exception('Invalid server response: Missing filePath');
      }

      String filePath = jsonResponse['filePath'] as String;

      // Handle both local testing and production URLs
      if (filePath.startsWith('/uploads')) {
        return '$_serverBaseUrl$filePath';
      } else if (!filePath.startsWith('http')) {
        return '$_productionDomain$filePath';
      }

      return filePath;
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Upload timed out after ${_timeout.inSeconds} seconds');
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

}