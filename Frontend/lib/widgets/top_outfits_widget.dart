import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';

class TopOutfitsWidget extends StatelessWidget {
  final String baseUrl;
  
  TopOutfitsWidget({super.key, required this.baseUrl});

  // Hardcoded image info data
  final List<ImageUploadResponse> _hardcodedImageInfos = [
    ImageUploadResponse(
      imageId: '1',
      imageUrl: 'https://i.imgur.com/abc123.jpg',
    ),
    ImageUploadResponse(
      imageId: '2',
      imageUrl: 'https://i.imgur.com/def456.jpg',
    ),
    ImageUploadResponse(
      imageId: '3',
      imageUrl: 'https://i.imgur.com/ghi789.jpg',
    ),
    ImageUploadResponse(
      imageId: '4',
      imageUrl: 'https://i.imgur.com/jkl012.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Top Outfits',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hardcodedImageInfos.length,
            itemBuilder: (context, index) {
              final imageInfo = _hardcodedImageInfos[index];
              return _buildImageCard(imageInfo, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(ImageUploadResponse imageInfo, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetailsPage(imageId: imageInfo.imageId),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Card(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.network(
                  imageInfo.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => 
                    const Center(child: Icon(Icons.error)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'View Details',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}