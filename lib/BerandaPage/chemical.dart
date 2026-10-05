import 'package:flutter/material.dart';
import 'package:teknisi_aag/constants/app__Colors.dart';

import '../services/api_service.dart';

/// ================= MODEL =================
class cartModel {
  final int id_order;
  int cart_id;
  int qty;
  final int cart_user;
  final String nama_barang;
  cartModel({
    required this.id_order,
    required this.cart_id,
    required this.qty,
    required this.cart_user,
    required this.nama_barang,
  });

  factory cartModel.fromJson(Map<String, dynamic> json) {
    return cartModel(
      id_order: json['id_order'] ?? 0,
      cart_id: json['cart_id'] ?? 0,
      qty: json['qty'] ?? 0,
      cart_user: json['cart_user'] ?? 0,
      nama_barang: json['nama_barang'] ?? "",
    );
  }
}

class ChemicalModel {
  final int cart_id;
  final String namaBarang;

  ChemicalModel({required this.cart_id, required this.namaBarang});

  factory ChemicalModel.fromJson(Map<String, dynamic> json) {
    return ChemicalModel(
      cart_id: json['id_che'] ?? 0,
      namaBarang: json['nama_barang'] ?? "",
    );
  }
}

class SelectedChemical {
  final ChemicalModel chemical;
  int qty;
  int? idOrder;

  SelectedChemical({required this.chemical, this.qty = 1, this.idOrder});
}

/// ================= PAGE =================
class ChemicalPage extends StatefulWidget {
  const ChemicalPage({super.key});

  @override
  State<ChemicalPage> createState() => _ChemicalPageState();
}

class _ChemicalPageState extends State<ChemicalPage> {
  List<ChemicalModel> allChemical = [];
  List<ChemicalModel> filteredChemical = [];
  List<SelectedChemical> selectedChemical = [];
  List<cartModel> cart = [];
  final Map<int, TextEditingController> qtyControllers = {};
  final Map<int, FocusNode> focusNodes = {};
  final Map<int, bool> isUpdatingQtyByCartId = {};
  // int qty = 134; // Data awal
  bool isAdding = false;
  bool isLoading = true;

  int get totalItem => cart.fold(0, (sum, item) => sum + item.qty);

