import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:teknisi_aag/BerandaPage/Checkin&Checkout/checkIn.dart';
import 'package:teknisi_aag/BerandaPage/Checkin&Checkout/checkOut.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/checklist.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/chemicalUsed.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/dokumentasiRekomendasi.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/dokumentasiTreatment.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/signature.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/task_completion_cache.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

/// Model tugas aktif (dipakai beranda & alur jadwal).
class TaskAktif {
  final int taskId;
  final int clientId;
  final String? absenIn;
  final int? tugas;
  final String? signIn;
  final int? status;
  final String? absenOut;

  TaskAktif({
    required this.taskId,
    required this.clientId,
    this.absenIn,
    this.tugas,
    this.signIn,
    this.status,
    this.absenOut,
  });

  bool get hasCheckedOut {
    if (absenOut == null) return false;
    return absenOut!.trim().isNotEmpty;
  }

  factory TaskAktif.fromJson(Map<String, dynamic> json) {
    final rawOut = json['absen_out'];
    return TaskAktif(
      taskId: int.tryParse('${json['task_id']}') ?? 0,
      clientId: int.tryParse('${json['client_id']}') ?? 0,
      absenIn: json['absen_in']?.toString(),
      tugas: json['tugas'] == null ? null : int.tryParse('${json['tugas']}'),
      signIn: json['sign_in']?.toString(),
      absenOut: rawOut == null ? null : rawOut.toString(),
    );
  }
}

class taskStatus {
  final int taskid;
  final String task_name;

  taskStatus({required this.taskid, required this.task_name});
}

/// Label & style tombol jadwal di beranda (logika dipusatkan di sini).
class ScheduleButtonStyle {
  final String buttonText;
  final Color buttonColor;
  final bool isDisabled;
  // final Color textColor;
  final TextStyle textStyle;

  const ScheduleButtonStyle({
    required this.buttonText,
    required this.buttonColor,
    required this.isDisabled,
    // required this.textColor,
    required this.textStyle,
  });
}

ScheduleButtonStyle resolveScheduleButtonStyle(
  TaskAktif? task, {
  required int jadwalIdCli,
}) {
  const selesai = ScheduleButtonStyle(
    buttonText: 'Selesai',
    buttonColor: Colors.grey,
    isDisabled: true,
    // textColor: Colors.white,
    textStyle: const TextStyle(color: Colors.white),
  );

  if (BerandaTaskCompletionCache.isClientCompleted(jadwalIdCli)) {
    return selesai;
  }

  String buttonText = 'Mulai';
  Color buttonColor = AppColors.secondaryLight;
  bool isDisabled = false;
  // Color textColor = Colors.white;
  TextStyle textStyle = const TextStyle(color: Colors.white);
  if (task != null) {
    if (task.hasCheckedOut) {
      return selesai;
    }
    if (task.tugas != 4) {
      buttonText = 'Proses';
      buttonColor = AppColors.primaryLight;
      // textColor = Colors.black;
      textStyle = const TextStyle(color: Colors.white);
    } else if (task.tugas == 4 && task.signIn == null) {
      buttonText = 'Proses';
      buttonColor = AppColors.primaryLight;
      // textColor = Colors.white;
      textStyle = const TextStyle(color: Colors.white);
    } else if (task.tugas == 4 && task.signIn != null && !task.hasCheckedOut) {
      buttonText = 'Absen-out';
      buttonColor = AppColors.primaryLight;
      // textColor = Colors.white;
      textStyle = const TextStyle(color: Colors.white);
    }
  }

  return ScheduleButtonStyle(
    buttonText: buttonText,
    buttonColor: buttonColor,
    isDisabled: isDisabled,
    // textColor: textColor,
    textStyle: textStyle,
  );
}

TaskAktif? taskForJadwalRow(TaskAktif? task, int jadwalIdCli) {
  if (task == null) return null;
  if (task.clientId == jadwalIdCli) return task;
  return null;
}

