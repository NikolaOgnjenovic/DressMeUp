import 'dart:convert';
import 'package:dress_me_up/config/app_config.dart';
import 'package:dress_me_up/dtos/product_search_dto.dart';
import 'package:http/http.dart' as http;

class ImageDetailsService {
  Future<List<ProductSearchResponse>> getImageDetails(String imageId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/images/$imageId/details');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => ProductSearchResponse.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load image details: ${response.statusCode}');
    }
  }
}