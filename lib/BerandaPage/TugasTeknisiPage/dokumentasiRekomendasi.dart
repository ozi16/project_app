import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/dokumentasiTreatment.dart'
    show CameraPage, DashedBorderContainer, DokumentasiItem, DokumentasiPreviewPage;
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class DokumentasiRekomendasi extends StatefulWidget {
  final int taskId;

  const DokumentasiRekomendasi({super.key, required this.taskId});

  @override
  State<DokumentasiRekomendasi> createState() => _DokumentasiRekomendasiState();
}

class _DokumentasiRekomendasiState extends State<DokumentasiRekomendasi> {
  static const _maxKeterangan = 1000;

  XFile? _imageFile;
  final TextEditingController _keteranganController = TextEditingController();

  List<DokumentasiItem> dokumentasiList = [];

  double uploadProgress = 0;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<Box> getBox() async {
    return Hive.isBoxOpen('dokumentasirekomendasiBox')
        ? Hive.box('dokumentasirekomendasiBox')
        : await Hive.openBox('dokumentasirekomendasiBox');
  }

  Future<void> loadData() async {
    final box = await getBox();

    final temp = <DokumentasiItem>[];

    for (var item in box.values) {
      if (File(item['imagePath']).existsSync()) {
        temp.add(
          DokumentasiItem(
            image: XFile(item['imagePath']),
            keterangan: item['keterangan'],
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => dokumentasiList = temp);
  }

  Future<void> uploadData() async {
    if (dokumentasiList.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tidak ada data')));
      return;
    }

    setState(() {
      isSaving = true;
      uploadProgress = 0;
    });

    try {
      final items = <Map<String, dynamic>>[];

      for (var item in dokumentasiList) {
        if (item.image == null) continue;

        final file = File(item.image!.path);

        if (!file.existsSync()) continue;

        var base64Image = await ApiService.convertToBase64(file);
        base64Image = 'data:image/jpeg;base64,$base64Image';

        items.add({
          'deskripsi': item.keterangan,
          'photo': base64Image,
        });
      }

      await ApiService.sendRekomendasi(
        taskId: widget.taskId,
        taskName: 'AKSES',
        items: items,
      );

      final box = await getBox();
      await box.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload berhasil')));

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERROR: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload gagal')));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _ambilFoto() async {
    if (isSaving) return;

    final result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );

    if (result != null && mounted) {
      setState(() => _imageFile = result);
    }
  }

  Future<void> _tambahDokumentasi() async {
    if (_imageFile == null || _keteranganController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto & keterangan wajib diisi')),
      );
      return;
    }

    final box = await getBox();

    await box.add({
      'imagePath': _imageFile!.path,
      'keterangan': _keteranganController.text.trim(),
    });

    setState(() {
      dokumentasiList.add(
        DokumentasiItem(
          image: _imageFile,
          keterangan: _keteranganController.text.trim(),
        ),
      );

      _imageFile = null;
      _keteranganController.clear();
    });
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dokumentasi Rekomendasi'),
        content: const Text(
          'Ambil foto kondisi akses atau area yang direkomendasikan. '
          'Tambahkan keterangan, lalu kirim ke database saat koneksi tersedia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmHapusDokumentasi(int index) async {
    if (index < 0 || index >= dokumentasiList.length) return false;

    final item = dokumentasiList[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumentasi'),
        content: Text(
          'Yakin ingin menghapus dokumentasi ini?\n\n"${item.keterangan}"\n\n'
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    await _hapusDokumentasi(index);

    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dokumentasi berhasil dihapus')),
    );
    return true;
  }

  Future<void> _hapusDokumentasi(int index) async {
    if (index < 0 || index >= dokumentasiList.length) return;

    final item = dokumentasiList[index];
    final imagePath = item.image?.path;

    final box = await getBox();

    dynamic keyToDelete;
    for (final key in box.keys) {
      final val = box.get(key);
      if (val is Map && val['imagePath'] == imagePath) {
        keyToDelete = key;
        break;
      }
    }
    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }

    if (imagePath != null) {
      final file = File(imagePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }

    if (!mounted) return;
    setState(() => dokumentasiList.removeAt(index));
  }

  void _previewDokumentasi(int index) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DokumentasiPreviewPage(
          items: dokumentasiList,
          initialIndex: index,
          onDeleteRequest: (imagePath) async {
            final idx = dokumentasiList.indexWhere(
              (e) => e.image?.path == imagePath,
            );
            if (idx < 0) return false;
            return _confirmHapusDokumentasi(idx);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Dokumentasi Rekomendasi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: _showInfoDialog,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFotoSection(),
            const SizedBox(height: 16),
            _buildTipsBox(),
            const SizedBox(height: 20),
            _buildKeteranganSection(),
            const SizedBox(height: 20),
            _buildTambahButton(),
            if (dokumentasiList.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildDokumentasiTersimpan(),
            ],
            const SizedBox(height: 20),
            _buildDatabaseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Dokumentasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ambil foto kondisi akses atau area yang direkomendasikan.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _ambilFoto,
          child: DashedBorderContainer(
            borderRadius: 12,
            color: AppColors.primary.withValues(alpha: 0.45),
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ganti Foto',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ambil Foto',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tekan untuk mengambil foto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tips',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pastikan foto jelas, fokus, dan pencahayaan cukup '
                  'agar dokumentasi mudah dipahami.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeteranganSection() {
    final charCount = _keteranganController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keterangan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _keteranganController,
          maxLines: 5,
          maxLength: _maxKeterangan,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tuliskan keterangan rekomendasi...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$charCount/$_maxKeterangan',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildTambahButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : _tambahDokumentasi,
        icon: const Icon(Icons.note_add_rounded, size: 20),
        label: const Text(
          'Tambah Dokumentasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDokumentasiTersimpan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dokumentasi Tersimpan (${dokumentasiList.length})',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dokumentasiList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = dokumentasiList[i];
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _previewDokumentasi(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.file(
                            File(item.image!.path),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              color: Colors.black54,
                              child: Text(
                                item.keterangan,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => _confirmHapusDokumentasi(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatabaseCard() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSaving ? null : uploadData,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined, size: 24),
            label: Text(
              isSaving ? 'Mengirim...' : 'Kirim ke Database',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (isSaving) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: uploadProgress > 0 ? uploadProgress : null,
              backgroundColor: AppColors.secondary,
              color: AppColors.secondary,
              minHeight: 4,
            ),
          ),
        ],
      ],
    );
  }
}
