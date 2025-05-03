import 'package:flutter/material.dart';
import 'package:dress_me_up/config/app_config.dart';
import 'package:dress_me_up/widgets/image_picker_widget.dart';
import 'package:dress_me_up/widgets/top_outfits_widget.dart';
import 'package:dress_me_up/widgets/user_images_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dress me up',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Montserrat',
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dress Me Up',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopOutfitsWidget(baseUrl: AppConfig.baseUrl),
            const SizedBox(height: 24),
            UserImagesWidget(baseUrl: AppConfig.baseUrl),
            const SizedBox(height: 100), // space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ImagePickerWidget()),
          );
        },
        icon: const Icon(Icons.camera_alt),
        label: const Text('Add Outfit'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
