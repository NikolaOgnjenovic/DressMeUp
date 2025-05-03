import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';

class UserImagesWidget extends StatelessWidget {
  final String baseUrl;

  UserImagesWidget({super.key, required this.baseUrl});

  final List<ImageUploadResponse> _hardcodedUserImageInfos = [
    ImageUploadResponse(imageId: '5', imageUrl: 'https://i.imgur.com/mno345.jpg'),
    ImageUploadResponse(imageId: '6', imageUrl: 'https://i.imgur.com/pqr678.jpg'),
    ImageUploadResponse(imageId: '7', imageUrl: 'https://i.imgur.com/stu901.jpg'),
    ImageUploadResponse(imageId: '8', imageUrl: 'https://i.imgur.com/vwx234.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Captured Outfits',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _hardcodedUserImageInfos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final image = _hardcodedUserImageInfos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ImageDetailsPage(imageId: image.imageId)),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        image.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.center,
                      child: const Text(
                        'View Details',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
