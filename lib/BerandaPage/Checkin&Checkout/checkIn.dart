import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/detailtask.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/constants/app_responsive.dart';
import 'package:teknisi_aag/services/api_service.dart';
import 'package:geocoding/geocoding.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key, required this.id_cli});

  final int id_cli;

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
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

    /// 🔥 langsung buka kamera setelah UI ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  /// Gabungkan bagian placemark yang valid, hindari null/duplikat.
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
        imageQuality: 50, // 🔥 compress biar ringan
      );

      if (photo != null) {
        setState(() {
          _image = File(photo.path);
        });

        await _ambilLokasiDanAlamat();
      } else {
        /// kalau user cancel kamera → balik
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  int? _parsePositiveId(dynamic raw) {
    if (raw == null) return null;
    final id = int.tryParse('$raw');
    if (id == null || id <= 0) return null;
    return id;
  }

  Map<String, dynamic>? _taskDataFromMap(Map<String, dynamic> map) {
    final taskId =
        _parsePositiveId(map['task_id']) ?? _parsePositiveId(map['id']);
    if (taskId == null) return null;

    return {
      'task_id': taskId,
      'client_id':
          _parsePositiveId(map['client_id']) ?? widget.id_cli,
      'absen_in': map['absen_in']?.toString() ?? '',
      'tugas': map['tugas'] == null
          ? null
          : int.tryParse('${map['tugas']}'),
      'sign_in': map['sign_in']?.toString(),
    };
  }

  Map<String, dynamic>? _taskDataFromResponse(Map<String, dynamic> body) {
    final nested = body['data'];
    if (nested is Map) {
      final fromNested =
          _taskDataFromMap(Map<String, dynamic>.from(nested));
      if (fromNested != null) return fromNested;
    }
    return _taskDataFromMap(body);
  }

  Future<Map<String, dynamic>?> _fetchActiveVisitTask() async {
    final res = await ApiService.cekKondisiTask();
    final data = res['data'];
    if (data is! Map) return null;
    return _taskDataFromMap(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>?> _resolveTaskDataAfterCheckin(
    Map<String, dynamic>? checkinBody,
  ) async {
    if (checkinBody != null) {
      final fromCheckin = _taskDataFromResponse(checkinBody);
      if (fromCheckin != null) return fromCheckin;
    }

    for (var attempt = 0; attempt < 6; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        final fromApi = await _fetchActiveVisitTask();
        if (fromApi != null) return fromApi;
      } catch (_) {}
    }

    final box = await Hive.openBox('checkinBox');
    if (box.isEmpty) return null;

    final lastData = box.getAt(box.length - 1);
    if (lastData is! Map) return null;

    final taskId = _parsePositiveId(lastData['task_id']);
    if (taskId == null) return null;

    return {
      'task_id': taskId,
      'client_id': widget.id_cli,
      'absen_in': '',
      'tugas': null,
      'sign_in': null,
    };
  }

  Future<void> _goToDetailTask(Map<String, dynamic> data) async {
    var taskId = int.tryParse('${data['task_id']}') ?? 0;
    final clientId =
        int.tryParse('${data['client_id']}') ?? widget.id_cli;

    if (taskId <= 0) {
      try {
        final retry = await _fetchActiveVisitTask();
        if (retry != null) {
          taskId = int.tryParse('${retry['task_id']}') ?? 0;
          data = retry;
        }
      } catch (_) {}
    }

    if (taskId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in berhasil, tetapi task belum tersedia'),
        ),
      );
      Navigator.pop(context, false);
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DetailTask(
          taskId: taskId,
          clientId: clientId,
          absenIn: data['absen_in']?.toString() ?? '',
          tugas: data['tugas'] == null
              ? null
              : int.tryParse('${data['tugas']}'),
          signIn: data['sign_in']?.toString(),
        ),
      ),
    );
  }

  /// ========================
  /// UPLOAD CHECKIN
  /// ========================
  Future<void> _uploadCheckin() async {
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
      final box = Hive.box('loginBox');
      String token = box.get('token', defaultValue: "");
      int clientId = widget.id_cli;
      /// Convert image ke base64
      final bytes = await _image!.readAsBytes();
      String base64Image = base64Encode(bytes);

      /// Convert lat long ke STRING (sesuai backend)
      String lat = _position!.latitude.toString();
      String long = _position!.longitude.toString();

      print("=== DEBUG CHECKIN ===");
      print("lat: $lat");
      print("long: $long");
      print("image length: ${base64Image.length}");
      final checkinBody = await ApiService.sendCheckin(
        clientId: clientId,
        info: "IN",
        base64Image: base64Image,
        lat: lat,
        long: long,
        token: token,
      );

      if (!mounted) return;

      if (checkinBody != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check-in berhasil')));

        final taskData = await _resolveTaskDataAfterCheckin(checkinBody);
        if (taskData != null) {
          await _goToDetailTask(taskData);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in berhasil, buka tugas dari beranda'),
            ),
          );
          Navigator.pop(context, false);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Masih ada visit aktif')));
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




  /// =========================
  /// PROSES ABSEN + TRACK GPS
  /// =========================

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
          'Check-in Kamera',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PREVIEW FOTO
            Expanded(
              child: _image == null
                  ? const Center(child: Text('Membuka kamera...'))
                  : Image.file(_image!),
            ),

            _buildKartuLokasi(),

            const SizedBox(height: 20),

            /// BUTTON CHECKIN
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadCheckin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Kirim Check-in',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),

            const SizedBox(height: 10),

            /// RETAKE
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
