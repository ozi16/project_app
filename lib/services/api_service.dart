import 'dart:convert';
import 'dart:io' as io;
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseApp = 'https://test.atrindo.network/api';
  static const String baseReport = 'https://report.atrindo.network/api';

  // static get baseReport => null;

  static Map<String, String> _headers({bool token = false}) {
    final box = Hive.box('loginBox');
    final tkn = box.get('token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token) 'Authorization': 'Bearer $tkn',
    };
  }

  /// POST JSON tanpa mengubah method saat redirect (301/302).
  /// Paket http default bisa mengubah POST → GET saat follow redirect → 405 di Laravel.
  static Future<http.Response> _postJsonPreserveMethod(
    Uri url, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final httpClient = io.HttpClient();
    try {
      var currentUrl = url;
      for (var attempt = 0; attempt < 5; attempt++) {
        final request = await httpClient.postUrl(currentUrl);
        request.followRedirects = false;
        headers.forEach(request.headers.set);
        request.write(body);

        final ioResponse = await request.close();
        final responseBody = await ioResponse.transform(utf8.decoder).join();

        final isRedirect =
            ioResponse.statusCode >= 300 && ioResponse.statusCode < 400;
        final location = ioResponse.headers.value('location');

        if (isRedirect && location != null && location.isNotEmpty) {
          currentUrl = location.startsWith('http')
              ? Uri.parse(location)
              : currentUrl.resolve(location);
          continue;
        }

        final responseHeaders = <String, String>{};
        ioResponse.headers.forEach((name, values) {
          responseHeaders[name] = values.join(',');
        });

        return http.Response(
          responseBody,
          ioResponse.statusCode,
          headers: responseHeaders,
        );
      }
      throw Exception('Terlalu banyak redirect dari server');
    } finally {
      httpClient.close(force: true);
    }
  }

  static Future<String> convertToBase64(io.File file) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 40, // 🔥 penting (biar tidak 422)
      minWidth: 800,
      minHeight: 800,
    );

    if (compressed == null) throw Exception("Compress gagal");

    return base64Encode(compressed);
  }

  // ================= POST LOGIN =================
  static Future<dynamic> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseReport/login'),
        headers: _headers(),
        body: jsonEncode({"email": email, "password": password}),
      );

      // print("STATUS: ${res.statusCode}");
      // print("BODY: $res");

      final data = jsonDecode(res.body);
      return data;
      // if (res.statusCode == 200) {
      // } else {
      //   return {
      //     "success": false,
      //     "message": "Server error (${res.statusCode})",
      //   };
      // }
    } catch (e) {
      return {"success": false, "message": "Tidak bisa koneksi ke server"};
    }
  }

  // ================= GET CHEMICAL =================
  static Future<List<dynamic>> getChemical() async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final res = await http.get(
      Uri.parse("$baseReport/teknisiRequest/getChemical"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      if (body['success'] == true) {
        return body['data'];
      } else {
        throw Exception("API success false");
      }
    } else {
      throw Exception("Gagal ambil data (${res.statusCode})");
    }
  }

  // ================= GET CLIENT =================
  static Future<List<dynamic>> getClient() async {
    final res = await http.get(
      Uri.parse('$baseReport/me/clients'),
      headers: _headers(token: true),
    );
    // print("STATUS: ${res.statusCode}");
    // print("BODY: ${res.body}");
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      return jsonData['data'] ?? []; // 🔥 INI KUNCINYA
    } else {
      throw Exception('Gagal load client');
    }
  }

  // ================= GET JADWAL =================
  static Future<List<dynamic>> getJadwal() async {
    var box = Hive.box('loginBox');
    String? token = box.get('token');

    final res = await http.get(
      Uri.parse('$baseReport/jadwal'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      return jsonData['data'] ?? [];
    } else {
      throw Exception('API ERROR ${res.statusCode}');
    }
  }

  // ================= GET HISTORY =================
  static Future<List<dynamic>> getHistory() async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final res = await http.get(
      Uri.parse('$baseReport/history'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    // print("STATUS: ${res.statusCode}");
    // print("BODY: ${res.body}");
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      // ✅ FIX: ambil langsung list data
      return jsonData['data'] ?? [];
    } else {
      throw Exception('Gagal load history');
    }
  }

  // ================= POST ABSENSI CHECKIN =================
  /// Mengembalikan body response JSON jika sukses, null jika gagal.
  static Future<Map<String, dynamic>?> sendCheckin({
    required int clientId,
    required String info,
    required String base64Image,
    required String? lat,
    required String? long,
    required String token,
  }) async {
    final url = Uri.parse('$baseReport/absen/store');

    final body = {
      "client_id": clientId,
      "info": info,
      "data": "data:image/png;base64,$base64Image",
      "lat": lat,
      "long": long,
    };

    final box = await Hive.openBox('checkinBox');

    try {
      print("=== REQUEST ===");
      print(jsonEncode(body));

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("=== RESPONSE ===");
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      Map<String, dynamic>? resBody;
      int? taskId;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          resBody = decoded;
        } else if (decoded is Map) {
          resBody = Map<String, dynamic>.from(decoded);
        }
        final nested = resBody?['data'];
        final nestedMap = nested is Map ? Map<String, dynamic>.from(nested) : null;
        taskId = resBody?['task_id'] ??
            nestedMap?['task_id'] ??
            nestedMap?['id'] ??
            resBody?['id'];
      } catch (e) {
        print("ERROR PARSE JSON: $e");
      }

      // ✅ SUCCESS
      if (response.statusCode == 200 || response.statusCode == 201) {
        await box.add({
          "client_id": clientId,
          "task_id": taskId,
          "info": info,
          "image": base64Image,
          "lat": lat,
          "long": long,
          "status": "success",
          "created_at": DateTime.now().toString(),
        });

        return resBody;
      } else {
        // ❌ FAILED
        await box.add({
          "client_id": clientId,
          "task_id": taskId,
          "info": info,
          "image": base64Image,
          "lat": lat,
          "long": long,
          "status": "failed",
          "created_at": DateTime.now().toString(),
        });

        return null;
      }
    } catch (e) {
      print("ERROR API: $e");

      await box.add({
        "client_id": clientId,
        "task_id": null,
        "info": info,
        "image": base64Image,
        "lat": lat,
        "long": long,
        "status": "error",
        "created_at": DateTime.now().toString(),
      });

      return null;
    }
  }

  // ================= POST ABSENSI CHECKOUT =================
  static Future<bool> sendCheckOut({
    required int clientId,
    required int taskId,
    required String info,
    required String base64Image,
    required String? lat,
    required String? long,
  }) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final url = Uri.parse('$baseReport/absen/store');

    final body = {
      "client_id": clientId,
      "task_id": taskId,
      "info": info,
      "data": "data:image/jpeg;base64,$base64Image",
      "lat": lat, // 🔥 double, bukan string
      "long": long, // 🔥 double, bukan string
    };

    print("data logout $body");

    try {
      print("=== REQUEST ===");
      print(jsonEncode(body));

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      print("=== RESPONSE ===");
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("ERROR API: $e");
      return false;
    }
  }

  // ================= GET TASK BY TASK_ID =================
  static Future<List<dynamic>> getTasks({required int taskId}) =>
      _getReportByTask('doc-treat', taskId);

  static Future<List<dynamic>> getRekomendasiByTask(int taskId) =>
      _getReportByTask('doc-temuan', taskId);

  static Future<List<dynamic>> getChecklistByTask(int taskId) =>
      _getReportByTask('checklist', taskId);

  static Future<List<dynamic>> getChemicalUsedByTask(int taskId) =>
      _getReportByTask('chemical-used', taskId);

  static Future<List<dynamic>> _getReportByTask(
    String endpoint,
    int taskId,
  ) async {
    final box = Hive.box('loginBox');
    final token = box.get('token')?.toString();
    final url = '$baseReport/$endpoint/$taskId';

    final res = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      if (jsonData is Map && jsonData['data'] is List) {
        return jsonData['data'];
      }
      if (jsonData is Map && jsonData['data'] != null) {
        return [jsonData['data']];
      }
      if (jsonData is List) return jsonData;
      return [];
    }

    print("data task: ${res.statusCode}");
    print("ERROR: ${res.body}");

    if (res.statusCode == 404) return [];

    throw Exception('Gagal load $endpoint (${res.statusCode})');
  }

  /// Cek apakah [taskName] sudah ada di response API untuk [taskId].
  static bool hasTaskName(List<dynamic> list, int taskId, String taskName) {
    if (list.isEmpty) return false;

    final target = taskName.toUpperCase();
    return list.any((item) {
      if (item is! Map) return false;
      final id = int.tryParse('${item['task_id']}') ?? 0;
      final name = '${item['task_name']}'.toUpperCase();
      if (id == taskId && name == target) return true;
      // Endpoint per task_id: data tidak kosong = sudah ada
      if ((id == 0 || id == taskId) &&
          (item['items'] != null || item['data'] != null || item['photo'] != null)) {
        return name.isEmpty || name == target;
      }
      return false;
    });
  }

  // ================= POST TREATMENT TASK =================
  static Future<void> sendTreatment({
    required int taskId,
    required List<Map<String, dynamic>> items,
    required String taskName,
  }) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();

    final res = await http.post(
      Uri.parse('$baseReport/doc-treat'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "task_id": taskId,
        "task_name": taskName,
        "items": items,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Gagal upload ${res.statusCode}");
    }
  }

  // ================= POST REKOMENDASI TREATMENT TASK =================
  static Future<void> sendRekomendasi({
    required int taskId,
    required List<Map<String, dynamic>> items,
    required String taskName,
  }) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();

    final res = await http.post(
      Uri.parse('$baseReport/doc-temuan'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "task_id": taskId,
        "task_name": taskName,
        "items": items,
      }),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Gagal upload ${res.statusCode}");
    }
  }

  // ================= POST CHECKLIST TASK =================
  static Future<dynamic> sendChecklist({
    required int taskId,
    required List<Map<String, dynamic>> data,
    required String taskName,
  }) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();

    final body = {"task_id": taskId, "task_name": taskName, "data": data};

    print("SEND BODY: ${jsonEncode(body)}");

    final res = await http.post(
      Uri.parse('$baseReport/checklist'),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal kirim checklist');
    }
  }

  // ================= GET PEST CHECKLIST TASK =================
  static Future<List<dynamic>> getPest() async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final res = await http.get(
      Uri.parse('$baseReport/pest'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    // print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      return jsonData['data'];
    } else {
      throw Exception('Gagal load pest');
    }
  }

  // ================= GET TRAP CHECKLIST TASK =================
  static Future<List<dynamic>> getTrap() async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final res = await http.get(
      Uri.parse('$baseReport/trap'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    // print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");
    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      return jsonData['data'];
    } else {
      throw Exception('Gagal load pest');
    }
  }

  // ================= GET CHEMICAL USED GET TASK =================
  static Future<List<dynamic>> getChemicalUsed() async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final response = await http.get(
      Uri.parse("$baseReport/chemical-used"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // kalau response: {data: [...]}
      if (data is Map && data.containsKey('data')) {
        return data['data'];
      }

      // kalau langsung list
      if (data is List) {
        return data;
      }

      return [];
    } else {
      throw Exception("Gagal ambil data: ${response.statusCode}");
    }
  }

  // ================= POST CHEMICAL USED TASK =================
  static Future<bool> sendChemical(
    int taskId,
    List<Map<String, dynamic>> items, {
    required String taskName,
  }) async {
    final box = Hive.box('loginBox');
    String token = box.get('token') ?? "";

    final body = {"task_id": taskId, "task_name": taskName, "items": items};

    print("SEND BODY: ${jsonEncode(body)}");

    final response = await http.post(
      Uri.parse("$baseReport/chemical-used"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("POST STATUS: ${response.statusCode}");
    print("POST BODY: ${response.body}");

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ================= POST SIGN-IN TASK =================
  static Future<Map<String, dynamic>> sendSignature({
    required int taskId,
    required String photo,
    required String stamp,
  }) async {
    final box = Hive.box('loginBox');
    final token = box.get('token')?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Token login tidak ditemukan. Silakan login ulang.');
    }

    final url = Uri.parse('$baseReport/task/sign-in');
    final encodedBody = jsonEncode({
      'task_id': taskId,
      'photo': photo,
      'stamp': stamp,
    });

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    print('SIGNATURE POST → $url');
    print('SIGNATURE BODY SIZE: ${encodedBody.length} bytes');

    final response = await _postJsonPreserveMethod(
      url,
      headers: headers,
      body: encodedBody,
    );

    print('SIGNATURE STATUS: ${response.statusCode}');
    print('SIGNATURE BODY: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload gagal (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  // ================= POST AADCART =================
  static Future<int?> addCart(int cartId, int qty) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();

    final res = await http.post(
      Uri.parse("$baseReport/teknisiRequest/addCart"),
      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
      body: {"cart_id": cartId.toString(), "qty": qty.toString()},
    );

    print("ADD CART STATUS: ${res.statusCode}");
    print("ADD CART BODY: ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body);

      if (body['data'] is Map) {
        return body['data']['cart_id'];
      } else {
        return body['data'];
      }
    } else {
      throw Exception("Gagal add cart: ${res.body}");
    }
  }

  // ================= POST DELETECART =================
  static Future<void> delCart(int id_order) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final res = await http.post(
      Uri.parse("$baseReport/teknisiRequest/delCart"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      // Use form fields for compatibility with typical PHP/Laravel request parsing
      body: {"id_order": id_order.toString()},
    );
    print("delete cart id_order: $id_order");
    print("DELETE CART STATUS: ${res.statusCode}");
    print("DELETE CART BODY: ${res.body}");
  }

  // ================= POST UPDATEQTY =================
  static Future addQty({
    required int idOrder,
    required int qty,
    required String status,
  }) async {
    final box = Hive.box('loginBox');

    String? token = box.get('token')?.toString();

    final response = await http.post(
      Uri.parse("$baseReport/teknisiRequest/addQty"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
      body: {
        "id_order": idOrder.toString(),
        "qty": qty.toString(),
        "status": status,
      },
    );

    print(response.body);

    if (response.statusCode != 200) {
      throw Exception("Gagal add qty: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  // ================= GET CART =================
  static Future<List<dynamic>> getCart() async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    int? id = int.tryParse(box.get('id')?.toString() ?? '');
    final res = await http.get(
      Uri.parse("$baseReport/teknisiRequest/getCart/$id"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print("GET CART STATUS: ${res.statusCode}");
    print("GET CART BODY: ${res.body}");

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        return body['data'] ?? [];
      } else {
        throw Exception("API success false");
      }
    } else {
      throw Exception("Gagal ambil data (${res.statusCode})");
    }
  }

  // ================= POST SENDREQUEST =================
  static Future<void> sendRequest(String area) async {
    final box = Hive.box('loginBox');
    String? token = box.get('token')?.toString();
    final res = await http.post(
      Uri.parse("$baseReport/teknisiRequest/sendRequest"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },

      body: jsonEncode({"area": area}),
    );
    print("send request area: $area");
    print("SEND REQUEST STATUS: ${res.statusCode}");
    print("SEND REQUEST BODY: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Gagal kirim request: ${res.body}");
    }
  }

  // ================= GET CEK KONDISI TASK =================
  static Future<Map<String, dynamic>> cekKondisiTask() async {
    var box = Hive.box('loginBox');
    String? token = box.get('token');

    final res = await http.get(
      Uri.parse('$baseReport/task/active-visit'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );
    // print("STATUS: ${res.statusCode}");
    // print("BODY: ${res.body}");
    if (res.statusCode == 200) {
      return jsonDecode(res.body); // ✅ FULL response
    } else {
      throw Exception('API ERROR ${res.statusCode}');
    }
  }

  // ================= GET HISTORY REQUEST CHEMICAL  =================
  static Future<List<dynamic>> getReqChemHistory() async {
    var box = Hive.box('loginBox');
    String? token = box.get('token');

    final res = await http.get(
      Uri.parse('$baseReport/teknisiRequest/history'),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");
      return jsonData['data'] ?? [];
    } else {
      throw Exception('API ERROR ${res.statusCode}');
    }
  }
}
