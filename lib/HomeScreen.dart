import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ClearCachesScreen extends StatefulWidget {
  const ClearCachesScreen({super.key});

  @override
  State<ClearCachesScreen> createState() => _ClearCachesScreenState();
}

class _ClearCachesScreenState extends State<ClearCachesScreen> {


  double _cacheSize = 0.0;
  // Calculate the total size of the directory
  Future<double> _getDirectorySize(Directory dir) async {
    double size = 0.0;
    try {
      if (dir.existsSync()) {
        for (var file in dir.listSync(recursive: true)) {
          if (file is File) {
            size += await file.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }
    return size;
  }
  Future<void> _updateCacheSize() async {
    double size = await _getCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }

  @override
  void initState() {
    super.initState();
    _updateCacheSize(); // Calculate cache size on widget initialization
  }
  Future<double> _getCacheSize() async {
    try {
      var tempDir = await getTemporaryDirectory();

      if (tempDir.existsSync()) {
        double totalSize = _calculateFolderSize(tempDir);
        return totalSize / (1024 * 1024); // Convert to MB
      }
    } catch (e) {
      print("Error calculating cache size: $e");
    }
    return 0.0;
  }

  double _calculateFolderSize(Directory folder) {
    double folderSize = 0;
    try {
      folder.listSync(recursive: true, followLinks: false).forEach((entity) {
        if (entity is File) {
          folderSize += entity.lengthSync();
        }
      });
    } catch (e) {
      print("Error calculating folder size: $e");
    }
    return folderSize;
  }


  Future<void> _deleteCacheDir() async {
    try {
      print("Getting temporary directory...");
      var tempDir = await getTemporaryDirectory();
      print("Temporary directory: ${tempDir.path}");
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        setState(() {
          _mediaList = []; // Reset the list to empty or modify it as needed
        });
        print("Cache cleared successfully.");
      }
      await _getCacheSize(); // Update the cache size after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cache cleared successfully!')),
      );
    } catch (e) {
      print("Error clearing cache: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing cache: $e')),
      );
    }
  }
  List<Map<String, dynamic>> _mediaList = [];
  /// Add test cache data
  Future<void> _addCacheData() async {
    try {
      var tempDir = await getTemporaryDirectory();
      print("Temporary directory path: ${tempDir.path}");

      for (int i = 0; i < 5; i++) {
        File file = File('${tempDir.path}/test_file_$i.txt');
        await file.writeAsString('This is test data for file $i.');
        print('Created file: ${file.path}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test cache data added!')),
      );
    } catch (e) {
      print("Error adding cache data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding cache data: $e')),
      );
    }
  }
  // Pick an image from the gallery and save to cache
  Future<void> _pickAndSaveImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Get cache directory
        final Directory tempDir = await getTemporaryDirectory();

        // Create a cache path for the image
        final File cachedImage = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');

        // Copy the selected image to cache
        await File(pickedFile.path).copy(cachedImage.path);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to cache!')),
        );

        await _updateCacheSize();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No image selected.')),
        );
      }
    } catch (e) {
      print('Error picking/saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking/saving image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clear Caches',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
      _mediaList.isNotEmpty
      ?GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Number of columns
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _mediaList.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SizedBox(
              width: 200.0,
              height: 200.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0), // Optional: Rounded corners for the image
                child: Image.file(
                  File(_mediaList[index]['file']),
                  fit: BoxFit.cover, // Ensures the image covers the entire area
                ),
              ),
            ),
          );
        },
      )

          : const Center(
    child: Text('No images selected'),
    ),
          Text(
            'Cache Size: ${_cacheSize.toStringAsFixed(2)} MB',
            style: TextStyle(fontSize: 20),
          ),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor:Colors.orange, ),
              child: Text('Pick Image from Gallery',style: TextStyle(color: Colors.white),),
              onPressed: () async {
                await _pickImage(ImageSource.gallery); // Call your pick image function
              },
            ),
          ),
          // Center(
          //   child: ElevatedButton(
          //     style: ElevatedButton.styleFrom(backgroundColor:Colors.orange, ),
          //     child: Text('Add Cache Data',style: TextStyle(color: Colors.white),),
          //     onPressed: () async {
          //       await _addCacheData();
          //       await _updateCacheSize();
          //     },
          //   ),
          // ),
          SizedBox(height: 10,),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor:Colors.orange, ),
              child: Text('Clear Caches',style: TextStyle(color: Colors.white),),
              onPressed: () async {
                await _deleteCacheDir();
                await _updateCacheSize();

                setState(() {

                });
              },
            ),
          )
        ],
      ),
    );
  }
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();

    try {
      if (source == ImageSource.gallery) {
        // Picking multiple images from the gallery
        final List<XFile>? images = await _picker.pickMultiImage();
        if (images != null && images.isNotEmpty) {
          for (var image in images) {
            _addMedia(image.path, 'image');
            _updateCacheSize();
          }
        }
      } else if (source == ImageSource.camera) {
        // Capturing a single image from the camera
        final XFile? image = await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          _addMedia(image.path, 'image');
          _updateCacheSize();
        }
      }
    } catch (e) {
      log('Error picking image: $e');
    }

    setState(() {});
  }

// Helper method to add media to the list
  void _addMedia(String filePath, String type) {
    //ImagePaths.add(filePath);
    _mediaList.add({
      'file': filePath,
      'type': type,
    });
    _updateCacheSize();

    log('_mediaList ==> $_mediaList');
    log('You selected/captured a $type: $filePath');
  }

}
