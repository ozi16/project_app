import 'package:flutter/material.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class Absensi extends StatefulWidget {
  const Absensi({super.key});

  @override
  State<Absensi> createState() => _AbsensiState();
}

class _AbsensiState extends State<Absensi> {
  bool _isLoading = true;
  String? _error;
  List<_AbsensiDay> _allDays = [];
  List<_AbsensiDay> _days = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // GET API
  // ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _allDays = [];
      _days = [];
    });

    try {
      final rawList = await ApiService.getHistory();
      final records = <_AbsensiRecord>[];

      for (final raw in rawList) {
        if (raw is! Map) continue;
        records.add(_mapHistoryItem(Map<String, dynamic>.from(raw)));
      }

      if (!mounted) return;
      setState(() {
        _allDays = _groupRecordsByDate(records);
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MAPPING API → UI  (atur field yang ingin ditampilkan di sini)
  // ─────────────────────────────────────────────────────────────

  _AbsensiRecord _mapHistoryItem(Map<String, dynamic> item) {
    // Contoh field dari GET /history:
    // date_in, time_in, date_out, time_out, tgl, client.nama_client

    final client = item['client'];
    final namaClient = client is Map
        ? client['nama_client']?.toString() ?? '-'
        : item['nama_client']?.toString() ?? '-';

    final dateRaw = item['tgl'] ?? item['date_in'];
    final timeIn = item['time_in']?.toString();
    final timeOut = item['time_out']?.toString();

    return _AbsensiRecord(
      date: _parseDate(dateRaw),
      location: namaClient,
      checkInTime: _formatTime(timeIn),
      hasCheckIn: _isNotEmpty(timeIn),
      checkOutTime: _formatTime(timeOut),
      hasCheckOut: _isNotEmpty(timeOut),
      isToday: _isSameDay(_parseDate(dateRaw), DateTime.now()),
    );
  }

  List<_AbsensiDay> _groupRecordsByDate(List<_AbsensiRecord> records) {
    final grouped = <String, List<_AbsensiRecord>>{};

    for (final record in records) {
      final key = _dateKey(record.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(record);
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return keys.map((key) {
      final parts = key.split('-');
      return _AbsensiDay(
        date: DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        ),
        records: grouped[key]!,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Helper kecil (boleh diubah sesuai kebutuhan)
  // ─────────────────────────────────────────────────────────────

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    final s = raw.toString().trim();
    if (s.isEmpty) return DateTime.now();

    final parsed = DateTime.tryParse(s);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }

    if (s.length >= 10) {
      final parts = s.substring(0, 10).split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }

    return DateTime.now();
  }

  String _formatTime(String? raw) {
    if (!_isNotEmpty(raw)) return '-';
    final s = raw!.trim();
    if (s.length >= 5 && s.contains(':')) return '${s.substring(0, 5)} WIB';
    return s;
  }

  String _formatDateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isNotEmpty(String? value) {
    if (value == null) return false;
    final s = value.trim();
    return s.isNotEmpty && s != 'null';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _days = List.from(_allDays);
      return;
    }

    _days = _allDays
        .map((day) {
          final dateLabel = _formatDateLabel(day.date).toLowerCase();
          final filtered = day.records.where((record) {
            return record.location.toLowerCase().contains(query) ||
                record.checkInTime.toLowerCase().contains(query) ||
                record.checkOutTime.toLowerCase().contains(query) ||
                dateLabel.contains(query);
          }).toList();

          if (filtered.isEmpty) return null;
          return _AbsensiDay(date: day.date, records: filtered);
        })
        .whereType<_AbsensiDay>()
        .toList();
  }

  void _onSearchChanged(String _) {
    setState(_applySearch);
  }

  // Widget _buildSearchBar() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
  //     child: TextField(
  //       controller: _searchController,
  //       onChanged: _onSearchChanged,
  //       style: const TextStyle(color: Colors.black87),
  //       decoration: InputDecoration(
  //         hintText: 'Cari nama client atau tanggal...',
  //         hintStyle: TextStyle(color: Colors.grey.shade500),
  //         prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
  //         filled: true,
  //         fillColor: Colors.white,
  //         contentPadding: const EdgeInsets.symmetric(vertical: 12),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(24),
  //           borderSide: BorderSide.none,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSearchBar({
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
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Cari nama client atau tanggal...',
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

  // ─────────────────────────────────────────────────────────────
  // TAMPILAN UI
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: _buildSearchBar(title: 'Absensi', onFilter: () {}),
      ),
      body: Column(
        children: [
          // _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Gagal memuat absensi.\n$_error',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      );
    }

    if (_days.isEmpty) {
      final hasData = _allDays.isNotEmpty;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: hasData ? 80 : 120),
          Center(
            child: Text(
              hasData ? 'Data tidak ditemukan' : 'Belum ada riwayat absensi',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _days.length,
      itemBuilder: (context, index) => _buildDaySection(_days[index]),
    );
  }

  Widget _buildDaySection(_AbsensiDay day) {
    final cards = <_AbsensiCardData>[];

    for (final record in day.records) {
      cards.add(
        _AbsensiCardData(
          type: _AbsensiCardType.checkIn,
          timeText: record.hasCheckIn ? record.checkInTime : '-',
          location: record.location,
          isDone: record.hasCheckIn,
          isActive: record.isToday && record.hasCheckIn && !record.hasCheckOut,
        ),
      );
      cards.add(
        _AbsensiCardData(
          type: _AbsensiCardType.checkOut,
          timeText: record.hasCheckOut ? record.checkOutTime : '-',
          location: record.location,
          isDone: record.hasCheckOut,
          isActive: false,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                _formatDateLabel(day.date),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(cards.length, (index) {
            return _buildTimelineRow(
              card: cards[index],
              showTopLine: index > 0,
              showBottomLine: index < cards.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required _AbsensiCardData card,
    required bool showTopLine,
    required bool showBottomLine,
  }) {
    const lineColor = Color(0xFFE1E6EF);
    final isCheckIn = card.type == _AbsensiCardType.checkIn;
    final title = isCheckIn ? 'Check In' : 'Check Out';
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final dotColor = card.dotColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                if (showTopLine)
                  Container(width: 2, height: 26, color: lineColor),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (showBottomLine)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color.fromARGB(10, 0, 0, 0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: dotColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _StatusChip(
                        label: card.statusLabel,
                        bg: card.statusBg,
                        fg: card.statusFg,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.timeText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Model data (isi dari _mapHistoryItem)
// ─────────────────────────────────────────────────────────────

class _AbsensiRecord {
  final DateTime date;
  final String location;
  final String checkInTime;
  final bool hasCheckIn;
  final String checkOutTime;
  final bool hasCheckOut;
  final bool isToday;

  const _AbsensiRecord({
    required this.date,
    required this.location,
    required this.checkInTime,
    required this.hasCheckIn,
    required this.checkOutTime,
    required this.hasCheckOut,
    required this.isToday,
  });
}

class _AbsensiDay {
  final DateTime date;
  final List<_AbsensiRecord> records;

  const _AbsensiDay({required this.date, required this.records});
}

enum _AbsensiCardType { checkIn, checkOut }

class _AbsensiCardData {
  final _AbsensiCardType type;
  final String timeText;
  final String location;
  final bool isDone;
  final bool isActive;

  const _AbsensiCardData({
    required this.type,
    required this.timeText,
    required this.location,
    required this.isDone,
    required this.isActive,
  });

  Color get dotColor {
    if (type == _AbsensiCardType.checkIn) {
      return isDone ? AppColors.secondaryDark : AppColors.gray500;
    }
    return isDone ? AppColors.secondaryDark : AppColors.danger;
  }

  String get statusLabel {
    if (!isDone) return 'Belum';
    if (isActive) return 'Aktif';
    return 'Tepat Waktu';
  }

  Color get statusBg {
    if (!isDone) return const Color(0xFFECEFF1);
    return Colors.green.shade50;
  }

  Color get statusFg {
    if (!isDone) {
      return type == _AbsensiCardType.checkOut
          ? AppColors.danger
          : AppColors.gray700;
    }
    return Colors.green.shade800;
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusChip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
