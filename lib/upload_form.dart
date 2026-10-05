import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadForm extends StatefulWidget {
  const UploadForm({super.key});

  @override
  _UploadFormState createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Gambar'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image == null
                ? Text('Tidak ada gambar yang dipilih.')
                : Image.file(_image!, height: 200, width: 200),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: Text('Pilih dari Galeri'),
            ),
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: Text('Ambil dari Kamera'),
            ),
            if (_image != null)
              ElevatedButton(
                onPressed: () {
                  // Logika upload gambar di sini
                  // Misalnya, kirim ke server menggunakan http package
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gambar berhasil diupload!')),
                  );
                },
                child: Text('Upload Gambar'),
              ),
          ],
        ),
      ),
    );
  }
}