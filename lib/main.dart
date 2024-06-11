import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapMath',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'SnapMath Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedImage;
  Iterable<double>? _detectedNumbers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_selectedImage == null)
              Column(
                children: [
                  Text(
                    'Welcome to',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Snap Math!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    'Try picking or taking a photo\nthat have numbers!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 24,
                  )
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      _pickImageAndProcess(source: ImageSource.gallery),
                  child: const Row(
                    children: [
                      Icon(Icons.photo),
                      SizedBox(
                        width: 8,
                      ),
                      Text('Pick photo'),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                ElevatedButton(
                    onPressed: () =>
                        _pickImageAndProcess(source: ImageSource.camera),
                    child: const Row(
                      children: [
                        Icon(Icons.camera),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Camera'),
                      ],
                    )),
              ],
            ),
            const SizedBox(
              height: 24,
            ),
            if (_selectedImage != null)
              SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Image.file(_selectedImage!)),
            const SizedBox(
              height: 16,
            ),
            if (_detectedNumbers != null)
              Text(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  'Found these numbers:\n${_detectedNumbers?.map((value) => value == value.round() ? value.round().toString() : value.toStringAsFixed(2)).join(", ")}'),
            const SizedBox(
              height: 16,
            ),
            if (_detectedNumbers != null)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Average = ${_calculateAverage()}'),
                      IconButton(
                          onPressed: () =>
                              _copyToClipboard(_calculateAverage().toString()),
                          icon: const Icon(Icons.copy))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sum = ${_calculateSum()}'),
                      IconButton(
                          onPressed: () =>
                              _copyToClipboard(_calculateSum().toString()),
                          icon: const Icon(Icons.copy))
                    ],
                  ),
                ],
              )
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _copyToClipboard(String toCopy) async {
    await Clipboard.setData(ClipboardData(text: toCopy));
    final snackBar = SnackBar(
      content: Text('Copied ${toCopy} to clipboard'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _pickImageAndProcess({ImageSource source = ImageSource.gallery}) async {
    final image = await _pickImage(source: source);
    if (image != null) {
      final inputImage = InputImage.fromFile(image);
      _displayImage(image);

      final parsedValues = await _recognizedNumbers(image, inputImage);
      _displayResults(parsedValues);
    }
  }

  void _displayResults(Iterable<double> parsedValues) {
    setState(() {
      _detectedNumbers = parsedValues;
    });
  }

  void _displayImage(File image) {
    setState(() {
      _selectedImage = image;
    });
  }

  Future<Iterable<double>> _recognizedNumbers(
      File image, InputImage inputImage) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final recognizedText = await textRecognizer.processImage(inputImage);

    String text = recognizedText.text;
    RegExp regex = RegExp(r'\b\d+(\.\d+)?\b');
    final parsedValues = regex
        .allMatches(text.replaceAll(',', ''))
        .map((regex) =>
            regex.group(0) != null ? double.parse(regex.group(0)!) : null)
        .whereNotNull();

    for (TextBlock block in recognizedText.blocks) {
      // final rect = block.boundingBox;
      // final cornerPoints = block.cornerPoints;
      // final text = block.text;
      // final languages = block.recognizedLanguages;

      // for (TextLine line in block.lines) {
      //   // Same getters as TextBlock
      //   for (TextElement element in line.elements) {
      //     // Same getters as TextBlock
      //     finalText +=', ${element.text}';
      //   }
      // }
    }
    return parsedValues;
  }

  Future<File?> _pickImage({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  double _calculateAverage() {
    return _calculateSum() / (_detectedNumbers?.length ?? 1);
  }

  double _calculateSum() {
    if (_detectedNumbers == null || _detectedNumbers?.isEmpty == true) {
      return 0;
    }
    return _detectedNumbers?.reduce((a, b) => a + b) ?? 0;
  }
}
