import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';

class UserImagesWidget extends StatelessWidget {
  final String baseUrl;

  UserImagesWidget({super.key, required this.baseUrl});

  final List<ImageUploadResponse> _hardcodedUserImageInfos = [
    ImageUploadResponse(id: 5, imgurUrl: 'https://i.imgur.com/mno345.jpg'),
    ImageUploadResponse(id: 6, imgurUrl: 'https://i.imgur.com/pqr678.jpg'),
    ImageUploadResponse(id: 7, imgurUrl: 'https://i.imgur.com/stu901.jpg'),
    ImageUploadResponse(id: 8, imgurUrl: 'https://i.imgur.com/vwx234.jpg'),
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
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hardcodedUserImageInfos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final image = _hardcodedUserImageInfos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ImageDetailsPage(imageId: image.imgurUrl)),
                  );
                },
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          image.imgurUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error)),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            color: Colors.black.withOpacity(0.4),
                            padding: const EdgeInsets.all(8),
                            child: const Text(
                              'View Details',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}