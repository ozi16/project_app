import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class MyClient extends StatefulWidget {
  const MyClient({super.key});

  @override
  State<MyClient> createState() => _MyClientState();
}

class _MyClientState extends State<MyClient> {
  List<dynamic> allClients = [];
  List<dynamic> filteredData = [];
  Future<List<dynamic>>? futureClients;
  final TextEditingController searchController = TextEditingController();

  bool isSearching = false;

  static const _iconPalette = [
    (Color(0xFF2196F3), Color(0xFFE3F2FD)),
    (Color(0xFF4CAF50), Color(0xFFE8F5E9)),
    (Color(0xFFFFC107), Color(0xFFFFF8E1)),
    (Color(0xFF9C27B0), Color(0xFFF3E5F5)),
    (Color(0xFFE91E63), Color(0xFFFCE4EC)),
    (Color(0xFF009688), Color(0xFFE0F2F1)),
  ];

  @override
  void initState() {
    super.initState();
    futureClients = fetchClient();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> fetchClient() async {
    try {
      final data = await ApiService.getClient();

      setState(() {
        allClients = data;
        filteredData = data;
      });

      return data;
    } catch (e) {
      debugPrint('ERROR fetchClient: $e');
      return [];
    }
  }

  void _search(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      if (lowerQuery.isEmpty) {
        isSearching = false;
        filteredData = allClients;
      } else {
        isSearching = true;
        filteredData = allClients.where((item) {
          final name = item['nama_client']?.toString().toLowerCase() ?? '';
          final location = _clientLocation(item).toLowerCase();
          return name.contains(lowerQuery) || location.contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _refresh() async {
    final data = await fetchClient();
    setState(() {
      futureClients = Future.value(data);
    });
  }

  String _clientLocation(Map data) {
    final kota = data['kota'] ?? data['city'] ?? '';
    final provinsi = data['provinsi'] ?? data['province'] ?? '';
    final parts = [
      kota,
      provinsi,
    ].map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');

    final alamat = data['alamat']?.toString().trim() ?? '';
    if (alamat.isNotEmpty) return alamat;

    return data['client_irl']?.toString() ?? '-';
  }

  String _clientDate(Map data) {
    final raw =
        data['last_visit'] ??
        data['tanggal'] ??
        data['created_at'] ??
        data['updated_at'];
    if (raw == null) return '-';

    final parsed = DateTime.tryParse(raw.toString())?.toLocal();
    if (parsed == null) return raw.toString();
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _clientVisitCount(Map data) {
    final count =
        data['jumlah_kunjungan'] ??
        data['total_kunjungan'] ??
        data['kunjungan'] ??
        data['visit_count'];
    if (count == null) return '0 Kunjungan';
    return '$count Kunjungan';
  }

  Widget _buildClientCard(Map data, int index) {
    final (iconColor, bgColor) = _iconPalette[index % _iconPalette.length];
    final name = data['nama_client']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.business, color: iconColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _clientLocation(data),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _clientDate(data),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '|',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                    Icon(
                      Icons.assignment_outlined,
                      size: 13,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _clientVisitCount(data),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueAppBar({
    required String title,
    required VoidCallback onFilter,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: searchController,
                  onChanged: _search,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Cari nama client atau lokasi...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: _buildBlueAppBar(title: 'My Client', onFilter: () {}),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: futureClients,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Data client kosong',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  final dataList = isSearching ? filteredData : snapshot.data!;

                  if (dataList.isEmpty) {
                    return Center(
                      child: Text(
                        'Client tidak ditemukan',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: dataList.length,
                      itemBuilder: (context, index) {
                        final data = dataList[index] as Map;
                        return InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(14),
                          child: _buildClientCard(data, index),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
