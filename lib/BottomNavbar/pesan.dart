import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Pesan extends StatefulWidget {
  const Pesan({super.key});

  @override
  State<Pesan> createState() => _PesanState();
}

class _PesanState extends State<Pesan> {
  List<DokumentasiItem> dokumentasiList = [];

  double screenWidth = 0;
  double screenHeight = 0;
  double iconsize = 50;

  Future<void> generatePdfFromList() async {
    final pdf = pw.Document();

    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/icons/logo_aag.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "LAPORAN DOKUMENTASI",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 20),
          pw.Center(child: pw.Image(logo, height: 80)),
          pw.SizedBox(height: 20),

          pw.Text("Tanggal: ${DateTime.now()}"),

          /// LOOP SEMUA DATA
          ...dokumentasiList.asMap().entries.map((entry) {
            int index = entry.key;
            var item = entry.value;

            final image = item.image != null
                ? pw.MemoryImage(File(item.image!.path).readAsBytesSync())
                : null;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "Dokumentasi ${index + 1}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),

                pw.SizedBox(height: 10),

                if (image != null)
                  pw.Image(image, height: 200)
                else
                  pw.Text("Tidak ada gambar"),

                pw.SizedBox(height: 10),

                pw.Text(
                  "Keterangan:",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),

                pw.Text(item.keteranganController.text),

                pw.Divider(),

                pw.SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // return Scaffold(
    //   appBar: AppBar(title: const Text("Task Dokumentasi"), centerTitle: true),
    //   body: Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       SizedBox(
    //         width: screenWidth * 0.95,
    //         child: Column(
    //           children: [
    //             const SizedBox(height: 10),
    //             /// TITLE
    //             Row(
    //               children: const [
    //                 Text(
    //                   'Task',
    //                   style: TextStyle(
    //                     fontSize: 25,
    //                     fontWeight: FontWeight.bold,
    //                   ),
    //                 ),
    //               ],
    //             ),
    //             const SizedBox(height: 10),
    //             /// LIST
    //             Expanded(
    //               child: ListView.builder(
    //                 padding: const EdgeInsets.all(10),
    //                 itemCount: dokumentasiList.length + 1,
    //                 itemBuilder: (context, index) {
    //                   /// BUTTON TAMBAH
    //                   if (index == dokumentasiList.length) {
    //                     return Padding(
    //                       padding: const EdgeInsets.only(top: 16),
    //                       child: ElevatedButton.icon(
    //                         icon: const Icon(Icons.add),
    //                         label: const Text('Tambahkan Dokumentasi'),
    //                         style: ElevatedButton.styleFrom(
    //                           backgroundColor: const Color(0xFFBFDDF4),
    //                         ),
    //                         onPressed: () {
    //                           setState(() {
    //                             dokumentasiList.add(
    //                               DokumentasiItem(
    //                                 keteranganController:
    //                                     TextEditingController(),
    //                               ),
    //                             );
    //                           });
    //                         },
    //                       ),
    //                     );
    //                   }
    //                   final item = dokumentasiList[index];
    //                   return Container(
    //                     margin: const EdgeInsets.only(bottom: 16),
    //                     padding: const EdgeInsets.all(10),
    //                     decoration: BoxDecoration(
    //                       borderRadius: BorderRadius.circular(15),
    //                       border: Border.all(color: Colors.black),
    //                     ),
    //                     child: Column(
    //                       children: [
    //                         /// PREVIEW FOTO
    //                         item.image != null
    //                             ? ClipRRect(
    //                                 borderRadius: BorderRadius.circular(10),
    //                                 child: Image.file(
    //                                   File(item.image!.path),
    //                                   height: 180,
    //                                   width: double.infinity,
    //                                   fit: BoxFit.cover,
    //                                 ),
    //                               )
    //                             : Icon(
    //                                 Icons.camera_alt,
    //                                 size: 80,
    //                                 color: Colors.grey,
    //                               ),
    //                         const SizedBox(height: 10),
    //                         /// KETERANGAN
    //                         TextField(
    //                           controller: item.keteranganController,
    //                           maxLines: 2,
    //                           decoration: const InputDecoration(
    //                             border: OutlineInputBorder(),
    //                             labelText: 'Keterangan Foto',
    //                           ),
    //                         ),
    //                         const SizedBox(height: 10),
    //                         /// BUTTON CAMERA
    //                         ElevatedButton.icon(
    //                           icon: const Icon(Icons.camera_alt),
    //                           label: const Text('Ambil Foto'),
    //                           onPressed: () async {
    //                             final picked = await ImagePicker().pickImage(
    //                               source: ImageSource.camera,
    //                             );
    //                             if (picked != null) {
    //                               setState(() {
    //                                 item.image = picked;
    //                               });
    //                             }
    //                           },
    //                         ),
    //                       ],
    //                     ),
    //                   );
    //                 },
    //               ),
    //             ),
    //             /// BUTTON SIMPAN
    //             SizedBox(
    //               width: double.infinity,
    //               child: ElevatedButton(
    //                 onPressed: () {
    //                   /// VALIDASI
    //                   if (dokumentasiList.isEmpty) {
    //                     ScaffoldMessenger.of(context).showSnackBar(
    //                       const SnackBar(
    //                         content: Text("Tambahkan minimal 1 dokumentasi"),
    //                       ),
    //                     );
    //                     return;
    //                   }
    //                   for (var item in dokumentasiList) {
    //                     if (item.image == null ||
    //                         item.keteranganController.text.isEmpty) {
    //                       ScaffoldMessenger.of(context).showSnackBar(
    //                         const SnackBar(
    //                           content: Text(
    //                             "Semua foto & keterangan harus diisi",
    //                           ),
    //                         ),
    //                       );
    //                       return;
    //                     }
    //                   }
    //                   /// LANJUT KE PDF (nanti kita sambung)
    //                   generatePdfFromList();
    //                 },
    //                 child: const Text("Simpan"),
    //               ),
    //             ),
    //             const SizedBox(height: 10),
    //           ],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
    return Scaffold(
      appBar: AppBar(title: const Text("Pesan"), centerTitle: true),
      body: const Center(
        child: Text(
          "Coming Soon",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class DokumentasiItem {
  XFile? image;
  TextEditingController keteranganController;

  DokumentasiItem({this.image, required this.keteranganController});
}
