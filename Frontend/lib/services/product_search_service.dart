import 'dart:convert';
import 'package:dress_me_up/config/app_config.dart';
import 'package:dress_me_up/dtos/product_search_dto.dart';
import 'package:http/http.dart' as http;

class ProductSearchService {
  Future<ProductSearchResponse> searchProducts(String imageLink) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/products');
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': 'OpenPlatform/1.0',
    };

    final response = await http.get(
      uri.replace(queryParameters: {'image': imageLink}),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ProductSearchResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to search products: ${response.statusCode}');
    }
  }
}