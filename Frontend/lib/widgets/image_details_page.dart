import 'package:dress_me_up/dtos/product_search_dto.dart';
import 'package:dress_me_up/services/product_search_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageDetailsPage extends StatefulWidget {
  final String imageUrl;

  const ImageDetailsPage({super.key, required this.imageUrl});

  @override
  _ImageDetailsPageState createState() => _ImageDetailsPageState();
}

class _ImageDetailsPageState extends State<ImageDetailsPage> {
  late Future<List<ProductSearchResponse>> _detailsFuture;
  final ProductSearchService _detailsService = ProductSearchService();

  @override
  void initState() {
    super.initState();
    _detailsFuture = _detailsService.searchProducts(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Details'),
      ),
      body: FutureBuilder<List<ProductSearchResponse>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No details found'));
          }

          final details = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: details.length,
            itemBuilder: (context, index) {
              final response = details[index];
              return _buildProductResponseCard(response, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductResponseCard(ProductSearchResponse response, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          // Display the original image at the top
          Image.network(
            widget.imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => 
              const Center(child: Icon(Icons.error, size: 100)),
          ),
          ...response.products.map((product) => ListTile(
            leading: InkWell(
              onTap: () => _launchUrl(product.link),
              child: Stack(
                children: [
                  Image.network(
                    product.link,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.error),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_new,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(product.name),
            subtitle: Text('${product.price.value.current} ${product.price.currency}'),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _launchUrl(product.link),
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}