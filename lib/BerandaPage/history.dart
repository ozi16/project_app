import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class HistoryModel {
  final String clientName;
  final String location;
  final String dateOut;
  final String timeOut;
  final DateTime startDate;

  HistoryModel({
    required this.clientName,
    required this.location,
    required this.dateOut,
    required this.timeOut,
    required this.startDate,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    String clientName = 'No Client';
    String location = '-';

    final client = json['client'];
    if (client is Map) {
      final clientMap = Map<String, dynamic>.from(client);
      clientName = clientMap['nama_client']?.toString() ?? clientName;

      final kota = clientMap['kota'] ?? clientMap['city'] ?? '';
      final provinsi = clientMap['provinsi'] ?? clientMap['province'] ?? '';
      final parts = [
        kota,
        provinsi,
      ].map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        location = parts.join(', ');
      } else {
        final alamat = clientMap['alamat']?.toString().trim() ?? '';
        location = alamat.isNotEmpty ? alamat : '-';
      }
    } else if (json['client_name'] != null) {
      clientName = json['client_name'].toString();
      location = json['location']?.toString() ?? '-';
    }

    final dateOut = json['date_out']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dateOut)?.toLocal() ?? DateTime.now();
    final timeOut =
        json['time_out']?.toString() ??
        '${DateFormat('HH:mm').format(parsedDate)} WIB';

    return HistoryModel(
      clientName: clientName,
      location: location,
      dateOut: dateOut,
      timeOut: timeOut,
      startDate: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_name': clientName,
      'location': location,
      'date_out': dateOut,
      'time_out': timeOut,
      'start_date': startDate.toIso8601String(),
    };
  }
}

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<HistoryModel> completedHistory = [];
  List<HistoryModel> displayedHistory = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  String? token;

  static const _iconPalette = [
    (Color(0xFF2196F3), Color(0xFFE3F2FD)),
    (Color(0xFF4CAF50), Color(0xFFE8F5E9)),
    (Color(0xFFFF9800), Color(0xFFFFF3E0)),
    (Color(0xFF9C27B0), Color(0xFFF3E5F5)),
    (Color(0xFF009688), Color(0xFFE0F2F1)),
    (Color(0xFFF44336), Color(0xFFFFEBEE)),
  ];

  @override
  void initState() {
    super.initState();
    _initializeHistory();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> getUserLogin() async {
    final box = Hive.box('loginBox');
    token = box.get('token')?.toString();
  }

  Future<Box> _openHistoryBox() async {
    if (!Hive.isBoxOpen('historyBox')) {
      return await Hive.openBox('historyBox');
    }
    return Hive.box('historyBox');
  }

  Future<bool> _loadCachedHistory() async {
    final box = await _openHistoryBox();
    final cached = box.get('completedHistory_$token');

    if (cached is List) {
      final items = cached.map<HistoryModel>((item) {
        final itemMap = Map<String, dynamic>.from(item as Map);
        return HistoryModel.fromJson(itemMap);
      }).toList();

      if (!mounted) return false;

      setState(() {
        completedHistory = items;
        displayedHistory = List.from(items);
        isLoading = false;
      });

      return true;
    }
    return false;
  }

  Future<void> _saveHistoryCache(List<HistoryModel> history) async {
    final box = await _openHistoryBox();
    final data = history.map((item) => item.toJson()).toList();
    await box.put('completedHistory_$token', data);
  }

  Future<void> _initializeHistory() async {
    await getUserLogin();
    final loaded = await _loadCachedHistory();

    if (!loaded) {
      await fetchHistory();
    }
  }

  Future<void> fetchHistory({bool forceRefresh = false}) async {
    try {
      final data = await ApiService.getHistory();

      final allHistory = data
          .map((item) => HistoryModel.fromJson(item))
          .toList();

      await _saveHistoryCache(allHistory);

      if (!mounted) return;

      setState(() {
        completedHistory = allHistory;
        displayedHistory = List.from(allHistory);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR fetchHistory: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _searchClient(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      if (lowerQuery.isEmpty) {
        displayedHistory = List.from(completedHistory);
      } else {
        displayedHistory = completedHistory
            .where(
              (item) =>
                  item.clientName.toLowerCase().contains(lowerQuery) ||
                  item.location.toLowerCase().contains(lowerQuery),
            )
            .toList();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    await fetchHistory(forceRefresh: true);
  }

  Widget _buildHistoryCard(HistoryModel item, int index) {
    final (iconColor, bgColor) = _iconPalette[index % _iconPalette.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(Icons.business, color: iconColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.clientName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8E6C9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
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
                      item.dateOut.isNotEmpty
                          ? formatDate(item.startDate)
                          : '-',
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
                      Icons.access_time,
                      size: 13,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.timeOut,
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
                  onChanged: _searchClient,
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
        child: _buildBlueAppBar(title: 'History Client', onFilter: () {}),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: Color(0xFF5C6BC0),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Riwayat Kunjungan',
                          style: TextStyle(
                            color: Color(0xFF1A237E),
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          children: [
                            const TextSpan(text: 'Total '),
                            TextSpan(
                              text: '${completedHistory.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' Client'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: displayedHistory.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada riwayat kunjungan',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          color: AppColors.primary,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: displayedHistory.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryCard(
                                displayedHistory[index],
                                index,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
