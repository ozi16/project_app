import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:teknisi_aag/BerandaPage/Checkin&Checkout/checkIn.dart';
import 'package:teknisi_aag/BerandaPage/Checkin&Checkout/checkOut.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/chemicalUsed.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/detailtask.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/signature.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/task_completion_cache.dart';
import 'package:teknisi_aag/BerandaPage/absensi.dart';
import 'package:teknisi_aag/BerandaPage/chemical.dart';
import 'package:teknisi_aag/BerandaPage/history.dart';
import 'package:teknisi_aag/BerandaPage/myClient.dart';
import 'package:teknisi_aag/BerandaPage/notifikasi.dart';
import 'package:teknisi_aag/BerandaPage/qrCode.dart';
import 'package:teknisi_aag/constants/app__colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class JadwalModel {
  final int id;
  final String title;
  final DateTime start_date;
  final String start_time;
  final int id_cli;

  JadwalModel({
    required this.id,
    required this.title,
    required this.start_date,
    required this.start_time,
    required this.id_cli,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    return JadwalModel(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      start_date: _parseStartDate(json['start_date']),
      start_time: json['start_time']?.toString() ?? '',
      id_cli: client != null
          ? _parseInt(client['id_cli'])
          : _parseInt(json['id_cli']),
    );
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static DateTime _parseStartDate(dynamic raw) {
    if (raw == null) return DateTime.now();

    final rawDate = raw.toString().trim();
    if (rawDate.isEmpty) return DateTime.now();

    final iso = DateTime.tryParse(rawDate);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    if (rawDate.length >= 10) {
      final parts = rawDate.substring(0, 10).split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    }

    final segments = rawDate.split(RegExp(r'[/-]'));
    if (segments.length == 3) {
      final a = int.tryParse(segments[0].trim());
      final b = int.tryParse(segments[1].trim());
      final c = int.tryParse(segments[2].trim());
      if (a != null && b != null && c != null) {
        if (a > 1000) {
          return DateTime(a, b, c);
        }
        if (c > 1000) {
          return DateTime(c, b, a);
        }
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_date': start_date.toIso8601String(),
      'start_time': start_time,
      'id_cli': id_cli,
    };
  }

  String getFormattedDate() {
    return DateFormat('dd MMM yyyy').format(start_date);
  }
}

class JadwalCache {
  static const String boxName = 'jadwalBox';
  static const String key = 'jadwal';

  /// 🔥 Simpan ke Hive
  static Future<void> save(List<JadwalModel> data) async {
    final box = Hive.box(boxName);

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await box.put(key, {
      'date': today,
      'data': data.map((e) => e.toJson()).toList(),
    });
  }

  /// 🔥 Ambil dari Hive
  static List<JadwalModel>? load() {
    final box = Hive.box(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final cached = box.get(key);

    if (cached != null && cached['date'] == today) {
      final List list = cached['data'];

      return list
          .map((e) => JadwalModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return null;
  }

  /// 🔥 Clear cache
  static Future<void> clear() async {
    final box = Hive.box(boxName);
    await box.clear();
  }
}

class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  String levelStandby = "basic"; // basic | standard | premium

  // State untuk API
  // List<JadwalModel> tugasData = [];
  bool isLoading = true;
  String? errorMessage;
  String? token;
  String? photo;
  String? info;

  List<JadwalModel> allJadwal = [];
  DateTime? _selectedDay;
  TaskAktif? currentTask;
  String userName = 'Teknisi';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initData();
    Cektask();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final box = Hive.box('loginBox');
    if (!mounted) return;
    setState(() {
      userName = _readNameFromLoginBox(box);
      photo = box.get('photo')?.toString();
    });
  }

  String _readNameFromLoginBox(Box box) {
    final candidates = [box.get('name'), box.get('nama'), box.get('username')];

    for (final raw in candidates) {
      final name = raw?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }

    return 'Teknisi';
  }

  List<JadwalModel> get _jadwalHariIni {
    final today = DateTime.now();
    return allJadwal.where((item) {
      return item.start_date.year == today.year &&
          item.start_date.month == today.month &&
          item.start_date.day == today.day;
    }).toList();
  }

  List<JadwalModel> get _filteredJadwal {
    if (_searchQuery.isEmpty) return _jadwalHariIni;
    final q = _searchQuery.toLowerCase();
    return _jadwalHariIni
        .where((e) => e.title.toLowerCase().contains(q))
        .toList();
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month]} ${now.year}';
  }

  ({String label, Color bg, Color text}) _taskStatusBadge(
    JadwalModel data,
    TaskAktif? rowTask,
  ) {
    if (BerandaTaskCompletionCache.isClientCompleted(data.id_cli)) {
      return (
        label: 'Selesai',
        bg: const Color(0xFFE0E0E0),
        text: Colors.black54,
      );
    }
    if (rowTask != null &&
        rowTask.clientId == data.id_cli &&
        rowTask.absenIn != null &&
        !rowTask.hasCheckedOut) {
      return (
        label: 'Sedang Berjalan',
        bg: const Color(0xFFFFE0B2),
        text: const Color(0xFFE65100),
      );
    }
    return (
      label: 'Belum Dimulai',
      bg: const Color(0xFFC8E6C9),
      text: const Color(0xFF2E7D32),
    );
  }

  Color _taskIconColor(int index) {
    const colors = [Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFF4CAF50)];
    return colors[index % colors.length];
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _initData() async {
    final cached = JadwalCache.load();

    if (cached != null) {
      setState(() {
        allJadwal = cached;
        isLoading = false;
      });
    } else {
      await fetchJadwal();
    }
  }

  Future<void> loadInfo() async {
    final box = await Hive.openBox('checkinBox');

    if (box.isNotEmpty) {
      final lastData = box.getAt(box.length - 1);
      info = lastData['info']; // 🔥 ambil info
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> getCheckin() async {
    final box = Hive.box('checkinBox');
    var info = box.get('info');
  }

  Future<void> getUserLogin() async {
    final box = Hive.box('loginBox');
    token = box.get('token');
    photo = box.get('photo');
  }

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen('jadwalBox')) {
      return await Hive.openBox('jadwalBox');
    }
    return Hive.box('jadwalBox');
  }

  Future<void> _saveCache(List<JadwalModel> data) async {
    final box = await _openBox();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await box.put('jadwal', {
      'date': today,
      'data': data.map((e) => e.toJson()).toList(),
    });
  }

  Future<bool> _loadCache() async {
    final box = await _openBox();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final cached = box.get('jadwal');

    if (cached != null && cached['date'] == today) {
      final List list = cached['data'];

      setState(() {
        allJadwal = list
            .map((e) => JadwalModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        isLoading = false;
      });

      return true;
    }

    return false;
  }

  // Method untuk filter data berdasarkan tanggal hari ini
  List<JadwalModel> getFilteredJadwal() {
    if (_selectedDay == null) return allJadwal;

    return allJadwal.where((item) {
      return isSameDay(item.start_date, _selectedDay!);
    }).toList();
  }

  Map<String, List<JadwalModel>> groupByDate(List<JadwalModel> list) {
    Map<String, List<JadwalModel>> grouped = {};

    for (var item in list) {
      String key = DateFormat('yyyy-MM-dd').format(item.start_date);

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      grouped[key]!.add(item);
    }

    return grouped;
  }

  // Method untuk fetch data dari API
  Future<void> fetchJadwal() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.getJadwal();

      final items = data.map<JadwalModel>((e) {
        return JadwalModel.fromJson(e);
      }).toList();

      setState(() {
        allJadwal = items;
        isLoading = false;
        errorMessage = null;
      });
      debugPrint("data jadwal ${jsonEncode(data)}");

      // 🔥 SIMPAN KE HIVE
      await JadwalCache.save(items);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // Method untuk refresh data
  Future<void> _refreshTugasData() async {
    _loadUserInfo();
    await Cektask();
    await fetchJadwal();
  }

  Future<void> Cektask() async {
    try {
      final res = await ApiService.cekKondisiTask();

      if (res['data'] != null) {
        final task = TaskAktif.fromJson(res['data']);
        if (task.hasCheckedOut) {
          await BerandaTaskCompletionCache.markClientCompleted(task.clientId);
        }
        if (!mounted) return;
        setState(() {
          currentTask = task;
        });
      } else {
        if (!mounted) return;
        setState(() {
          currentTask = null;
        });
      }
    } catch (e) {
      debugPrint("CekTask error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double icon = MediaQuery.of(context).size.width;
    double pontSize = MediaQuery.of(context).size.width;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final todayTasks = _jadwalHariIni;
    final selesaiCount = todayTasks
        .where((t) => BerandaTaskCompletionCache.isClientCompleted(t.id_cli))
        .length;
    final belumCount = todayTasks.length - selesaiCount;
    final hasCheckedIn = currentTask?.absenIn != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTugasData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(screenWidth),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildAttendanceCard(
                        screenWidth,
                        hasCheckedIn,
                        totalTasks: todayTasks.length,
                        selesaiCount: selesaiCount,
                        belumCount: belumCount,
                      ),
                      const SizedBox(height: 16),
                      // _buildStatRow(
                      //   todayTasks.length,
                      //   selesaiCount,
                      //   belumCount,
                      // ),
                      const SizedBox(height: 16),
                      _buildMenuGrid(
                        context,
                        icon: icon,
                        pontSize: pontSize,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      const SizedBox(height: 20),
                      _buildTugasSectionHeader(),
                      const SizedBox(height: 12),
                      // _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildTugasListBody(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    final displayName = _readNameFromLoginBox(Hive.box('loginBox'));
    final userPhoto = Hive.box('loginBox').get('photo')?.toString();
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFF5F7FA)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $displayName 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selamat bekerja hari ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTodayDate(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 26,
            backgroundImage: userPhoto != null && userPhoto.isNotEmpty
                ? NetworkImage(userPhoto)
                : const NetworkImage('https://i.pravatar.cc/150?img=3'),
          ),
        ],
      ),
    );
  }

  int _readJobFromLoginBox() {
    final raw = Hive.box('loginBox').get('job');
    return int.tryParse('$raw') ?? 2;
  }

  bool _isVisitJob([int? job]) {
    final value = job ?? _readJobFromLoginBox();
    return value == 0 || value == 1;
  }

  bool _isStandbyJob([int? job]) {
    final value = job ?? _readJobFromLoginBox();
    return value == 2;
  }

  Widget _buildAttendanceCard(
    double screenWidth,
    bool hasCheckedIn, {
    required int totalTasks,
    required int selesaiCount,
    required int belumCount,
  }) {
    final job = _readJobFromLoginBox();
    if (_isVisitJob(job)) {
      return _buildProgressHariIniCard(
        screenWidth,
        totalTasks: totalTasks,
        selesaiCount: selesaiCount,
        belumCount: belumCount,
      );
    }
    return _buildAbsenCard(screenWidth, hasCheckedIn);
  }

  Widget _buildProgressHariIniCard(
    double screenWidth, {
    required int totalTasks,
    required int selesaiCount,
    required int belumCount,
  }) {
    final progress = totalTasks > 0 ? selesaiCount / totalTasks : 0.0;
    final percentLabel = (progress * 100).round();

    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: Color(0xFF5C6BC0),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Progress Hari Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildProgressStatColumn(
                          label: 'Total Task',
                          value: '$totalTasks',
                          labelColor: const Color(0xFF1A237E),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildProgressStatColumn(
                          label: 'Selesai',
                          value: '$selesaiCount',
                          labelColor: AppColors.success,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildProgressStatColumn(
                          label: 'Belum Selesai',
                          value: '$belumCount',
                          labelColor: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFFE8EAF6),
                    color: AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentLabel%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatColumn({
    required String label,
    required String value,
    required Color labelColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Task',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildAbsenCard(double screenWidth, bool hasCheckedIn) {
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Jam Kerja Hari Ini',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasCheckedIn
                      ? const Color(0xFFB3E5FC)
                      : const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasCheckedIn ? 'Sudah Check In' : 'Belum Check In',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasCheckedIn
                        ? const Color(0xFF0277BD)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeInfo(
                  label: 'Check In',
                  time: '08:00 WIB',
                  color: AppColors.success,
                  icon: Icons.login,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeInfo(
                  label: 'Check Out',
                  time: '17:00 WIB',
                  color: AppColors.danger,
                  icon: Icons.logout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckinPage(
                          id_cli: allJadwal.isNotEmpty
                              ? allJadwal[0].id_cli
                              : 0,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Check In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (currentTask == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Belum ada task aktif')),
                      );
                      return;
                    }
                    if (currentTask!.hasCheckedOut) return;

                    final done = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckOut(
                          taskId: currentTask!.taskId,
                          clientId: currentTask!.clientId,
                        ),
                      ),
                    );

                    if (done == true) {
                      await BerandaTaskCompletionCache.markClientCompleted(
                        currentTask!.clientId,
                      );
                      await _refreshTugasData();
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Check Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo({
    required String label,
    required String time,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: color)),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(int total, int selesai, int belum) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment,
            iconColor: AppColors.primary,
            label: 'Tugas Hari Ini',
            value: '$total Tugas',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            label: 'Selesai',
            value: '$selesai Tugas',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            iconColor: AppColors.orange,
            label: 'Belum Selesai',
            value: '$belum Tugas',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(
    BuildContext context, {
    required double icon,
    required double pontSize,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      width: screenWidth,
      // padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: screenWidth * 0.01,
        runSpacing: 12,
        children: [
          _buildMenuItem(
            context,
            iconPath: 'assets/icons/history.png',
            label: 'History',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => History()),
            ),
            iconSize: icon * 0.11,
            fontSize: pontSize,
            containerWidth: screenWidth,
            containerHeight: screenHeight * 0.12,
          ),
          _buildMenuItem(
            context,
            iconPath: 'assets/icons/myclient.png',
            label: 'My Client',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MyClient()),
            ),
            iconSize: icon * 0.11,
            fontSize: pontSize,
            containerWidth: screenWidth,
            containerHeight: screenHeight * 0.12,
          ),
          _buildMenuItem(
            context,
            iconPath: 'assets/icons/chemical.png',
            label: 'Chemical',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChemicalPage()),
            ),
            iconSize: icon * 0.11,
            fontSize: pontSize,
            containerWidth: screenWidth,
            containerHeight: screenHeight * 0.12,
          ),
          _buildMenuItem(
            context,
            iconPath: 'assets/icons/absensi.png',
            label: 'Absensi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Absensi()),
            ),
            iconSize: icon * 0.11,
            fontSize: pontSize,
            containerWidth: screenWidth,
            containerHeight: screenHeight * 0.12,
          ),
          _buildMenuItem(
            context,
            iconPath: 'assets/icons/absensi.png',
            label: 'QR Code',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrCode()),
            ),
            iconSize: icon * 0.11,
            fontSize: pontSize,
            containerWidth: screenWidth,
            containerHeight: screenHeight * 0.12,
          ),
          _buildMenuItem(
            context,
            iconPath: 'assets/icons/notifikasi.png',
            label: 'Notifikasi',
            badgeCount: 3,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Notifikasi()),
            ),
            iconSize: icon * 0.11,
            fontSize: pontSize,
            containerWidth: screenWidth,
            containerHeight: screenHeight * 0.12,
          ),
          
        ],
      ),
    );
  }

  Widget _buildTugasSectionHeader() {
    return Row(
      children: [
        const Icon(Icons.assignment, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Tugas Hari Ini',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton.icon(
          onPressed: _refreshTugasData,
          icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
          label: const Text(
            'Refresh',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari tugas...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTugasListBody() {
    if (_isStandbyJob()) {
      return _buildStandbyContent();
    }
    return _buildVisitContent();
  }

  Widget _buildVisitContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshTugasData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final jadwalHariIni = _filteredJadwal;

    if (jadwalHariIni.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Tidak ada tugas untuk hari ini'
                  : 'Tugas tidak ditemukan',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jadwalHariIni.length,
      itemBuilder: (context, index) {
        final data = jadwalHariIni[index];
        final rowTask = taskForJadwalRow(currentTask, data.id_cli);
        final scheduleBtn = resolveScheduleButtonStyle(
          rowTask,
          jadwalIdCli: data.id_cli,
        );
        final badge = _taskStatusBadge(data, rowTask);
        final iconColor = _taskIconColor(index);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_run,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badge.bg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: badge.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PCRC',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
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
                              data.getFormattedDate(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.message_outlined,
                              size: 13,
                              color: Colors.black45,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'note',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Opacity(
                  opacity: scheduleBtn.isDisabled ? 0.55 : 1,
                  child: InkWell(
                    onTap: scheduleBtn.isDisabled
                        ? null
                        : () async {
                            await handleBerandaScheduleTap(
                              context,
                              jadwalIdCli: data.id_cli,
                              task: rowTask,
                              onRefresh: _refreshTugasData,
                            );
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheduleBtn.buttonColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            scheduleBtn.buttonText,
                            style: scheduleBtn.textStyle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandbyContent() {
    if (levelStandby == "basic") {
      return _buildBasic();
    } else if (levelStandby == "standard") {
      return _buildStandard();
    } else if (levelStandby == "premium") {
      return _buildPremium();
    } else {
      return const Text("Level tidak dikenal");
    }
  }

  Widget _buildBasic() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Tugas Standby - Basic",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text("Deskripsi tugas untuk level Basic"),
          // Tambahkan detail tugas lainnya sesuai kebutuhan
        ],
      ),
    );
  }

  Widget _buildStandard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Tugas Standby - Standard",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text("Deskripsi tugas untuk level Standard"),
          // Tambahkan detail tugas lainnya sesuai kebutuhan
        ],
      ),
    );
  }

  Widget _buildPremium() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Jika sedang loading
    if (isLoading) {
      return Center(
        child: Container(
          width: screenWidth,
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF2F80ED)),
              const SizedBox(height: 16),
              const Text('Memuat tugas teknisi...'),
            ],
          ),
        ),
      );
    }

    // Jika ada error
    if (errorMessage != null) {
      return Center(
        child: Container(
          width: screenWidth,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage ?? 'Terjadi kesalahan',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshTugasData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                ),
                child: const Text(
                  'Coba Lagi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Jika data kosong
    if (allJadwal.isEmpty) {
      return Center(
        child: Container(
          width: screenWidth,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada tugas untuk hari ini',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshTugasData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                ),
                child: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTugasData,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: allJadwal.length,
        itemBuilder: (context, index) {
          final data = allJadwal[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ICON
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB3DBF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_run,
                    color: Color(0xFF2F80ED),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),

                /// TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   data.description,
                      //   style: const TextStyle(
                      //     fontSize: 13,
                      //     color: Colors.black54,
                      //   ),
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${data.getFormattedDate()} ${data.start_time}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Row(
                      //   crossAxisAlignment: CrossAxisAlignment.start,
                      //   children: [
                      //     const Icon(
                      //       Icons.message_outlined,
                      //       size: 14,
                      //       color: Colors.black45,
                      //     ),
                      //     const SizedBox(width: 4),
                      //     Expanded(
                      //       child: Text(
                      //         data.description,
                      //         style: const TextStyle(
                      //           fontSize: 12,
                      //           color: Colors.black54,
                      //         ),
                      //         maxLines: 2,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                /// BUTTON
                InkWell(
                  onTap: () async {
                    print("🔥 KLIK MULAI");

                    try {
                      final res = await ApiService.cekKondisiTask();

                      print("✅ RESPONSE: $res");

                      final data = res['data'];
                      print("📦 DATA: $data");

                      final job = _readJobFromLoginBox();

                      print("👤 JOB: $job");

                      final isVisit = _isVisitJob(job);

                      // ======================
                      // 🔴 DATA NULL
                      // ======================
                      if (data == null) {
                        print("➡️ DATA NULL → CHECKIN");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckinPage(id_cli: 0),
                          ),
                        );
                        return;
                      }

                      // ======================
                      // ✅ DATA ADA
                      // ======================
                      final taskId = int.tryParse('${data['task_id']}') ?? 0;
                      final clientId =
                          int.tryParse('${data['client_id']}') ?? 0;
                      final absenIn = data['absen_in'];
                      final tugas = data['tugas'] == null
                          ? null
                          : int.tryParse('${data['tugas']}');
                      final signIn = data['sign_in'];

                      print("📊 taskId: $taskId, clientId: $clientId");
                      print(
                        "📊 absenIn: $absenIn, tugas: $tugas, signIn: $signIn",
                      );

                      if (isVisit) {
                        print("🔴 MODE VISIT");

                        if (absenIn == null) {
                          print("➡️ BELUM ABSEN");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckinPage(id_cli: clientId),
                            ),
                          );
                          return;
                        }

                        if (tugas != 4) {
                          print("➡️ KE DETAIL");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailTask(
                                taskId: taskId,
                                clientId: clientId,
                                absenIn: absenIn,
                                tugas: tugas,
                                signIn: signIn,
                              ),
                            ),
                          );
                          return;
                        }

                        if (tugas == 4 && signIn == null) {
                          print("➡️ KE SIGNATURE");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignaturePage(taskId: taskId),
                            ),
                          );
                          return;
                        }

                        if (tugas == 4 && signIn != null) {
                          print("➡️ KE CHECKOUT");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CheckOut(taskId: taskId, clientId: clientId),
                            ),
                          );
                          return;
                        }
                      } else {
                        print("🔵 MODE STANDBY");

                        if (absenIn == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckinPage(id_cli: clientId),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailTask(
                                taskId: taskId,
                                clientId: clientId,
                                absenIn: absenIn,
                                tugas: tugas,
                                signIn: signIn,
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print("❌ ERROR API: $e");

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Mulai',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String iconPath,
    required String label,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required double containerHeight,
    required double containerWidth,
    int? badgeCount,
  }) {
    return Container(
      width: containerWidth * 0.3,
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(iconPath, fit: BoxFit.contain),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width > 750
                  ? fontSize * 0.03
                  : fontSize * 0.028,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
