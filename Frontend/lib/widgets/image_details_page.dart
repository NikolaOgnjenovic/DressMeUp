import 'package:dress_me_up/dtos/product_search_dto.dart';
import 'package:dress_me_up/services/image_details_service.dart';
import 'package:flutter/material.dart';

class ImageDetailsPage extends StatefulWidget {
  final String imageId;

  const ImageDetailsPage({super.key, required this.imageId});

  @override
  _ImageDetailsPageState createState() => _ImageDetailsPageState();
}

class _ImageDetailsPageState extends State<ImageDetailsPage> {
  late Future<List<ProductSearchResponse>> _detailsFuture;
  final ImageDetailsService _detailsService = ImageDetailsService();

  @override
  void initState() {
    super.initState();
    _detailsFuture = _detailsService.getImageDetails(widget.imageId);
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
          if (response.products.isNotEmpty)
            Image.network(
              response.products.first.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                const Center(child: Icon(Icons.error, size: 100)),
            ),
          ...response.products.map((product) => ListTile(
            leading: Image.network(
              product.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.error),
            ),
            title: Text(product.name),
            subtitle: Text(product.price),
          )),
        ],
      ),
    );
  }
}