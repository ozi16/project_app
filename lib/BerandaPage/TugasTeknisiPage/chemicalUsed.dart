import 'package:flutter/material.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class ChemicalModel {
  final int id;
  final String nama_pps;
  final String bahan;
  final String dosis;
  final String metode;

  ChemicalModel({
    required this.id,
    required this.nama_pps,
    required this.bahan,
    required this.dosis,
    required this.metode,
  });

  factory ChemicalModel.fromJson(Map<String, dynamic> json) {
    return ChemicalModel(
      id: int.tryParse('${json['id'] ?? json['chemical_id']}') ?? 0,
      nama_pps: json['nama_pps']?.toString() ?? '',
      bahan: json['bahan']?.toString() ?? '',
      dosis: json['dosis']?.toString() ?? '',
      metode: json['metode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'chemical_id': id};
  }

  String get subtitle {
    final parts = <String>[];
    if (dosis.trim().isNotEmpty) parts.add(dosis.trim());
    if (metode.trim().isNotEmpty) parts.add(metode.trim());
    return parts.isEmpty ? '-' : parts.join(' • ');
  }
}

class _ChemicalAccent {
  final Color color;
  final Color background;

  const _ChemicalAccent({required this.color, required this.background});
}

const _chemicalAccents = [
  _ChemicalAccent(color: Color(0xFF1565C0), background: Color(0xFFE3F2FD)),
  _ChemicalAccent(color: Color(0xFF2E7D32), background: Color(0xFFE8F5E9)),
  _ChemicalAccent(color: Color(0xFF6A1B9A), background: Color(0xFFF3E5F5)),
  _ChemicalAccent(color: Color(0xFFEF6C00), background: Color(0xFFFFF3E0)),
  _ChemicalAccent(color: Color(0xFF00838F), background: Color(0xFFE0F7FA)),
];

class ChemicalUsedPage extends StatefulWidget {
  final int taskId;

  const ChemicalUsedPage({super.key, required this.taskId});

  @override
  State<ChemicalUsedPage> createState() => _ChemicalUsedPageState();
}

class _ChemicalUsedPageState extends State<ChemicalUsedPage> {
  final TextEditingController _searchController = TextEditingController();

  List<ChemicalModel> allChemical = [];
  List<ChemicalModel> filteredChemical = [];
  List<ChemicalModel> selectedChemical = [];

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchChemical();
  }

  Future<void> fetchChemical() async {
    try {
      final data = await ApiService.getChemicalUsed();

      if (!mounted) return;
      setState(() {
        allChemical =
            data.map<ChemicalModel>((e) => ChemicalModel.fromJson(e)).toList();
        filteredChemical = allChemical;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void addChemical(ChemicalModel item) {
    if (selectedChemical.any((e) => e.id == item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chemical sudah ditambahkan')),
      );
      return;
    }

    setState(() => selectedChemical.add(item));
  }

  void removeChemical(int index) {
    setState(() => selectedChemical.removeAt(index));
  }

  void searchChemical(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        filteredChemical = allChemical;
        return;
      }

      filteredChemical = allChemical.where((item) {
        return item.nama_pps.toLowerCase().contains(q) ||
            item.dosis.toLowerCase().contains(q) ||
            item.bahan.toLowerCase().contains(q);
      }).toList();
    });
  }

  _ChemicalAccent _accentForIndex(int index) {
    return _chemicalAccents[index % _chemicalAccents.length];
  }

  Future<void> _showAddChemicalSheet() async {
    if (allChemical.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data chemical belum tersedia')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pilih Chemical',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: allChemical.length,
                    itemBuilder: (context, index) {
                      final item = allChemical[index];
                      final alreadyAdded =
                          selectedChemical.any((e) => e.id == item.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildChemicalCard(
                          item: item,
                          accent: _accentForIndex(index),
                          isUsedSection: false,
                          onAction: alreadyAdded
                              ? null
                              : () {
                                  addChemical(item);
                                  Navigator.pop(ctx);
                                },
                          actionIcon: alreadyAdded
                              ? Icons.check_rounded
                              : Icons.add_rounded,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> submitData() async {
    if (selectedChemical.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih chemical dulu!')),
      );
      return;
    }

    if (selectedChemical.any((e) => e.id == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ada data ID tidak valid!')),
      );
      return;
    }

    setState(() => isSaving = true);

    final items = selectedChemical.map((e) => e.toJson()).toList();
    debugPrint('SEND BODY: $items');

    final success = await ApiService.sendChemical(
      widget.taskId,
      taskName: 'CHEMICAL',
      items,
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submit berhasil')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submit gagal')),
      );
    }
  }

  Widget _buildChemicalCard({
    required ChemicalModel item,
    required _ChemicalAccent accent,
    required bool isUsedSection,
    VoidCallback? onAction,
    IconData actionIcon = Icons.add_rounded,
  }) {
    final actionColor = isUsedSection ? AppColors.danger : accent.color;
    final actionBg = isUsedSection
        ? AppColors.danger.withValues(alpha: 0.12)
        : accent.background;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.science_outlined,
              color: accent.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama_pps,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: actionBg,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onAction,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Chemical Used',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: searchChemical,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search chemical...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade500,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChemicalListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Chemical List',
        ),
        if (filteredChemical.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Text(
                allChemical.isEmpty
                    ? 'Data chemical tidak tersedia'
                    : 'Chemical tidak ditemukan',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          )
        else
          ...List.generate(filteredChemical.length, (index) {
            final item = filteredChemical[index];
            final alreadyAdded =
                selectedChemical.any((e) => e.id == item.id);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _buildChemicalCard(
                item: item,
                accent: _accentForIndex(index),
                isUsedSection: false,
                onAction: alreadyAdded ? null : () => addChemical(item),
                actionIcon: alreadyAdded
                    ? Icons.check_rounded
                    : Icons.add_rounded,
              ),
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUsedChemicalSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        // border: Border(
        //   top: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)
        //   ),
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title: 'Used Chemical'),
          Expanded(
            child: selectedChemical.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Belum ada chemical dipilih',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: selectedChemical.length,
                    itemBuilder: (context, index) {
                      final item = selectedChemical[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildChemicalCard(
                          item: item,
                          accent: _accentForIndex(index),
                          isUsedSection: true,
                          onAction: () => removeChemical(index),
                          actionIcon: Icons.delete_outline_rounded,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : submitData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.secondary.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: _buildChemicalListSection(),
          ),
        ),
        Expanded(
          flex: 2,
          child: _buildUsedChemicalSection(),
        ),
        _buildSubmitButton(),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }
}
