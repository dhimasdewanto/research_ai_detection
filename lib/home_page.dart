import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

/// Tambahkan path asset yang ditambahkan tadi,
/// untuk model.tflite dan juga labels.txt.
///
/// Svg hanya untuk icon dan bebas mau dipakai
/// atau tidak.
const tfLiteModelPath = "assets/model_v2.tflite"; // V2 is new generated .tflite
const tfLiteLabelPath = "assets/labels.txt";
const fruitImageAssetPath = "assets/fruits.svg";

/// 131 types of fruits and vegetables.
const classCount = 131;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _loading = false;

  /// Hasil output gambar dalam betuk byte data.
  List? _output;

  /// Hasil gambar ambil di gallery.
  File? _image;

  /// Untuk ambil gambar di gallery.
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    /// Load model di init state.
    _loadModel();
  }

  @override
  void dispose() {
    /// Close tensorflow lite ketika dispose widget.
    Tflite.close();
    super.dispose();
  }

  /// Method untuk klasifikasi jenis gambar dari hasil
  /// foto atau gallery [image].
  ///
  /// Menggunakan [Tflite] dengan model training yang
  /// tadi dimasukkan ke folder assets.
  ///
  /// Hasilnya akan dimasukkan ke dalam [_output].
  Future<void> _classifyImage(File image) async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
    });
    final output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: classCount,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _output = output;
      _loading = false;
    });
  }

  /// Untuk load model training dari assets, beserta
  /// load labelnya.
  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: tfLiteModelPath,
      labels: tfLiteLabelPath,
    );
  }

  /// Method untuk ambil gambar dari gallery / foto.
  ///
  /// Setelah selesai, proses gambar menggunakan
  /// method [_classifyImage].
  Future<void> _pickImage({
    ImageSource? source,
  }) async {
    final image = await _picker.pickImage(
      source: source ?? ImageSource.gallery,
    );
    if (image == null) {
      return;
    }
    setState(() {
      _image = File(image.path);
    });

    final currImage = _image;
    if (currImage != null) {
      await _classifyImage(currImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final output = _output;
    final image = _image;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detect Fruits and Vegetables"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Initial view.
              if (_image == null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SvgPicture.asset(
                    fruitImageAssetPath,
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                  ),
                )

              /// Apabila hasil klasifikasi gambar tidak ditemukan
              /// oleh ai.
              else if (output == null || output.isEmpty)
                Column(
                  children: [
                    SvgPicture.asset(
                      fruitImageAssetPath,
                      height: 250,
                      width: 250,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Can't Recognize",
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    )
                  ],
                )

              /// Klasifikasi gambar berhasil.
              else
                Column(
                  children: [
                    if (image != null)
                      Container(
                        height: 250,
                        child: Image.file(image),
                      ),
                    const SizedBox(height: 20),
                    if (output.isNotEmpty)
                      /// Outputnya akan diambil dari list pertama dengan key 'label'.
                      Text(
                        "${output[0]['label']}".toUpperCase(),
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      )
                  ],
                ),
              const SizedBox(height: 30),

              /// Tombol ambil foto.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () {
                  _pickImage(
                    source: ImageSource.camera,
                  );
                },
                child: const Text("Take a Photo"),
              ),
              const SizedBox(height: 10),

              /// Tombol ambil dari gallery.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () {
                  _pickImage(
                    source: ImageSource.gallery,
                  );
                },
                child: const Text("Get from Galery"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