/// Setelah check-in, buka DetailTask jika visit aktif sudah terdaftar di server.
Future<void> openDetailTaskAfterCheckin(
  BuildContext context, {
  required int clientId,
}) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    if (attempt > 0) {
      await Future.delayed(Duration(milliseconds: 500 * attempt));
    }

    try {
      final res = await ApiService.cekKondisiTask();
      final data = res['data'];
      if (data is! Map) continue;

      final map = Map<String, dynamic>.from(data);
      final taskId = int.tryParse('${map['task_id']}') ?? 0;
      final activeClientId = int.tryParse('${map['client_id']}') ?? 0;
      final absenIn = map['absen_in'];

      if (taskId <= 0 || absenIn == null) continue;
      if (clientId > 0 && activeClientId > 0 && activeClientId != clientId) {
        continue;
      }

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailTask(
            taskId: taskId,
            clientId: activeClientId > 0 ? activeClientId : clientId,
            absenIn: absenIn.toString(),
            tugas: map['tugas'] == null
                ? null
                : int.tryParse('${map['tugas']}'),
            signIn: map['sign_in']?.toString(),
          ),
        ),
      );
      return;
    } catch (_) {}
  }
}

/// Navigasi tombol jadwal beranda (visit / standby, check-in → detail → ttd → checkout).
Future<void> handleBerandaScheduleTap(
  BuildContext context, {
  required int jadwalIdCli,
  TaskAktif? task,
  Future<void> Function()? onRefresh,
}) async {
  if (BerandaTaskCompletionCache.isClientCompleted(jadwalIdCli)) {
    return;
  }

  final loginBox = Hive.box('loginBox');
  final job = int.tryParse('${loginBox.get('job')}') ?? 2;

  final isVisit = job == 0 || job == 1;

  if (task?.hasCheckedOut == true) {
    await BerandaTaskCompletionCache.markClientCompleted(task!.clientId);
    return;
  }

  if (task == null && isVisit) {
    final checkinResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckinPage(id_cli: jadwalIdCli)),
    );

    await onRefresh?.call();
    if (checkinResult == false) {
      await openDetailTaskAfterCheckin(context, clientId: jadwalIdCli);
    }
    return;
  }

  if (task == null) {
    return;
  }

  if (task.absenIn == null && isVisit) {
    final checkinResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CheckinPage(id_cli: task.clientId)),
    );

    await onRefresh?.call();
    if (checkinResult == false) {
      await openDetailTaskAfterCheckin(context, clientId: task.clientId);
    }
    return;
  }

  if (isVisit) {
    if (task.tugas != 4) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailTask(
            taskId: task.taskId,
            clientId: task.clientId,
            absenIn: task.absenIn ?? '',
            tugas: task.tugas,
            signIn: task.signIn,
          ),
        ),
      );

      await onRefresh?.call();
      return;
    }

    if (task.tugas == 4 && task.signIn == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SignaturePage(taskId: task.taskId)),
      );

      await onRefresh?.call();
      return;
    }

    if (task.tugas == 4 && task.signIn != null && !task.hasCheckedOut) {
      final done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CheckOut(taskId: task.taskId, clientId: task.clientId),
        ),
      );

      if (done == true) {
        await BerandaTaskCompletionCache.markClientCompleted(task.clientId);
      }

      await onRefresh?.call();
      return;
    }
  } else {
    if (task.absenIn == null) {
      final checkinResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => CheckinPage(id_cli: task.clientId)),
      );
      if (checkinResult == false) {
        await openDetailTaskAfterCheckin(context, clientId: task.clientId);
      }
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailTask(
            taskId: task.taskId,
            clientId: task.clientId,
            absenIn: task.absenIn ?? '',
            tugas: task.tugas,
            signIn: task.signIn,
          ),
        ),
      );
    }
    await onRefresh?.call();
  }
}

class DetailTask extends StatefulWidget {
  // const DetailTask({super.key});
  final int taskId;
  final int clientId;
  final String absenIn;
  final int? tugas;
  final String? signIn;

  const DetailTask({
    super.key,
    required this.taskId,
    required this.clientId,
    required this.absenIn,
    required this.tugas,
    required this.signIn,
  });

