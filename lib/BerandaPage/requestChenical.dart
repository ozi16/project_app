import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';
import 'package:teknisi_aag/constants/app_responsive.dart';
import 'package:teknisi_aag/services/api_service.dart';

class Item {
  final int cartId;
  final String namaBarang;
  final int qty;
  final int spv_qty;
  final int ms_qty;
  final int ga_qty;
  final int dirut_qty;

  Item({
    required this.cartId,
    required this.namaBarang,
    required this.qty,
    required this.spv_qty,
    required this.ms_qty,
    required this.ga_qty,
    required this.dirut_qty,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      cartId: json['cart_id'] ?? 0,
      namaBarang: json['nama_barang'] ?? '',
      qty: json['qty'] ?? 0,
      spv_qty: json['spv_qty'] ?? 0,
      ms_qty: json['ms_qty'] ?? 0,
      ga_qty: json['ga_qty'] ?? 0,
      dirut_qty: json['dirut_qty'] ?? 0,
    );
  }
}

class ReqModel {
  final String kodeTrx;
  final String namaCabang;
  final String area;
  final int selesai;
  final DateTime date;
  final int teknisiQty;
  final int spv;
  final int spvQty;
  final int ms;
  final int msQty;
  final int ga;
  final int gaQty;
  final int dirut;
  final int dirutQty;
  final List<Item> items; // Tambahkan field untuk list items
  // final String nama_barang;
  // final int qty;

  ReqModel({
    required this.kodeTrx,
    required this.namaCabang,
    required this.area,
    required this.selesai,
    required this.date,
    required this.teknisiQty,
    required this.spv,
    required this.spvQty,
    required this.ms,
    required this.msQty,
    required this.ga,
    required this.gaQty,
    required this.dirut,
    required this.dirutQty,
    // required this.nama_barang,
    // this.qty = 0,
    required this.items,
  });

  factory ReqModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    String toStr(dynamic value) {
      if (value == null) return '-'; // biar kelihatan kosong di UI
      return value.toString();
    }

    DateTime parseDate(dynamic value) {
      try {
        return DateTime.parse(value.toString().replaceAll(' ', 'T'));
      } catch (_) {
        return DateTime.now();
      }
    }

