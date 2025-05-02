import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../services/product_search_service.dart';

class ImageGalleryWidget extends StatefulWidget {
  final String baseUrl;
  final String? authToken;

  const ImageGalleryWidget({
    Key? key,
    required this.baseUrl,
    this.authToken,
  }) : super(key: key);

  @override
  _ImageGalleryWidgetState createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  List<UploadedImage> _images = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUploadedImages();
  }

  Future<void> _fetchUploadedImages() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/images'),
        headers: widget.authToken != null
            ? {'Authorization': 'Bearer ${widget.authToken}'}
            : null,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _images = List<UploadedImage>.from(
            data['images'].map((img) => UploadedImage.fromJson(img)),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load images: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching images: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onImageTap(UploadedImage image) async {
    final productSearchService = ProductSearchService(
      baseUrl: widget.baseUrl,
    );

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/products?image=${image.url}'),
        headers: widget.authToken != null
            ? {'Authorization': 'Bearer ${widget.authToken}'}
            : null,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = List<Product>.from(
          data.map((p) => Product.fromJson(p)),
        );
        
        if (!mounted) return;
        
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => ProductSearchResults(
            products: products,
            imageUrl: image.url,
          ),
        );
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching products: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_images.isEmpty) {
      return const Center(child: Text('No images uploaded yet.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchUploadedImages,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final image = _images[index];
          return GestureDetector(
            onTap: () => _onImageTap(image),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image.url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      image.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchUploadedImages,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class UploadedImage {
  final int id;
  final String url;
  final String filename;
  final String uploadDate;

  UploadedImage({
    required this.id,
    required this.url,
    required this.filename,
    required this.uploadDate,
  });

  factory UploadedImage.fromJson(Map<String, dynamic> json) {
    return UploadedImage(
      id: json['id'],
      url: json['url'],
      filename: json['filename'],
      uploadDate: json['upload_date'],
    );
  }
}

class ProductSearchResults extends StatelessWidget {
  final List<Product> products;
  final String imageUrl;

  const ProductSearchResults({
    Key? key,
    required this.products,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Original image
            Container(
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Results title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${products.length} Similar Products Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            // Results list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _getProductImageUrl(product.link),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.shopping_bag);
                          },
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.brand.toUpperCase()),
                          const SizedBox(height: 4),
                          Text(
                            '${product.price.value.current} ${product.price.currency}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          // Open product link
                        },
                      ),
                      onTap: () {
                        // Open product details
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getProductImageUrl(String productLink) {
    // This is a placeholder - you would need to implement actual logic
    // to get a product image URL from the product link
    return 'https://via.placeholder.com/150?text=Product+Image';
  }
}