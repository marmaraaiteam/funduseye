import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';  // MediaType için

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FundusEye',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.purple,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String label = '';
  double confidence = 0.0;
  bool isLoading = false; // Yükleme durumu göstergesi için değişken

  Future<void> uploadFile(File imageFile) async {
    var dio = Dio();
    String? mimeType = lookupMimeType(imageFile.path);

    if (mimeType == null || (!['image/jpeg', 'image/png'].contains(mimeType))) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsupported File Type'),
          content: const Text('Please select a JPEG or PNG image.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path,
          filename: 'uploaded_image.jpg', contentType: MediaType.parse(mimeType)),
    });

    if (await imageFile.length() > 5 * 1024 * 1024) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Too Large'),
          content: const Text('File size exceeds 5 MB limit.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true; // Yükleme başladığında
      });
      var response = await dio.post(
        'https://Bitirme-odirapi.hf.space/predict', // API URL'niz
        data: formData,
      );

      if (response.statusCode == 200) {
        var responseData = response.data;
        setState(() {
          label = responseData['class'];
          confidence = responseData['confidence'];
        });
      } else {
        print('HTTP request error with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during request: $e');
    } finally {
      setState(() {
        isLoading = false; // İşlem tamamlandığında
      });
    }
  }

  Future<void> pickImageGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    var imageFile = File(image.path);

    setState(() {
      filePath = imageFile;
    });
    await uploadFile(imageFile);
  }

  Future<void> pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    var imageFile = File(image.path);

    setState(() {
      filePath = imageFile;
    });
    await uploadFile(imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FundusEye"),
        backgroundColor: Colors.deepPurple,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple, Colors.purpleAccent],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: Container(),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : (filePath == null
              ? const Text('No image selected.',
              style: TextStyle(color: Colors.white))
              : Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.file(filePath!,
                    width: MediaQuery.of(context).size.width * 0.8),
                Text('Label: $label',
                    style: const TextStyle(color: Colors.white)),
                Text(
                    'Confidence: ${confidence.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          )),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPopupMenu,
        tooltip: 'Options',
        child: const Icon(Icons.attachment, color: Colors.white70),
      ),
    );
  }

  void _showPopupMenu() async {
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          MediaQuery.of(context).size.width - 50,
          MediaQuery.of(context).size.height - 80,
          0,
          0),
      items: [
        PopupMenuItem<String>(
          child: Text('Take a photo',
              style: TextStyle(color: Colors.purple.shade300)),
          value: 'Take a photo',
        ),
        PopupMenuItem<String>(
          child: Text('Pick from gallery',
              style: TextStyle(color: Colors.purple.shade300)),
          value: 'Pick from gallery',
        ),
      ],
      elevation: 8.0,
      color: Colors.deepPurple,
    ).then((value) {
      handleMenuAction(value ?? '');
    });
  }

  void handleMenuAction(String choice) {
    if (choice == 'Take a photo') {
      pickImageCamera();
    } else if (choice == 'Pick from gallery') {
      pickImageGallery();
    }
  }
}
