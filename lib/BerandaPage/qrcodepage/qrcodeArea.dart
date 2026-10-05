import 'package:flutter/material.dart';

class qrcodeArea extends StatefulWidget {
  const qrcodeArea({super.key, required String qrData});

  @override
  State<qrcodeArea> createState() => _qrcodeAreaState();
}

class _qrcodeAreaState extends State<qrcodeArea> {
  String result = "Scan QR Code";
  bool isScanned = false;
  // late final String qrData;
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      // color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            " Area A",
                            style: TextStyle(
                              fontSize: 22,
                              // fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Text(
                          //   "Lt. 2",
                          //   style: TextStyle(
                          //     fontSize: 20,
                          //     // fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      // controller: kodeController,
                      decoration: const InputDecoration(
                        labelText: "Kode dari QR",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nama Area',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),

                    DropdownMenu(
                      width: screenWidth,
                      label: Text('-- Pilih Kondisi Perangkap --'),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(value: 'option1', label: 'Option 1'),
                        DropdownMenuEntry(value: 'option2', label: 'Option 2'),
                        DropdownMenuEntry(value: 'option3', label: 'Option 3'),
                      ],
                    ),

                    SizedBox(height: 10),

                    DropdownMenu(
                      width: screenWidth,
                      label: Text('-- Pilih Kondisi Racun --'),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(value: 'option1', label: 'Option 1'),
                        DropdownMenuEntry(value: 'option2', label: 'Option 2'),
                        DropdownMenuEntry(value: 'option3', label: 'Option 3'),
                      ],
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      // width: double.infinity,
                      width: screenWidth * 0.9,
                      // color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.5,
                            child: DropdownMenu(
                              width: screenWidth,
                              label: Text('-- Pilih Hama --'),
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                  value: 'option1',
                                  label: 'Option 1',
                                ),
                                DropdownMenuEntry(
                                  value: 'option2',
                                  label: 'Option 2',
                                ),
                                DropdownMenuEntry(
                                  value: 'option3',
                                  label: 'Option 3',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.3,

                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Qty',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Noted',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Logika untuk menyimpan data ke database atau server
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data berhasil disimpan!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        // fixedSize: Size(150, 45),
                      ),
                      child: Text(
                        'Simpan Data',
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

// class FormPage extends StatelessWidget {
//   final String qrData;

//   const FormPage({super.key, required this.qrData});

//   @override
//   Widget build(BuildContext context) {
//     TextEditingController kodeController = TextEditingController(text: qrData);
//     double screenWidth = MediaQuery.of(context).size.width;
//     double screenHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       appBar: AppBar(title: const Text("Isi Data")),

//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Container(
//               width: screenWidth,
//               // height: screenHeight,
//               color: const Color.fromARGB(255, 194, 222, 248),
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       // color: Colors.white,
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Mall AEON",
//                             style: TextStyle(
//                               fontSize: 22,
//                               // fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             "Lt. 2",
//                             style: TextStyle(
//                               fontSize: 20,
//                               // fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     TextField(
//                       controller: kodeController,
//                       decoration: const InputDecoration(
//                         labelText: "Kode dari QR",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),

//                     SizedBox(height: 8),

//                     TextField(
//                       decoration: InputDecoration(
//                         hintText: 'Nama Area',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     SizedBox(height: 8),

//                     DropdownMenu(
//                       width: screenWidth,
//                       label: Text('-- Pilih Kondisi Perangkap --'),
//                       dropdownMenuEntries: [
//                         DropdownMenuEntry(value: 'option1', label: 'Option 1'),
//                         DropdownMenuEntry(value: 'option2', label: 'Option 2'),
//                         DropdownMenuEntry(value: 'option3', label: 'Option 3'),
//                       ],
//                     ),

//                     SizedBox(height: 8),

//                     DropdownMenu(
//                       width: screenWidth,
//                       label: Text('-- Pilih Kondisi Racun --'),
//                       dropdownMenuEntries: [
//                         DropdownMenuEntry(value: 'option1', label: 'Option 1'),
//                         DropdownMenuEntry(value: 'option2', label: 'Option 2'),
//                         DropdownMenuEntry(value: 'option3', label: 'Option 3'),
//                       ],
//                     ),
//                     SizedBox(height: 8),
//                     Container(
//                       // width: double.infinity,
//                       width: screenWidth * 0.9,
//                       // color: Colors.white,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Container(
//                             width: screenWidth * 0.5,
//                             child: DropdownMenu(
//                               width: screenWidth,
//                               label: Text('-- Pilih Hama --'),
//                               dropdownMenuEntries: [
//                                 DropdownMenuEntry(
//                                   value: 'option1',
//                                   label: 'Option 1',
//                                 ),
//                                 DropdownMenuEntry(
//                                   value: 'option2',
//                                   label: 'Option 2',
//                                 ),
//                                 DropdownMenuEntry(
//                                   value: 'option3',
//                                   label: 'Option 3',
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Container(
//                             width: screenWidth * 0.3,

//                             child: TextField(
//                               decoration: InputDecoration(
//                                 hintText: 'Qty',
//                                 border: OutlineInputBorder(),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     TextField(
//                       decoration: InputDecoration(
//                         hintText: 'Noted',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () {
//                         // Logika untuk menyimpan data ke database atau server
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Data berhasil disimpan!')),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         fixedSize: Size(150, 45),
//                       ),
//                       child: Text(
//                         'Simpan Data',
//                         style: TextStyle(color: Colors.white, fontSize: 18),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
