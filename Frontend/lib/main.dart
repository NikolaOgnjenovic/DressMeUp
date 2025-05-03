import 'package:dress_me_up/config/app_config.dart';
import 'package:flutter/material.dart';
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
      title: 'Dress Me Up',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dress Me Up'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home screen with both widgets
          SingleChildScrollView(
            child: Column(
              children: [
                TopOutfitsWidget(baseUrl: AppConfig.baseUrl),
                UserImagesWidget(baseUrl: AppConfig.baseUrl),
              ],
            ),
          ),
          // Favorites screen
          const Center(child: Text('Favorites')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) { // Camera icon index
            _openImagePicker(context);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Add',
          )
        ],
      ),
    );
  }

  void _openImagePicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePickerWidget(),
      ),
    );
  }
}