  @override
  State<DetailTask> createState() => _DetailTaskState();
}

/// task_name yang dikirim saat POST ke API.
abstract class _TaskNames {
  static const treatment = 'TREATMENT';
  static const rekomendasi = 'AKSES';
  static const checklist = 'CHECKLIST';
  static const chemical = 'CHEMICAL';
}

class _DetailTaskState extends State<DetailTask> {
  bool isSelesaiTreatment = false;
  bool isSelesaiRekomendasi = false;
  bool isSelesaiChecklist = false;
  bool isSelesaiChemicel = false;
  bool isReloading = false;

  // ✅ kondisi semua selesai
  bool get isSemuaSelesai =>
      isSelesaiTreatment &&
      isSelesaiRekomendasi &&
      isSelesaiChecklist &&
      isSelesaiChemicel;

  @override
  void initState() {
    super.initState();
    _cekStatusTreatment();
    _cekStatusRekomendasi();
    _cekStatusChecklist();
    _cekStatusChemical();
  }

  Future<int?> getTaskIdFromHive() async {
    final box = await Hive.openBox('checkinBox');

    if (box.isEmpty) return null;

    final lastData = box.getAt(box.length - 1); // 🔥 ambil data terakhir

    return lastData['task_id'];
  }

  Future<int?> _resolveTaskId() async {
    if (widget.taskId > 0) return widget.taskId;
    return getTaskIdFromHive();
  }

  Future<void> _cekStatusMenu({
    required Future<List<dynamic>> Function(int id) fetchData,
    required String taskName,
    required void Function(bool selesai) setSelesai,
  }) async {
    final taskId = await _resolveTaskId();
    if (taskId == null || taskId <= 0) return;

    try {
      final data = await fetchData(taskId);
      if (!mounted) return;
      setState(() {
        setSelesai(ApiService.hasTaskName(data, taskId, taskName));
      });
    } catch (e) {
      debugPrint('Error cek $taskName: $e');
    }
  }

  Future<void> _cekStatusTreatment() => _cekStatusMenu(
    fetchData: (id) => ApiService.getTasks(taskId: id),
    taskName: _TaskNames.treatment,
    setSelesai: (selesai) => isSelesaiTreatment = selesai,
  );

  Future<void> _cekStatusRekomendasi() => _cekStatusMenu(
    fetchData: ApiService.getRekomendasiByTask,
    taskName: _TaskNames.rekomendasi,
    setSelesai: (selesai) => isSelesaiRekomendasi = selesai,
  );

  Future<void> _cekStatusChecklist() => _cekStatusMenu(
    fetchData: ApiService.getChecklistByTask,
    taskName: _TaskNames.checklist,
    setSelesai: (selesai) => isSelesaiChecklist = selesai,
  );

  Future<void> _cekStatusChemical() => _cekStatusMenu(
    fetchData: ApiService.getChemicalUsedByTask,
    taskName: _TaskNames.chemical,
    setSelesai: (selesai) => isSelesaiChemicel = selesai,
  );

  /// Reload semua status menu dari API (setelah selesai isi task).
  Future<void> _reloadSemuaStatus() async {
    if (!mounted) return;
    setState(() => isReloading = true);

    await Future.wait([
      _cekStatusTreatment(),
      _cekStatusRekomendasi(),
      _cekStatusChecklist(),
      _cekStatusChemical(),
    ]);

    if (!mounted) return;
    setState(() => isReloading = false);
  }

