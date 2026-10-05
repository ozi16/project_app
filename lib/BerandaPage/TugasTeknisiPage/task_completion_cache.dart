import 'package:hive/hive.dart';

/// Cache client yang sudah checkout hari ini (jika API tidak lagi mengembalikan task aktif).
class BerandaTaskCompletionCache {
  static String _todayKey() {
    final n = DateTime.now();
    return 'completed_clients_${n.year}-${n.month}-${n.day}';
  }

  static Set<int> loadCompletedClientIds() {
    final box = Hive.box('loginBox');
    final raw = box.get(_todayKey());
    if (raw is! List) return {};
    return raw
        .map((e) => int.tryParse('$e') ?? 0)
        .where((id) => id > 0)
        .toSet();
  }

  static bool isClientCompleted(int clientId) {
    return loadCompletedClientIds().contains(clientId);
  }

  static Future<void> markClientCompleted(int clientId) async {
    if (clientId <= 0) return;
    final box = Hive.box('loginBox');
    final ids = loadCompletedClientIds()..add(clientId);
    await box.put(_todayKey(), ids.toList());
  }
}
