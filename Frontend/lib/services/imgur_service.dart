import 'dart:convert';
import 'dart:io';
import 'package:dress_me_up/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html if (dart.library.io) 'dart:io';

class ImgurService {
  Future<String?> uploadImage(dynamic imageFile) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/upload/');
    final request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      final file = imageFile as html.File;
      final bytes = await _readFileBytes(file);
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      );
      request.files.add(multipartFile);
    } else {
      final file = imageFile as File;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);
      return data['link'];
    } else {
      print('Upload failed with status: ${response.statusCode}');
      return null;
    }
  }

  Future<List<int>> _readFileBytes(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    return reader.result as List<int>;
  }
}