  /// Buka halaman task, lalu reload DetailTask jika upload berhasil.
  Future<void> _bukaTaskDanReload(Widget page) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (result == true && mounted) {
      await _reloadSemuaStatus();
    }
  }

  void _showTaskIdError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task ID tidak ditemukan')));
  }

  static const _darkCardColor = Color(0xFF1E293B);

  Widget _buildStatusBadge({required bool isDone, required bool onDarkCard}) {
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: onDarkCard
              ? AppColors.secondary.withValues(alpha: 0.25)
              : AppColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: onDarkCard ? AppColors.secondaryLight : AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              'Selesai',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    onDarkCard ? AppColors.secondaryLight : AppColors.secondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 14,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            'Belum Selesai',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWajibBadge({required bool onDarkCard}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDarkCard
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 13,
            color: onDarkCard ? Colors.white70 : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Wajib',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: onDarkCard ? Colors.white70 : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required bool isDone,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    final onDarkCard = isDone;
    final titleColor = onDarkCard ? Colors.white : AppColors.textPrimary;
    final subtitleColor =
        onDarkCard ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600;
    final chevronColor = onDarkCard ? Colors.white70 : Colors.grey.shade500;

    return Material(
      color: onDarkCard ? _darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: onDarkCard ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: isDone ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: onDarkCard
                ? null
                : Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: onDarkCard
                      ? iconColor.withValues(alpha: 0.22)
                      : iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
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
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(
                          isDone: isDone,
                          onDarkCard: onDarkCard,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildWajibBadge(onDarkCard: onDarkCard),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: chevronColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerhatianBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: AppColors.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perhatian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pastikan semua tugas selesai sebelum menyelesaikan pekerjaan.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Detail Tugas Teknisi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            if (isReloading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            _buildTaskCard(
              title: 'Dokumentasi Treatment',
              subtitle:
                  'Lengkapi dokumentasi kondisi dan proses treatment.',
              isDone: isSelesaiTreatment,
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF1565C0),
              iconBg: const Color(0xFFE3F2FD),
              onTap: () async {
                if (isSelesaiTreatment) return;
                final taskId = await _resolveTaskId();
                if (taskId == null) {
                  _showTaskIdError();
                  return;
                }
                await _bukaTaskDanReload(Dokumentasitreatment(taskId: taskId));
              },
            ),
            const SizedBox(height: 12),
            _buildTaskCard(
              title: 'Dokumentasi Temuan & Rekomendasi',
              subtitle:
                  'Catat temuan di lapangan serta berikan rekomendasi perbaikan.',
              isDone: isSelesaiRekomendasi,
              icon: Icons.fact_check_outlined,
              iconColor: const Color(0xFF2E7D32),
              iconBg: const Color(0xFFE8F5E9),
              onTap: () async {
                if (isSelesaiRekomendasi) return;
                final taskId = await _resolveTaskId();
                if (taskId == null) {
                  _showTaskIdError();
                  return;
                }
                await _bukaTaskDanReload(
                  DokumentasiRekomendasi(taskId: taskId),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildTaskCard(
              title: 'Checklist',
              subtitle:
                  'Isi checklist area, equipment, dan item yang digunakan.',
              isDone: isSelesaiChecklist,
              icon: Icons.checklist_rtl_rounded,
              iconColor: const Color(0xFF6A1B9A),
              iconBg: const Color(0xFFF3E5F5),
              onTap: () async {
                if (isSelesaiChecklist) return;
                final taskId = await _resolveTaskId();
                if (taskId == null) {
                  _showTaskIdError();
                  return;
                }
                await _bukaTaskDanReload(Checklistpage(taskId: taskId));
              },
            ),
            const SizedBox(height: 12),
            _buildTaskCard(
              title: 'Chemical Used',
              subtitle:
                  'Catat bahan kimia yang digunakan selama treatment.',
              isDone: isSelesaiChemicel,
              icon: Icons.science_outlined,
              iconColor: const Color(0xFFC62828),
              iconBg: const Color(0xFFFFEBEE),
              onTap: () async {
                if (isSelesaiChemicel) return;
                final taskId = await _resolveTaskId();
                if (taskId == null) {
                  _showTaskIdError();
                  return;
                }
                await _bukaTaskDanReload(ChemicalUsedPage(taskId: taskId));
              },
            ),
            const SizedBox(height: 16),
            // _buildPerhatianBanner(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isSemuaSelesai
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final taskId = await _resolveTaskId();
                          if (taskId == null) {
                            _showTaskIdError();
                            return;
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SignaturePage(taskId: taskId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Lanjut',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