    return ReqModel(
      kodeTrx: toStr(json['kode_trx']),
      namaCabang: toStr(json['nama_cabang']), // ← tadinya NULL
      area: toStr(json['area']),
      selesai: toInt(json['selesai']), // ← tadinya NULL
      date: DateFormat('yyyy-MM-dd ').parse(json['date'].toString()),
      teknisiQty: toInt(json['teknisi_qty']),
      spv: toInt(json['spv']), // ← NULL
      spvQty: toInt(json['spv_qty']),
      ms: toInt(json['ms']),
      msQty: toInt(json['ms_qty']),
      ga: toInt(json['ga']),
      gaQty: toInt(json['ga_qty']),
      dirut: toInt(json['dirut']),
      dirutQty: toInt(json['dirut_qty']),
      // nama_barang: toStr(json['nama_barang']),
      // qty: toInt(json['qty']),
      items:
          (json['items'] as List?)
              ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RequestChemicalPage extends StatefulWidget {
  const RequestChemicalPage({super.key});

  @override
  State<RequestChemicalPage> createState() => _RequestChemicalPageState();
}

class _RequestChemicalPageState extends State<RequestChemicalPage> {
  int selectedIndex = 0;
  List<ReqModel> reqhistory = [];
  bool isLoading = true;
  bool showApproved = false;

  @override
  void initState() {
    super.initState();
    fetchReqChemHistory();
  }

  // 🔥 FILTER DATA
  List<ReqModel> get filteredData {
    if (selectedIndex == 0) return reqhistory;

    if (selectedIndex == 1) {
      // Status PROCESS: Jika 'selesai' bernilai null atau bukan 1
      return reqhistory
          .where((item) => item.selesai == null || item.selesai != 1)
          .toList();
    }

    // Status APPROVED: Jika 'selesai' bernilai 1
    return reqhistory.where((item) => item.selesai == 1).toList();
  }

  // ====================== AMBIL DATA DARI API ======================
  Future<void> fetchReqChemHistory() async {
    try {
      final data = await ApiService.getReqChemHistory();

      if (data == null) {
        throw Exception("Data null dari API");
      }

      if (data is! List) {
        throw Exception("Format data bukan List");
      }

      final requests = data.map<ReqModel>((e) => ReqModel.fromJson(e)).toList();

      setState(() {
        reqhistory = requests;
        isLoading = false;
      });

      print("✅ Success: $data");
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print("❌ Error fetching chemical request history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(
                AppSizes.hp(context, 0.16),
              ), // lebih tinggi
              child: AppBar(
                backgroundColor: const Color(0xFF1535D6),
                title: const Text(
                  "Progress Chemical",
                  style: TextStyle(color: Colors.white),
                ),
                centerTitle: true,
                elevation: 0,

                // 🔥 PINDAHKAN FILTER KE SINI
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildFilterTab(),
                        // const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: Column(
              children: [
                // const SizedBox(height: 16),
                // _buildFilterTab(),
                const SizedBox(height: 16),
                Expanded(child: _buildList()),
              ],
            ),
          );
  }

  // ======================
  // 🔵 FILTER TAB
  // ======================
  Widget _buildFilterTab() {
    final data = reqhistory; // ambil data pertama untuk cek status

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // semi transparan
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FilterTabItem(
            label: 'All',
            isSelected: selectedIndex == 0,
            onTap: () => setState(() => selectedIndex = 0),
          ),
          FilterTabItem(
            label: 'Progress',
            dotColor: Colors.orange,
            isSelected: selectedIndex == 1,
            onTap: () => setState(() => selectedIndex = 1),
          ),
          FilterTabItem(
            label: 'Approved',
            dotColor: Colors.green,
            isSelected: selectedIndex == 2,
            onTap: () => setState(() => selectedIndex = 2),
          ),
        ],
      ),
    );
  }

  // ======================
  // 📋 LIST DATA
  // ======================
  Widget _buildList() {
    final data = reqhistory;
    // final data = filteredData; // ✅ WAJIB
    // final formattedDate = DateFormat('dd MMM yyyy').format(data.date);

    if (data.isEmpty) {
      return const Center(child: Text("Tidak ada data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index]; // <- ini ReqModel

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailRequest(request: item),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 🔹 DATA
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.kodeTrx, // ✅ FIX
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(item.date), // bisa diformat nanti
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Team: ${item.area}", // ✅ FIX
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // 🔹 STATUS
                  _buildStatus(item.selesai), // ✅ FIX (int)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ======================
  // 🟢 STATUS BADGE
  // ======================
  Widget _buildStatus(int? selesai) {
    // Kondisi: Jika selesai == 1 maka Approved, selain itu (null/0) maka Process
    final bool isApproved = selesai == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // Warna background transparan mengikuti status
        color: isApproved
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApproved ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Text(
        isApproved ? "Approved" : "Process",
        style: TextStyle(
          color: isApproved ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ======================
// 🔘 FILTER TAB ITEM
// ======================
class FilterTabItem extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterTabItem({
    super.key,
    required this.label,
    this.dotColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
//            DETAIL PAGE
//===================================================

class DetailRequest extends StatefulWidget {
  const DetailRequest({super.key, required this.request});

  /// Baris yang dipilih dari list — dipakai sebagai sumber data detail
  /// supaya tidak bergantung pada `reqhistory[0]` (sering kosong / race).
  final ReqModel request;

  @override
  State<DetailRequest> createState() => _DetailRequestState();
}

class _DetailRequestState extends State<DetailRequest> {
  late ReqModel currentRequest;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentRequest = widget.request;
    fetchReqChemHistory();
  }

  Future<void> fetchReqChemHistory() async {
    try {
      final data = await ApiService.getReqChemHistory();

      if (data is! List) {
        throw Exception("Format data bukan List");
      }

      final requests = data
          .map<ReqModel>((e) => ReqModel.fromJson(e as Map<String, dynamic>))
          .toList();

      ReqModel? match;
      for (final r in requests) {
        if (r.kodeTrx == widget.request.kodeTrx) {
          match = r;
          break;
        }
      }

      setState(() {
        if (match != null) currentRequest = match;
        isLoading = false;
      });

      print("✅ Success: $data");
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      print("❌ Error fetching chemical request history: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            "Chemical Approved",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final formattedDate = DateFormat('dd MMM yyyy').format(currentRequest.date);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
        title: const Text(
          "Chemical Approved",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Proses Pengajuan Chemical",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "ID Pengajuan: ${currentRequest.kodeTrx} | $formattedDate ",
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),

            const SizedBox(height: 20),
            // ✅ Stepper
            _buildStepper(currentRequest),

            const SizedBox(height: 20),

            // ✅ Detail Chemical (Dynamic)
            _buildInfoCard(currentRequest),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ================= STEP =================
  // Baris atas: hanya avatar + garis (tinggi tetap) → garis sejajar pusat lingkaran.
  // Baris bawah: label — kolom sama lebar dengan baris atas (7 Expanded).

  static const double _stepAvatarRadius = 18;

  Widget _buildStepper(ReqModel data) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _stepAvatarRadius * 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Center(child: _stepAvatarOnly(data.spv == 1))),
              Expanded(child: _stepConnector(data.ms == 1)),
              Expanded(child: Center(child: _stepAvatarOnly(data.ms == 1))),
              Expanded(child: _stepConnector(data.ga == 1)),
              Expanded(child: Center(child: _stepAvatarOnly(data.ga == 1))),
              Expanded(child: _stepConnector(data.dirut == 1)),
              Expanded(child: Center(child: _stepAvatarOnly(data.dirut == 1))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _stepLabelsColumn("SPV", data.spv == 1)),
            const Expanded(child: SizedBox.shrink()),
            Expanded(child: _stepLabelsColumn("Manager Service", data.ms == 1)),
            const Expanded(child: SizedBox.shrink()),
            Expanded(child: _stepLabelsColumn("GA", data.ga == 1)),
            const Expanded(child: SizedBox.shrink()),
            Expanded(child: _stepLabelsColumn("DIREKTUR", data.dirut == 1)),
          ],
        ),
      ],
    );
  }

  Widget _stepAvatarOnly(bool isDone) {
    return CircleAvatar(
      radius: _stepAvatarRadius,
      backgroundColor: isDone ? Colors.green : Colors.grey,
      child: Icon(
        isDone ? Icons.check : Icons.access_time,
        size: 26,
        color: Colors.white,
      ),
    );
  }

  Widget _stepConnector(bool isDone) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: 3,
            width: constraints.maxWidth,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isDone ? Colors.green : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }

  Widget _stepLabelsColumn(String label, bool isDone) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          isDone ? "Approved" : "Pending",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isDone ? Colors.green : AppColors.orange,
          ),
        ),
      ],
    );
  }

  // ================= CARD =================

  Widget _buildInfoCard(ReqModel data) {
    final items = data.items; // akses list items dari ReqModel
    return Container(
      // width: AppSizes.wp(context, 100),
      // padding: const EdgeInsets.all(6),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(color: Colors.grey[300]!),
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataTable(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            dataRowHeight: 75,
            headingRowColor: MaterialStateProperty.all(AppColors.info),
            // decoration: BoxDecoration(
            //   // color: const Color.fromARGB(255, 216, 13, 13),
            //   borderRadius: BorderRadius.circular(18),
            //   border: Border.all(color: Colors.black),
            // ),
            columns: const <DataColumn>[
              DataColumn(
                label: Text(
                  'Nama',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qty',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Approved',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: items.map((item) {
              return DataRow(
                cells: <DataCell>[
                  DataCell(
                    Text(
                      item.namaBarang,
                      style: const TextStyle(
                        overflow: TextOverflow.clip, // TextOverflow.ellipsis
                      ),
                    ),
                  ), // akses nama barang dari Item
                  DataCell(
                    Text(item.qty.toString()),
                  ), // contoh akses nama barang
                  DataCell(
                    Text(getApprovedQty(item)),
                  ), // contoh status approval
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String getApprovedQty(Item item) {
    if ((item.dirut_qty ?? 0) > 0) {
      return item.dirut_qty.toString();
    } else if ((item.ga_qty ?? 0) > 0) {
      return item.ga_qty.toString();
    } else if ((item.ms_qty ?? 0) > 0) {
      return item.ms_qty.toString();
    } else if ((item.spv_qty ?? 0) > 0) {
      return item.spv_qty.toString();
    } else {
      return "-";
    }
  }
  // ================= ROW =================

  Widget _buildInfoRow(String label1, String val1, String label2, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: _textColumn(label1, val1)),
          Expanded(child: _textColumn(label2, val2)),
        ],
      ),
    );
  }

  Widget _textColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ================= MODEL =================
