import 'dart:convert';
import 'dart:io';
import 'package:dress_me_up/config/app_config.dart';
import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html if (dart.library.io) 'dart:io';

class ImgurService {
  Future<ImageUploadResponse?> uploadImage(dynamic imageFile) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/images');
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
      return ImageUploadResponse.fromJson(data); // Convert JSON to Dart object
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

  Future<List<ImageUploadResponse>> getImages() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/images');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ImageUploadResponse.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load images: ${response.statusCode}');
    }
  }
}