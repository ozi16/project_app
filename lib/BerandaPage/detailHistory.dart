// import 'package:flutter/material.dart';

// import 'history.dart';

// class DetailHistory extends StatelessWidget {
//   final JadwalHistoryModel data;

//   const DetailHistory({super.key, required this.data});

//   String formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Detail History')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               data.title,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Tanggal: ${formatDate(data.startDate)}',
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Waktu: ${data.startTime}',
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Deskripsi:',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               data.description,
//               style: const TextStyle(fontSize: 14, color: Colors.black54),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
