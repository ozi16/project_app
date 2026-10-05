import 'package:flutter/material.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class PestModel {
  final int id;
  final String nama_pest;

  PestModel({required this.id, required this.nama_pest});

  factory PestModel.fromJson(Map<String, dynamic> json) {
    return PestModel(id: json['id'], nama_pest: json['nama_pest'] ?? '');
  }
}

class TrapModel {
  final int id;
  final String nama_device;

  TrapModel({required this.id, required this.nama_device});

  factory TrapModel.fromJson(Map<String, dynamic> json) {
    return TrapModel(id: json['id'], nama_device: json['nama_device'] ?? '');
  }
}

class Checklistpage extends StatefulWidget {
  final int taskId;

  const Checklistpage({super.key, required this.taskId});

  @override
  State<Checklistpage> createState() => _ChecklistpageState();
}

class _ChecklistpageState extends State<Checklistpage> {
  List<Map<String, dynamic>> areaList = [];
  List<PestModel> allPest = [];
  List<TrapModel> allTrap = [];

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    tambahArea();
    fetchAll();
  }

  Future<void> fetchAll() async {
    try {
      final pestData = await ApiService.getPest();
      final trapData = await ApiService.getTrap();

      if (!mounted) return;
      setState(() {
        allPest = pestData.map<PestModel>((e) => PestModel.fromJson(e)).toList();
        allTrap = trapData.map<TrapModel>((e) => TrapModel.fromJson(e)).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void tambahArea() {
    setState(() {
      areaList.add({
        'area': TextEditingController(),
        'data': [buatDataBaru()],
      });
    });
  }

  void hapusArea(int index) {
    if (areaList.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 area')),
      );
      return;
    }
    setState(() {
      final area = areaList.removeAt(index);
      area['area'].dispose();
      for (final data in area['data']) {
        data['qty'].dispose();
        data['note'].dispose();
      }
    });
  }

  Map<String, dynamic> buatDataBaru() {
    return {
      'equipment': null,
      'pest': null,
      'qty': TextEditingController(),
      'note': TextEditingController(),
    };
  }

  void tambahData(int areaIndex) {
    setState(() {
      areaList[areaIndex]['data'].add(buatDataBaru());
    });
  }

  void hapusData(int areaIndex, int dataIndex) {
    final dataList = areaList[areaIndex]['data'] as List;
    if (dataList.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 data per area')),
      );
      return;
    }
    setState(() {
      final data = dataList.removeAt(dataIndex);
      data['qty'].dispose();
      data['note'].dispose();
    });
  }

  Future<void> fetchsimpan() async {
    setState(() => isSaving = true);

    try {
      final dataArea = <Map<String, dynamic>>[];

      for (final area in areaList) {
        final namaArea = (area['area'] as TextEditingController).text.trim();
        if (namaArea.isEmpty) continue;

        final items = <Map<String, dynamic>>[];

        for (final data in area['data']) {
          if (data['equipment'] == null || data['pest'] == null) continue;

          items.add({
            'device_id': data['equipment'],
            'hama_id': data['pest'],
            'qty': int.tryParse(data['qty'].text) ?? 0,
            'note': data['note'].text,
          });
        }

        if (items.isNotEmpty) {
          dataArea.add({'nama_area': namaArea, 'items': items});
        }
      }

      if (dataArea.isEmpty) {
        throw Exception('Data kosong');
      }

      await ApiService.sendChecklist(
        taskId: widget.taskId,
        taskName: 'CHECKLIST',
        data: dataArea,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dikirim')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERROR: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal kirim data')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {bool required = false}) {
    return InputDecoration(
      label: _fieldLabel(label, required: required),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _fieldDecoration(label, required: required),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
    bool required = false,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      hint: Text(
        'Pilih $label',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
      decoration: _fieldDecoration(label, required: required),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildDeleteButton({required VoidCallback onPressed}) {
    return Material(
      color: AppColors.danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.delete_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard(int areaIndex, int dataIndex) {
    final area = areaList[areaIndex];
    final data = area['data'][dataIndex];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data ${dataIndex + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildDeleteButton(
                onPressed: () => hapusData(areaIndex, dataIndex),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'Equipment',
            required: true,
            value: allTrap.any((t) => t.id == data['equipment'])
                ? data['equipment']
                : null,
            items: allTrap
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.nama_device),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => data['equipment'] = val),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdown(
                  label: 'Pilih Posisi',
                  required: true,
                  value: allPest.any((p) => p.id == data['pest'])
                      ? data['pest']
                      : null,
                  items: allPest
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.nama_pest),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => data['pest'] = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  'Qty',
                  data['qty'],
                  required: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('Note', data['note'], maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildAreaCard(int areaIndex) {
    final area = areaList[areaIndex];
    final dataList = area['data'] as List;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 22,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Area ${areaIndex + 1}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildDeleteButton(onPressed: () => hapusArea(areaIndex)),
            ],
          ),
          const SizedBox(height: 14),
          _buildTextField('Nama Area', area['area'], required: true),
          const SizedBox(height: 14),
          ...List.generate(
            dataList.length,
            (dataIndex) => _buildDataCard(areaIndex, dataIndex),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => tambahData(areaIndex),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                '+ Data',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryBottomButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _saveBottomButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : tambahArea,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                '+ Area',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: _primaryBottomButtonStyle(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : fetchsimpan,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 20),
              label: Text(
                isSaving ? 'Menyimpan...' : 'Simpan Data',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: _saveBottomButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final area in areaList) {
      area['area'].dispose();
      for (final data in area['data']) {
        data['qty'].dispose();
        data['note'].dispose();
      }
    }
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
          'Checklist',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      color: const Color(0xFFF5F7FA),
                      child: Text(
                        'Isi data checklist sesuai dengan area dan '
                        'equipment yang digunakan.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            ...List.generate(
                              areaList.length,
                              (i) => _buildAreaCard(i),
                            ),
                            const SizedBox(height: 140),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _buildBottomActions(),
                ),
                if (isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
              ],
            ),
    );
  }
}
