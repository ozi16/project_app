import 'package:flutter/material.dart';
import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/detailtask.dart';
import 'package:teknisi_aag/services/api_service.dart';

class qrcodeTrap extends StatefulWidget {
  const qrcodeTrap({super.key, required String qrData});

  @override
  State<qrcodeTrap> createState() => _qrcodeTrapState();
}

class _qrcodeTrapState extends State<qrcodeTrap> {
  String result = "Scan QR Code";
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    // TextEditingController kodeController = TextEditingController(text: qrData);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: const Text("Isi Data")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenWidth,
              // // height: screenHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                // color: const Color.fromARGB(255, 194, 222, 248),
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      // color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Lantai 2",
                            style: TextStyle(
                              fontSize: 22,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Zona A",
                            style: TextStyle(
                              fontSize: 20,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nama Area',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final res = await ApiService.cekKondisiTask();
                        final data = res['data'];

                        if (data != null) {
                          final taskId =
                              int.tryParse('${data['task_id']}') ?? 0;
                          final clientId =
                              int.tryParse('${data['client_id']}') ?? 0;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailTask(
                                taskId: taskId,
                                clientId: clientId,
                                absenIn: data['absen_in']?.String(),
                                tugas: data['tugas'] == null
                                    ? null
                                    : int.tryParse('${data['tugas']}'),
                                signIn: data['sign_in']?.toString(),
                              ),
                            ),
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data berhasil disimpan!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        // fixedSize: Size(150, 45),
                      ),
                      child: Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
