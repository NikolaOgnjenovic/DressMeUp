import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/services/imgur_service.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';

class UserImagesWidget extends StatefulWidget {
  final String baseUrl;

  const UserImagesWidget({super.key, required this.baseUrl});

  @override
  State<UserImagesWidget> createState() => _UserImagesWidgetState();
}

class _UserImagesWidgetState extends State<UserImagesWidget> {
  late final ImgurService _imgurService;
  List<ImageUploadResponse> _userImages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imgurService = ImgurService();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final images = await _imgurService.getImages();
      setState(() {
        _userImages = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        
        if (_error != null)
          Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        
        if (!_isLoading && _error == null)
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _userImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final image = _userImages[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageDetailsPage(imageUrl: image.imgurUrl),
                      ),
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
                            errorBuilder: (_, __, ___) => 
                              const Center(child: Icon(Icons.error)),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              color: Colors.black.withOpacity(0.4),
                              padding: const EdgeInsets.all(8),
                              child: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w600),
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