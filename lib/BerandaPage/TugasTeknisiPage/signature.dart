import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:teknisi_aag/services/api_service.dart';

class SignaturePage extends StatefulWidget {
  final int taskId;

  const SignaturePage({super.key, required this.taskId});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool get isFormValid => _savedSignature != null && _stampImage != null;
  File? _savedSignature;
  File? _stampImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  /// CLEAR SIGNATURE
  void _clearSignature() {
    _signaturePadKey.currentState?.clear();
    setState(() {
      _savedSignature = null;
    });
  }

  /// SAVE SIGNATURE

  Future<void> _saveSignature() async {
    final image = await _signaturePadKey.currentState!.toImage(pixelRatio: 3.0);

    /// ambil PNG bytes dari canvas
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/signature.jpg';

    /// 🔥 CONVERT PNG → JPEG (INI YANG PENTING)
    final jpegBytes = await FlutterImageCompress.compressWithList(
      pngBytes,
      format: CompressFormat.jpeg,
      quality: 90,
    );

    if (jpegBytes == null) {
      throw Exception("Gagal convert ke JPEG");
    }

    final file = File(path);
    await file.writeAsBytes(jpegBytes);

    setState(() {
      _savedSignature = file;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tanda tangan berhasil disimpan")),
    );
  }

  /// PICK IMAGE FROM CAMERA
  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final tempDir = await getTemporaryDirectory();
      final newPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final newFile = await File(image.path).copy(newPath);

      setState(() {
        _stampImage = newFile;
      });
    }
  }

  /// PICK IMAGE FROM GALLERY
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _stampImage = File(image.path);
      });
    }
  }

  /// SUBMIT DATA
  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Peringatan"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<String> _fileToBase64(File file) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 55,
      minWidth: 800,
      minHeight: 800,
    );
    final bytes = compressed ?? await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  void _submit() async {
    if (_savedSignature == null) {
      _showAlert("Silakan tanda tangan terlebih dahulu");
      return;
    }

    if (_stampImage == null) {
      _showAlert("Silakan tambahkan stempel terlebih dahulu");
      return;
    }

    setState(() => _isLoading = true);

    // Munculkan Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Konversi ke Base64 menggunakan fungsi lokal yang sudah Anda buat
      // Ini lebih aman karena kita tahu fungsi _fileToBase64 menerima File
      final String signatureBase64 = await _fileToBase64(_savedSignature!);
      final String stampBase64 = await _fileToBase64(_stampImage!);

      // 2. Kirim ke API
      await ApiService.sendSignature(
        taskId: widget.taskId,
        photo: signatureBase64,
        stamp: stampBase64,
      );

      // 3. Jika berhasil, tutup loading dialog
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil kirim tanda tangan")),
      );

      await Future.delayed(const Duration(seconds: 1));

      // 4. Navigasi ke HomePage
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Tutup loading dialog jika error
      if (mounted) Navigator.pop(context);

      // Tampilkan error yang lebih manusiawi
      _showAlert("Gagal upload: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tanda Tangan & Stempel"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// SIGNATURE PAD
            Container(
              margin: const EdgeInsets.all(16),
              height: 300,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: SfSignaturePad(
                key: _signaturePadKey,
                backgroundColor: Colors.white,
                strokeColor: Colors.black,
                minimumStrokeWidth: 2.0,
                maximumStrokeWidth: 4.0,
              ),
            ),

            /// BUTTON SIGNATURE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _clearSignature,
                  child: const Text("Clear"),
                ),
                ElevatedButton(
                  onPressed: _saveSignature,
                  child: const Text("Simpan"),
                ),
                ElevatedButton(
                  onPressed: (isFormValid && !_isLoading) ? _submit : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Submit"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// BUTTON IMAGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickFromCamera,
                  child: const Text("Foto Stempel"),
                ),
                ElevatedButton(
                  onPressed: _pickFromGallery,
                  child: const Text("Dari Galeri"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// PREVIEW SIGNATURE
            if (_savedSignature != null) ...[
              const Text("Preview Tanda Tangan"),
              const SizedBox(height: 10),
              Image.file(_savedSignature!, height: 150),
            ],

            const SizedBox(height: 20),

            /// PREVIEW STAMP
            if (_stampImage != null) ...[
              const Text("Preview Stempel"),
              const SizedBox(height: 10),
              Image.file(_stampImage!, height: 150),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
