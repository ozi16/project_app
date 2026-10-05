import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:teknisi_aag/BerandaPage/qrcodepage/qrcodeArea.dart';
import 'package:teknisi_aag/BerandaPage/qrcodepage/qrcodeTenant.dart';
import 'package:teknisi_aag/BerandaPage/qrcodepage/qrcodeTrap.dart';
// import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/detailtaks.dart';
// import 'package:teknisi_aag/BerandaPage/TugasTeknisiPage/signature.dart';
// import 'package:teknisi_aag/BerandaPage/qrcodepage/qrcodeArea.dart';
// import 'package:teknisi_aag/BerandaPage/qrcodepage/qrcodeTenant.dart';
// import 'package:teknisi_aag/BerandaPage/qrcodepage/qrcodeTrap.dart';

class QR extends StatefulWidget {
  const QR({super.key});

  @override
  State<QR> createState() => _QRState();
}

class _QRState extends State<QR> {
  String result = "Scan QR Code";
  bool isScanned = false;
  // bool isScanned = false;

  void handleQRCode(String code) {
    if (code.contains("/tenant/")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => qrcodeTenant(qrData: code)),
      );
    } else if (code.contains("/trap/")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => qrcodeTrap(qrData: code)),
      );
    } else if (code.contains("/index/")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => qrcodeArea(qrData: code)),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("QR Code tidak dikenali")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan QR Code"), centerTitle: true),

      body: MobileScanner(
        onDetect: (capture) {
          if (!isScanned) {
            final barcode = capture.barcodes.first;
            final String? code = barcode.rawValue;

            if (code != null) {
              isScanned = true;

              handleQRCode(code);
            }
          }
        },
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text("Scan QR Code"), centerTitle: true),
  //     body: Center(
  //       child: Column(
  //         // crossAxisAlignment: CrossAxisAlignment.center,
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => DetailTaks()),
  //               );
  //             },
  //             child: Text("Scan Qr Code Area"),
  //           ),
  //           SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => qrcodeTenant(qrData: 'tenant_data'),
  //                 ),
  //               );
  //             },
  //             child: Text("Scan Qr Code Tenant"),
  //           ),
  //           SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (context) => SignaturePage(taskId:929),
  //                 ),
  //               );
  //             },
  //             child: Text("Scan Qr Code Trap"),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
