import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart'; // MediaType için

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FundAi',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: Colors.white),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key});

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

    if (mimeType == null ||
        (!['image/jpg', 'image/jpeg', 'image/png'].contains(mimeType))) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Desteklenmeyen Dosya Türü',
            style: GoogleFonts.roboto(),
          ),
          content: Text(
            'Lütfen bir JPEG veya PNG resmi seçin.',
            style: GoogleFonts.roboto(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Tamam',
                style: GoogleFonts.roboto(),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'uploaded_image.jpg',
        contentType: MediaType.parse(mimeType),
      ),
    });

    if (await imageFile.length() > 5 * 1024 * 1024) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Dosya Çok Büyük',
            style: GoogleFonts.roboto(),
          ),
          content: Text(
            'Dosya boyutu 5 MB sınırını aşıyor.',
            style: GoogleFonts.roboto(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Tamam',
                style: GoogleFonts.roboto(),
              ),
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
      print('İstek sırasında hata oluştu: $e');
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

    label = "";

    setState(() {
      filePath = imageFile;
    });
  }

  Future<void> pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    var imageFile = File(image.path);

    label = "";

    setState(() {
      filePath = imageFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "FundAi",
          style: GoogleFonts.dancingScript(
            color: Colors.black,
            fontSize: 30,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: SizedBox(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: min(MediaQuery.of(context).size.width, 600),
            height: MediaQuery.of(context).size.height - 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 450,
                      decoration: BoxDecoration(
                        gradient: filePath == null
                            ? const LinearGradient(
                                colors: [Colors.teal, Colors.tealAccent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : null,
                        color: filePath != null ? Colors.black : null,
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            isLoading
                                ? const CircularProgressIndicator()
                                : (filePath == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.image_not_supported_rounded,
                                            size: 100,
                                            color: Colors.black,
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Lütfen tahmin edilmesini istediğiniz göz görüntüsünü yükleyin.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                              color: Colors.black,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Desteklenen format: JPG, JPEG, PNG',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Image.file(
                                            filePath!,
                                            height: 250,
                                            fit: BoxFit.cover,
                                          ),
                                          Card(
                                            color: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.0),
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    label,
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.white,
                                                      fontSize: 25,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Doğruluk: %${(confidence * 100).toStringAsFixed(2)}',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 100,
                      child: ElevatedButton(
                        onPressed: pickImageGallery,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Colors.tealAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.black,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "Galeriden Seç",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 100,
                      child: ElevatedButton(
                        onPressed: pickImageCamera,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Colors.tealAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.black,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "Fotoğraf Çek",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.3,
                      height: 100,
                      child: ElevatedButton(
                        onPressed: () {
                          if (filePath != null) {
                            uploadFile(filePath!);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Resim Seçilmedi',
                                  style: GoogleFonts.roboto(),
                                ),
                                content: Text(
                                  'Lütfen önce bir resim seçin.',
                                  style: GoogleFonts.roboto(),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                      'Tamam',
                                      style: GoogleFonts.roboto(),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.teal, Colors.tealAccent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.upload_file,
                                    size: 40,
                                    color: Colors.black,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      "Analiz Et",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.roboto(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void handleMenuAction(String choice) {
    if (choice == 'Fotoğraf çek') {
      pickImageCamera();
    } else if (choice == 'Galeriden seç') {
      pickImageGallery();
    }
  }
}
