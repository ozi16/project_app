import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:teknisi_aag/BerandaPage/chemical.dart';
import 'package:teknisi_aag/BottomNavbar/beranda.dart';
import 'package:teknisi_aag/BottomNavbar/jadwal.dart';
import 'package:teknisi_aag/BottomNavbar/profiile.dart';
import 'package:teknisi_aag/homepage.dart';
import 'package:teknisi_aag/loginPage.dart';
import 'package:intl/date_symbol_data_local.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('loginBox');
  await Hive.openBox('tokenBox');
  await Hive.openBox('checkinBox');
  await Hive.openBox('dokumentasirekomendasiBox');
  await Hive.openBox('dokumentasitreatmentBox');
  await Hive.openBox('jadwalBox');
  final box = Hive.box('loginBox');
  bool isLoggedIn = box.get('isLoggedIn', defaultValue: false);
  // final box = await Hive.openBox('checkinBox');
  await initializeDateFormatting('id_ID', null);
  home:
  isLoggedIn ? const homePage() : const LoginPage();
  runApp(const MyApp());
  // runApp(
  //   DevicePreview(
  //     builder: (context) => MyApp(), // Aplikasi utama Anda
  //   ),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  get navigatorKey => null;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      navigatorKey: navigatorKey,

      routes: {
        '/': (context) => LoginPage(),
        // '/': (context) => homePage(),
        '/homepage': (context) => homePage(),
        '/beranda': (context) => const Beranda(),
        '/profile': (context) => const Profile(),
        '/jadwal': (context) => const Jadwal(),
        '/chemical': (context) => const ChemicalPage(),
      },
    );
  }
}
