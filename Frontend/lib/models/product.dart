class Product {
  final String? id;
  final String name;
  final Price price;
  final String link;
  final String brand;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.link,
    required this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: Price.fromJson(json['price']),
      link: json['link'],
      brand: json['brand'],
    );
  }
}

class Price {
  final String currency;
  final PriceValue value;

  Price({
    required this.currency,
    required this.value,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
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
      current: json['current']?.toDouble(),
      original: json['original']?.toDouble(),
    );
  }
}