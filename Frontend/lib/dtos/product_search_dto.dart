class ProductSearchRequest {
  final String image;

  ProductSearchRequest(this.image);

  Map<String, dynamic> toJson() => {
        'image': image,
      };
}

class ProductSearchResponse {
  final List<Product> products;

  ProductSearchResponse(this.products);

  factory ProductSearchResponse.fromJson(List<dynamic> json) {
    final products = json.map((e) => Product.fromJson(e)).toList();
    return ProductSearchResponse(products);
  }
}

class Product {
  final String brand;
  final String? id;
  final String link;
  final String name;
  final PriceInfo price;

  Product({
    required this.brand,
    this.id,
    required this.link,
    required this.name,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      brand: json['brand'],
      id: json['id'],
      link: json['link'],
      name: json['name'],
      price: PriceInfo.fromJson(json['price']),
    );
  }
}

class PriceInfo {
  final String currency;
  final PriceValue value;

  PriceInfo({
    required this.currency,
    required this.value,
  });

  factory PriceInfo.fromJson(Map<String, dynamic> json) {
    return PriceInfo(
      currency: json['currency'],
      value: PriceValue.fromJson(json['value']),
    );
  }
}

class PriceValue {
  final double current;
  final double? original;

  PriceValue({
    required this.current,
    this.original,
  });

  factory PriceValue.fromJson(Map<String, dynamic> json) {
    return PriceValue(
      current: json['current'].toDouble(),
      original: json['original']?.toDouble(),
    );
  }
}