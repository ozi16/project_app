import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/services/api_service.dart';

class JadwalModel {
  final String title;
  final String description;
  final String start_time;
  final DateTime start_date;

  JadwalModel({
    required this.title,
    required this.description,
    required this.start_time,
    required this.start_date,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;

    try {
      parsedDate = DateTime.parse(json['start_date']).toLocal();
    } catch (e) {
      parsedDate = DateTime.now();
    }

    if (parsedDate.year < 2000 || parsedDate.year > 2030) {
      try {
        parsedDate = DateTime.parse(json['created_at']).toLocal();
      } catch (e) {
        parsedDate = DateTime.now();
      }
    }

    return JadwalModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      start_time: json['start_time'] ?? '',
      start_date: parsedDate,
    );
  }
}

class Jadwal extends StatefulWidget {
  const Jadwal({super.key});

  @override
  State<Jadwal> createState() => _JadwalState();
}

class _JadwalState extends State<Jadwal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  List<JadwalModel> allJadwal = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJadwal();
  }

  /// 🔥 SAFE DATE (ANTI CRASH)
  DateTime safeDate(DateTime date) {
    final first = DateTime.utc(2020, 1, 1);
    final last = DateTime.utc(2030, 12, 31);

    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }

  /// 🔥 FETCH API
  Future<void> fetchJadwal() async {
    try {
      final data = await ApiService.getJadwal();

      final items = data.map((e) => JadwalModel.fromJson(e)).toList();

      // print("TOTAL DATA: ${items.length}");

      for (var i in items) {
        print("JADWAL: ${i.title} - ${i.start_date}");
      }

      setState(() {
        allJadwal = items;
        isLoading = false;

        /// 🔥 AUTO SELECT DATA PERTAMA
        if (items.isNotEmpty) {
          _selectedDay = items.first.start_date;
          _focusedDay = items.first.start_date;
        }
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔥 FILTER TANGGAL
  List<JadwalModel> getFilteredJadwal() {
    if (_selectedDay == null) return allJadwal;

    return allJadwal.where((item) {
      return isSameDay(item.start_date, _selectedDay);
    }).toList();
  }

  /// 🔥 GROUP BY TANGGAL
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

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredJadwal();
    final grouped = groupByDate(filtered);
    final keys = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Jadwal Pekerjaan',
          style: TextStyle(color: Colors.white),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       setState(() {
        //         _selectedDay = null;
        //       });
        //     },
        //     child: const Text("Semua", style: TextStyle(color: Colors.white)),
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// ================= CALENDAR =================
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2050, 12, 31),
              focusedDay: safeDate(_focusedDay),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && isSameDay(_selectedDay, day),

              /// 🔴 MARKER
              eventLoader: (day) {
                return allJadwal.where((item) {
                  return isSameDay(item.start_date, day);
                }).toList();
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 8),

            /// ================= TITLE =================
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _selectedDay == null
                    ? "Semua Jadwal"
                    : "Jadwal ${DateFormat('dd MMM yyyy').format(_selectedDay!)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            /// ================= LIST =================
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF4FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : keys.isEmpty
                    ? const Center(child: Text("Tidak ada jadwal"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: keys.length,
                        itemBuilder: (context, index) {
                          final dateKey = keys[index];
                          final items = grouped[dateKey]!;
                          final date = DateTime.parse(dateKey);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              ...items.map((item) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat(
                                                'dd MMM yyyy',
                                              ).format(item.start_date),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.more_vert,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                );
                                ;
                              }).toList(),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