  Future<void> _onQtyBlur(int idOrder) async {
    final controller = qtyControllers[idOrder];
    if (controller == null) return;

    final itemIndex = cart.indexWhere((c) => c.id_order == idOrder);
    if (itemIndex == -1) return;
    final item = cart[itemIndex];

    // If user typed a new number and then clicked elsewhere, commit it.
    final raw = controller.text.trim();
    if (raw.isEmpty) {
      controller.text = item.qty.toString();
      return;
    }

    // Avoid double-sending while another update is running.
    if (isUpdatingQtyByCartId[idOrder] == true) {
      controller.text = item.qty.toString();
      return;
    }

    if (raw != item.qty.toString()) {
      await updateManualQty(item, raw);
    } else {
      controller.text = item.qty.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChemical();
    getCart();
  }

  /// ================= GET CART =================
  Future<void> getCart() async {
    try {
      final data = await ApiService.getCart();
      setState(() {
        cart = data.map((e) => cartModel.fromJson(e)).toList();
      });
      // Handle the retrieved cart data
    } catch (e) {
      debugPrint("ERROR GET CART: $e");
    }
  }

  /// ================= FETCH =================
  Future<void> fetchChemical() async {
    try {
      final data = await ApiService.getChemical();
      setState(() {
        allChemical = data.map((e) => ChemicalModel.fromJson(e)).toList();
        filteredChemical = allChemical;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR FETCH: $e");
    }
  }

  /// ================= SEARCH =================
  void searchChemical(String value) {
    setState(() {
      filteredChemical = allChemical
          .where(
            (e) => e.namaBarang.toLowerCase().contains(value.toLowerCase()),
          )
          .toList();
    });
  }

  /// ================= ADD CART =================
  Future<void> addChemical(ChemicalModel item) async {
    if (isAdding) return;
    setState(() => isAdding = true);
    try {
      /// 🔥 CREATE CART (INI SUDAH SEKALIGUS POST)
      await ApiService.addCart(item.cart_id, 1);
      await getCart();
    } catch (e) {
      debugPrint("ERROR ADD: $e");
    }

    setState(() => isAdding = false);
  }

  /// ================= ADD CART QTY =================
  Future<void> addQty(cartModel item) async {
    if (isUpdatingQtyByCartId[item.id_order] == true) return;

    setState(() {
      isUpdatingQtyByCartId[item.id_order] = true;
      item.qty++;
    });

    qtyControllers[item.id_order]?.text = item.qty.toString();

    try {
      await ApiService.addQty(idOrder: item.id_order, qty: 1, status: "plus");
    } catch (e) {
      debugPrint("ERROR ADD QTY: $e");

      setState(() {
        item.qty--;
        qtyControllers[item.id_order]?.text = item.qty.toString();
      });
    } finally {
      setState(() {
        isUpdatingQtyByCartId[item.id_order] = false;
      });
    }
  }

  /// ================= REMOVE CART QTY =================
  Future<void> decreaseCartQty(cartModel item) async {
    if (item.qty <= 1) return;

    if (isUpdatingQtyByCartId[item.id_order] == true) return;

    setState(() {
      isUpdatingQtyByCartId[item.id_order] = true;
      item.qty--;
    });

    qtyControllers[item.id_order]?.text = item.qty.toString();

    try {
      await ApiService.addQty(idOrder: item.id_order, qty: 1, status: "minus");
    } catch (e) {
      debugPrint("ERROR DECREASE QTY: $e");

      setState(() {
        item.qty++;
        qtyControllers[item.id_order]?.text = item.qty.toString();
      });
    } finally {
      setState(() {
        isUpdatingQtyByCartId[item.id_order] = false;
      });
    }
  }

  /// ================= INPUT MANUAL QTY =================
  Future<void> updateManualQty(cartModel item, String value) async {
    if (isUpdatingQtyByCartId[item.id_order] == true) {
      qtyControllers[item.id_order]?.text = item.qty.toString();
      return;
    }

    int? newQty = int.tryParse(value);

    if (newQty == null || newQty <= 0) {
      qtyControllers[item.id_order]?.text = item.qty.toString();
      return;
    }

    final oldQty = item.qty;

    final diff = newQty - oldQty;

    if (diff == 0) return;

    setState(() {
      isUpdatingQtyByCartId[item.id_order] = true;
      item.qty = newQty;
    });

    try {
      // Backend memproses update qty berdasarkan `status`.
      // Untuk input manual, gunakan mode "jumping" (set qty langsung).
      await ApiService.addQty(
        idOrder: item.id_order,
        qty: newQty,
        status: "jumping",
      );
    } catch (e) {
      debugPrint("ERROR UPDATE MANUAL QTY: $e");

      setState(() {
        item.qty = oldQty;
        qtyControllers[item.id_order]?.text = oldQty.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingQtyByCartId[item.id_order] = false;
        });
      }
    }
  }

  /// ================= DELETE CART =================
  Future<void> removeChemical(cartModel id_order) async {
    final item = cart[cart.indexWhere((c) => c.id_order == id_order.id_order)];
    if (isUpdatingQtyByCartId[item.id_order] == true) return;
    setState(() => isUpdatingQtyByCartId[item.id_order] = true);
    try {
      await ApiService.delCart(item.id_order);
      qtyControllers.remove(item.id_order);
      focusNodes.remove(item.id_order);
      await getCart();
    } catch (e) {
      debugPrint("ERROR DELETE CART: $e");
    } finally {
      if (mounted) {
        setState(() => isUpdatingQtyByCartId[item.id_order] = false);
      }
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(screenHeight * 0.15),
          child: AppBar(
            centerTitle: true,
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
              " Data Chemical & Non Chemical",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
            //     onPressed: _refresh,
            //   ),
            // ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(screenHeight * 0.05),
              child: Container(
                margin: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white70),
                  onChanged: searchChemical,
                  decoration: const InputDecoration(
                    hintText: 'Search chemical...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filteredChemical.length,
                        itemBuilder: (context, index) {
                          final item = filteredChemical[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                /// ICON BULAT
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.science,
                                    color: Colors.blue,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                /// NAMA
                                Expanded(
                                  child: Text(
                                    item.namaBarang,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                /// BUTTON +
                                GestureDetector(
                                  onTap: () => addChemical(item),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              /// ================= SELECTED =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔥 HEADER
                    Row(
                      children: const [
                        Icon(Icons.assignment, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Selected Chemical",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// 🔥 LIST
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          final controller = qtyControllers.putIfAbsent(
                            item.id_order,
                            () => TextEditingController(
                              text: item.qty.toString(),
                            ),
                          );
                          final node = focusNodes.putIfAbsent(
                            item.id_order,
                            () {
                              final node = FocusNode();

                              node.addListener(() async {
                                if (!node.hasFocus) {
                                  await _onQtyBlur(item.id_order);
                                }
                              });

                              return node;
                            },
                          );

                          // Sinkronkan tampilan qty dengan data API (tanpa ganggu saat user lagi edit)
                          if (!node.hasFocus &&
                              controller.text != item.qty.toString()) {
                            controller.text = item.qty.toString();
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                /// 🔵 ICON BULAT
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.science,
                                    color: Colors.blue,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// 🔥 NAMA
                                Expanded(
                                  child: Text(
                                    item.nama_barang,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                /// 🔥 QTY CONTROL
                                Row(
                                  children: [
                                    /// MINUS
                                    GestureDetector(
                                      onTap: () => decreaseCartQty(item),
                                      child: _qtyButton(
                                        Icons.remove,
                                        Colors.grey.shade300,
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    /// INPUT
                                    Container(
                                      width: 45,
                                      height: 35,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: controller,
                                        focusNode: node,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        readOnly: false,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onSubmitted: (value) {
                                          updateManualQty(item, value);
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    // / PLUS
                                    GestureDetector(
                                      onTap: () => addQty(item),
                                      child: _qtyButton(
                                        Icons.add,
                                        Colors.blue,
                                        true,
                                      ),
                                    ),
                                    const SizedBox(width: 6),

                                    // / DELETE
                                    GestureDetector(
                                      onTap: () => removeChemical(item),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              /// ================= SUBMIT =================
              ElevatedButton(
                onPressed: () => showRequestDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text("Submit", style: TextStyle(fontSize: 18)),
                    Text("Qty : $totalItem", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔥 BUTTON STYLE
  Widget _qtyButton(IconData icon, Color color, [bool isWhite = false]) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: isWhite ? Colors.white : Colors.black),
    );
  }

  /// ================= DIALOG =================
  void showRequestDialog(BuildContext context) {
    final TextEditingController areaController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 🔥 HEADER
                    Row(
                      children: const [
                        Icon(Icons.location_on, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Input Area",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// 🔥 INPUT
                    TextField(
                      controller: areaController,
                      decoration: InputDecoration(
                        hintText: "Contoh: Team Jakarta",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// 🔥 BUTTON
                    Row(
                      children: [
                        /// CANCEL
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Batal"),
                          ),
                        ),
                        const SizedBox(width: 10),

                        /// SUBMIT
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final area = areaController.text.trim();

                                    if (area.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Nama area wajib diisi",
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setStateDialog(() => isLoading = true);
                                    try {
                                      await ApiService.sendRequest(area);

                                      /// 🔥 CLEAR CART
                                      setState(() {
                                        cart.clear();
                                        qtyControllers.clear();
                                        focusNodes.clear();
                                      });

                                      Navigator.pop(context);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Berhasil kirim"),
                                        ),
                                      );
                                    } catch (e) {
                                      setStateDialog(() => isLoading = false);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text("Error: $e")),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            /// 🔥 LOADING LEBIH HALUS
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isLoading
                                  ? const SizedBox(
                                      key: ValueKey("loading"),
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text("Submit", key: ValueKey("text")),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
