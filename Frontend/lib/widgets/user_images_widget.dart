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
  int? _hoveredIndex;

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
          'Your saved fits',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
        
        if (_error != null)
          Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        
        if (!_isLoading && _error == null)
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _userImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final image = _userImages[index];
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageDetailsPage(imageUrl: image.imgurUrl),
                        ),
                      );
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: _hoveredIndex == index ? 1.02 : 1.0,
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
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
                              Positioned(
                                bottom: 16,
                                right: 0,
                                left: 0,
                                child: Center(
                                  child: Icon(
                                    Icons.remove_red_eye,
                                    size: 28,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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