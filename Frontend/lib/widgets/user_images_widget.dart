import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';

class UserImagesWidget extends StatelessWidget {
  final String baseUrl;
  
  UserImagesWidget({super.key, required this.baseUrl});

  // Hardcoded image info data
  final List<ImageUploadResponse> _hardcodedUserImageInfos = [
    ImageUploadResponse(
      imageId: '5',
      imageUrl: 'https://i.imgur.com/mno345.jpg',
    ),
    ImageUploadResponse(
      imageId: '6',
      imageUrl: 'https://i.imgur.com/pqr678.jpg',
    ),
    ImageUploadResponse(
      imageId: '7',
      imageUrl: 'https://i.imgur.com/stu901.jpg',
    ),
    ImageUploadResponse(
      imageId: '8',
      imageUrl: 'https://i.imgur.com/vwx234.jpg',
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
            'Your Outfits',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: _hardcodedUserImageInfos.length,
          itemBuilder: (context, index) {
            final imageInfo = _hardcodedUserImageInfos[index];
            return _buildImageCard(imageInfo, context);
          },
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
      child: Card(
        elevation: 2,
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
    );
  }
}