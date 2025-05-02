class ProductSearchRequest {
  final String imageLink;

  ProductSearchRequest(this.imageLink);

  Map<String, dynamic> toJson() => {
        'image_link': imageLink,
      };
}

class ProductSearchResponse {
  final List<Product> products;

  ProductSearchResponse(this.products);

  factory ProductSearchResponse.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List)
        .map((e) => Product.fromJson(e))
        .toList();
    return ProductSearchResponse(products);
  }
}

class Product {
  final String id;
  final String name;
  final String price;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      imageUrl: json['image_url'],
    );
  }
}