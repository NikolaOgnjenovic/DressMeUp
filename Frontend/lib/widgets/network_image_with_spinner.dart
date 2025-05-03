import 'package:flutter/material.dart';

class NetworkImageWithLoader extends StatefulWidget {
  final String imageUrl;

  const NetworkImageWithLoader({super.key, required this.imageUrl});

  @override
  State<NetworkImageWithLoader> createState() => _NetworkImageWithLoaderState();
}

class _NetworkImageWithLoaderState extends State<NetworkImageWithLoader> {
  bool _isLoaded = false;
  late Image _image;

  @override
  void initState() {
    super.initState();
    _image = Image.network(widget.imageUrl, fit: BoxFit.cover);
    _loadImage();
  }

  void _loadImage() {
    final ImageStream stream = _image.image.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener(
        (ImageInfo _, bool __) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onError: (dynamic _, __) {
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? _image
        : const Center(child: CircularProgressIndicator());
  }
}
