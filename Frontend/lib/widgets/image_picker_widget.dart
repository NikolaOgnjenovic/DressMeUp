import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/imgur_service.dart';

class ImagePickerWidget extends StatefulWidget {
  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  bool _isUploading = false;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectImage() async {
    if (kIsWeb) {
      // Web version
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files == null || files.isEmpty) return;
        final imageFile = files[0];
        await _uploadImage(imageFile);
      });
    } else {
      // Mobile/Desktop version
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _uploadImage(File(pickedFile.path));
      }
    }
  }

  Future<void> _uploadImage(dynamic image) async {
    setState(() {
      _isUploading = true;
      _imageUrl = null;
    });

    try {
      final imgurService = ImgurService();
      final response = await imgurService.uploadImage(image);
      
      if (response != null) {
        setState(() {
          _imageUrl = response.imgurUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Upload Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading)
              CircularProgressIndicator(),
            if (!_isUploading && _imageUrl != null)
              Image.network(_imageUrl!),
            if (!_isUploading)
              ElevatedButton(
                onPressed: _selectImage,
                child: Text('Select Image to Upload'),
              ),
          ],
        ),
      ),
    );
  }
}