import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/constants/app_responsive.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/task_completion_cache.dart';
import 'package:teknisi_aag/services/api_service.dart';

class CheckOut extends StatefulWidget {
  const CheckOut({super.key, required this.taskId, required this.clientId});
  final int taskId;
  final int clientId;
  @override
  State<CheckOut> createState() => _CheckOutState();
}

class _CheckOutState extends State<CheckOut> {
  String _koordinat = '-';
  String _alamatNyata = 'Ambil foto untuk mendapatkan lokasi.';

  File? _image;
  Position? _position;
  final ImagePicker _picker = ImagePicker();
  bool _memuatAlamat = false;
  bool _lokasiBerhasil = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  String _formatAlamat(Placemark p) {
    final seen = <String>{};
    final parts = <String>[];

    for (final raw in [
      p.street,
      p.thoroughfare,
      p.subLocality,
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
    ]) {
      if (raw == null) continue;
      final s = raw.trim();
      if (s.isEmpty || seen.contains(s)) continue;
      seen.add(s);
      parts.add(s);
    }

    return parts.isEmpty ? 'Alamat tidak tersedia' : parts.join(', ');
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return 'Alamat tidak ditemukan untuk koordinat ini.';
      }
      return _formatAlamat(placemarks.first);
    } catch (_) {
      return 'Koordinat berhasil didapat, namun alamat gagal dimuat.';
    }
  }

  /// ========================
  /// CAMERA
  /// ========================
  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });

        await _ambilLokasiDanAlamat();
      } else {
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  Future<void> _ambilLokasiDanAlamat() async {
    if (!mounted) return;

    setState(() {
      _memuatAlamat = true;
      _lokasiBerhasil = false;
      _alamatNyata = 'Sedang mendeteksi lokasi Anda...';
      _koordinat = '-';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'GPS HP Anda nonaktif. Aktifkan GPS terlebih dahulu.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Aplikasi tidak diizinkan mengakses lokasi.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen. Aktifkan di pengaturan HP.';
      }

      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (posisi.isMocked) {
        throw 'Fake GPS terdeteksi. Matikan aplikasi lokasi palsu.';
      }

      final alamat = await _reverseGeocode(posisi.latitude, posisi.longitude);
      final koordinat =
          '${posisi.latitude.toStringAsFixed(6)}, ${posisi.longitude.toStringAsFixed(6)}';

      if (!mounted) return;
      setState(() {
        _position = posisi;
        _koordinat = koordinat;
        _alamatNyata = alamat;
        _lokasiBerhasil = true;
        _memuatAlamat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _position = null;
        _koordinat = '-';
        _alamatNyata = e.toString();
        _lokasiBerhasil = false;
        _memuatAlamat = false;
      });
    }
  }

  Widget _buildKartuLokasi() {
    return Container(
      width: AppSizes.screenWidth(context),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _lokasiBerhasil ? Colors.green.shade400 : AppColors.primary,
        ),
        borderRadius: BorderRadius.circular(15),
        color: _lokasiBerhasil ? Colors.green.shade50 : null,
      ),
      child: _memuatAlamat
          ? const Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sedang mendeteksi lokasi...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: _lokasiBerhasil ? Colors.green : Colors.redAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lokasiBerhasil ? 'Lokasi Terdeteksi' : 'Lokasi',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      if (_lokasiBerhasil) ...[
                        const SizedBox(height: 4),
                        Text(
                          _koordinat,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _alamatNyata,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: _lokasiBerhasil
                              ? Colors.black87
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// ========================
  /// UPLOAD CHECKOUT
  /// ========================
  Future<void> _uploadCheckOut() async {
    if (_isLoading) return;

    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto belum ada')));
      return;
    }

    if (_position == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lokasi belum didapat')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      int clientId = widget.clientId;
      int taskId = widget.taskId;

      final bytes = await _image!.readAsBytes();
      String base64Image = base64Encode(bytes);

      String lat = _position!.latitude.toString();
      String long = _position!.longitude.toString();

      bool success = await ApiService.sendCheckOut(
        clientId: clientId,
        taskId: taskId,
        info: "OUT",
        base64Image: base64Image,
        lat: lat,
        long: long,
      );

      if (!mounted) return;

      if (success) {
        await BerandaTaskCompletionCache.markClientCompleted(clientId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check-Out berhasil')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal upload')));
      }
    } catch (e) {
      debugPrint("ERROR: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ========================
  /// UI
  /// ========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          'Check-Out Kamera',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _image == null
                  ? const Center(child: Text('Membuka kamera...'))
                  : Image.file(_image!),
            ),

            _buildKartuLokasi(),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _uploadCheckOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Kirim Check-Out',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _memuatAlamat || _isLoading ? null : _openCamera,
              child: const Text(
                'Ambil Ulang Foto',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
