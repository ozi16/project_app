import 'package:flutter/material.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';

class notif {
  final String title;
  final String description;
  final String date;
  final String time;
  final String status;
  final String type;
  final String priority;
  final String category;
  final String location;

  notif({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.status,
    required this.type,
    required this.priority,
    required this.category,
    required this.location,
  });
}

class Notifikasi extends StatefulWidget {
  const Notifikasi({super.key});

  @override
  State<Notifikasi> createState() => _NotifikasiState();
}

class _NotifikasiState extends State<Notifikasi> {
  List<notif> allNotifications = [];
  List<notif> filteredNotifications = [];
  Future<List<notif>>? futureNotifications;

  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    // futureNotifications = fetchNotification();
    dummyData();
  }

  void dummyData() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowLabel =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    setState(() {
      allNotifications = [
        notif(
          title: 'Kunjungan Besok - LSI Metropolitan Mall Bekasi',
          description:
              'Treatment rutin area food court & basement. Siapkan chemical dan alat sesuai checklist.',
          date: tomorrowLabel,
          time: '08:00',
          status: 'Upcoming',
          type: 'Visit',
          priority: 'Tinggi',
          category: 'Treatment Rutin',
          location: 'Bekasi, Jawa Barat',
        ),
        notif(
          title: 'Kunjungan Besok - PHD Ungaran',
          description:
              'Follow up treatment bulan lalu. Fokus area dapur dan gudang.',
          date: tomorrowLabel,
          time: '09:30',
          status: 'Upcoming',
          type: 'Visit',
          priority: 'Sedang',
          category: 'Follow Up',
          location: 'Ungaran, Jawa Tengah',
        ),
        notif(
          title: 'Kunjungan Besok - FCDS/PHD Pondok Labu',
          description:
              'Inspeksi perangkap tikus & replenishment bait station lantai 2.',
          date: tomorrowLabel,
          time: '11:00',
          status: 'Upcoming',
          type: 'Visit',
          priority: 'Sedang',
          category: 'Inspeksi',
          location: 'Jakarta Selatan',
        ),
        notif(
          title: 'Kunjungan Besok - PT ABC Indonesia',
          description:
              'Kunjungan awal (survey) untuk kontrak treatment tahunan.',
          date: tomorrowLabel,
          time: '13:30',
          status: 'Upcoming',
          type: 'Visit',
          priority: 'Tinggi',
          category: 'Survey',
          location: 'Jakarta Selatan',
        ),
        notif(
          title: 'Kunjungan Besok - Hotel Grand Mercure',
          description:
              'Fogging area kitchen & linen room. Koordinasi dengan PIC hotel sebelum mulai.',
          date: tomorrowLabel,
          time: '15:00',
          status: 'Upcoming',
          type: 'Visit',
          priority: 'Tinggi',
          category: 'Fogging',
          location: 'Jakarta Pusat',
        ),
        notif(
          title: 'Reminder Pekerjaan Besok',
          description:
              'Total 5 kunjungan dijadwalkan besok. Pastikan stok chemical dan kendaraan siap.',
          date: tomorrowLabel,
          time: '17:00',
          status: 'Reminder',
          type: 'Info',
          priority: 'Rendah',
          category: 'Reminder',
          location: '-',
        ),
      ];
      filteredNotifications = List.from(allNotifications);
    });
  }

  // ================= FETCH DATA =================
  // Future<List<dynamic>> fetchNotification() async {
  //   try {
  //     final data = await ApiService.getNotification();
  //   } catch (e) {
  //     print("ERROR: $e");
  //     return [];
  //   }
  // }

  // ================= SEARCH =================
  // void _search(String query) {
  //   setState(() {
  //     if (query.isEmpty) {
  //       isSearching = false;
  //       filteredNotifications = allNotifications;
  //     } else {
  //       isSearching = true;
  //       filteredNotifications = allNotifications.where((item) {
  //         return item['nama_notification'].toString().toLowerCase().contains(
  //           query.toLowerCase(),
  //         );
  //       }).toList();
  //     }
  //   });
  // }

  // ================= REFRESH =================
  // Future<void> _refresh() async {
  //   final data = await fetchNotification();

  //   setState(() {
  //     futureNotifications = Future.value(data);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          screenHeight * 0.15,
        ), // 15% dari tinggi layar
        child: AppBar(
          backgroundColor: AppColors.primary,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30), // radius bawah
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.maybePop(context);
            },
          ),
          title: const Text(
            "Notifications",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
              onPressed: dummyData,
            ),
          ],
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white70),
                // controller: searchController,
                // onChanged: _searchClient,
                decoration: InputDecoration(
                  hintText: 'Cari nama client',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: filteredNotifications.isEmpty
          ? const Center(child: Text("Tidak ada notifikasi"))
          : ListView.builder(
              itemCount: filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = filteredNotifications[index];
                return Container(
                  margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                  width: screenWidth * 1,
                  height: screenHeight * 0.23,
                  // color: const Color.fromARGB(255, 243, 109, 109),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: AppColors.secondary, width: 3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 35, top: 25),
                            child: Container(
                              width: screenWidth * 0.12,
                              height: screenHeight * 0.05,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.notifications,
                                size: 32,
                                color: const Color.fromARGB(255, 12, 143, 14),
                              ),
                            ),
                          ),
                          Container(
                            width: screenWidth * 0.7,
                            height: screenHeight * 0.18,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              // color: const Color.fromARGB(255, 255, 255, 255),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    notification.description,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${notification.time} WIB • ${notification.location}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailNotifikasi(),
                            ),
                          );
                        },
                        child: Container(
                          width: screenWidth * 1,
                          height: screenHeight * 0.05,
                          // color: const Color.fromARGB(255, 223, 238, 253),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 223, 238, 253),
                            // borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child:
                                // color: AppColors.secondary,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Detail",
                                      style: TextStyle(
                                        // color: AppColors.secondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      // color: AppColors.secondary,
                                      size: 16,
                                    ),
                                  ],
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
}

class DetailNotifikasi extends StatefulWidget {
  const DetailNotifikasi({super.key});

  @override
  State<DetailNotifikasi> createState() => _DetailNotifikasiState();
}

class _DetailNotifikasiState extends State<DetailNotifikasi> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
                top: 10,
                bottom: 10,
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                    width: screenWidth * 1,
                    height: screenHeight * 0.16,
                    // color: const Color.fromARGB(255, 243, 109, 109),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(color: AppColors.secondary, width: 3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: screenWidth * 0.6,
                              height: screenHeight * 0.16,
                              decoration: BoxDecoration(
                                // color: const Color.fromARGB(255, 156, 62, 62),
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Treatment Type",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      // fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Treatment Description",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 22,
                                        color: Colors.black45,
                                      ),
                                      SizedBox(width: 15),
                                      Text(
                                        "08:00 AM",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 30),
                              width: screenWidth * 0.25,
                              height: screenHeight * 0.03,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                  255,
                                  217,
                                  87,
                                  18,
                                ).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Upcoming",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: screenWidth * 1,
                    height: screenHeight * 0.16,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 158, 48, 48),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: screenWidth * 1,
                    height: screenHeight * 0.16,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 158, 48, 48),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: screenWidth * 1,
                    height: screenHeight * 0.16,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 158, 48, 48),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: screenWidth * 1,
                    height: screenHeight * 0.16,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 158, 48, 48),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: screenWidth * 1,
                    height: screenHeight * 0.16,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 158, 48, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
