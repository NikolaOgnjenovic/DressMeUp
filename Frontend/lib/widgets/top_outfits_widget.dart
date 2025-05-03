import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';

class TopOutfitsWidget extends StatelessWidget {
  final String baseUrl;

  TopOutfitsWidget({super.key, required this.baseUrl});

  final List<ImageUploadResponse> _hardcodedImageInfos = [
    ImageUploadResponse(id: 1, imgurUrl: 'https://i.imgur.com/abc123.jpg'),
    ImageUploadResponse(id: 2, imgurUrl: 'https://i.imgur.com/def456.jpg'),
    ImageUploadResponse(id: 3, imgurUrl: 'https://i.imgur.com/ghi789.jpg'),
    ImageUploadResponse(id: 4, imgurUrl: 'https://i.imgur.com/jkl012.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Outfits Today',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _hardcodedImageInfos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final outfit = _hardcodedImageInfos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ImageDetailsPage(imageId: outfit.imgurUrl)),
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
                          outfit.imgurUrl,
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
