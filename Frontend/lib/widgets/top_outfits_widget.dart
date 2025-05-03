import 'dart:convert';
import 'package:dress_me_up/dtos/image_upload_response.dart';
import 'package:dress_me_up/widgets/image_details_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TopOutfitsWidget extends StatefulWidget {
  final String baseUrl;

  const TopOutfitsWidget({super.key, required this.baseUrl});

  @override
  State<TopOutfitsWidget> createState() => _TopOutfitsWidgetState();
}

class _TopOutfitsWidgetState extends State<TopOutfitsWidget> {
  List<ImageUploadResponse> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopOutfits();
  }

  Future<void> _fetchTopOutfits() async {
    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/images/celebrity/quality'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _images = data.map((item) => ImageUploadResponse.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load outfits');
      }
    } catch (e) {
      debugPrint('Error fetching outfits: $e');
      setState(() {
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
          'Top Outfits Today',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                height: 260,
                child: _images.isEmpty
                    ? const Center(child: Text("No images found."))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final outfit = _images[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageDetailsPage(imageUrl: outfit.imgurUrl),
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
                                      outfit.imgurUrl,
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
