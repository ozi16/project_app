import 'package:flutter/material.dart';
import 'package:teknisi_aag/BerandaPage/requestChenical.dart';
import 'package:teknisi_aag/BottomNavbar/beranda.dart';
import 'package:teknisi_aag/BottomNavbar/jadwal.dart';
import 'package:teknisi_aag/BottomNavbar/pesan.dart';
import 'package:teknisi_aag/BottomNavbar/profiile.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePage();
}

class _homePage extends State<homePage> {
  int _selectedTabIndex = 0;

  @override
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
      // super.initState();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenheight = MediaQuery.of(context).size.height;
    double inWidth = MediaQuery.of(context).size.width;
    double fontSize = MediaQuery.of(context).size.width;
    double iconSize = MediaQuery.of(context).size.width;

    final listPage = <Widget>[
      // const Text("Beranda"),
      Beranda(),
      // const Text("survey"),
      Jadwal(),
      // const Text("promo"),
      RequestChemicalPage(),
      // const Text("chat"),
      Pesan(),
      // const Text("profile"),
      Profile(),
    ];

    final bottonNavBarItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        label: "Beranda",
        icon: InkWell(child: Icon(Icons.home, size: iconSize * 0.08)),
      ),
      BottomNavigationBarItem(
        label: "Jadwal",
        icon: InkWell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Icon(Icons.calendar_month, size: iconSize * 0.08),
              ),
            ],
          ),
        ),
        //   child: Icon(
        // Icons.assignment, )
      ),
      BottomNavigationBarItem(
        label: "",
        icon: InkWell(
          child: Transform.translate(
            offset: const Offset(0, -1), // NAIK KE ATAS
            child: Container(
              width: screenWidth * 0.13,
              height: screenWidth * 0.13, // HARUS SAMA → BULAT
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 126, 180, 255),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ),
      ),

      BottomNavigationBarItem(
        label: "Pesan",
        icon: InkWell(child: Icon(Icons.monitor, size: iconSize * 0.08)),
      ),

      ///BOTTOM PROFILE
      BottomNavigationBarItem(
        label: "Akun",
        icon: InkWell(
          // onTap: () {
          //   setState(() {
          //     index_color = 4;
          //    _navigateWithoutTransition(ProfilePage());
          //   });
          // },
          child: Icon(
            Icons.person_pin,
            size: iconSize * 0.08,
            // color: index_color == 4 ? Colors.red : Colors.white,
          ),
        ),
      ),
    ];
    final bottomNavBar = BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      items: bottonNavBarItems,
      currentIndex: _selectedTabIndex,
      unselectedItemColor: Colors.grey,
      selectedItemColor: const Color(0xFF233d63),
      selectedFontSize: fontSize * 0.04,
      unselectedFontSize: fontSize * 0.03,
      onTap: _onNavBarTapped,
      iconSize: iconSize * 0.08,
    );

    return Scaffold(
      // appBar: Navbar(),
      body: Center(child: listPage[_selectedTabIndex]),
      bottomNavigationBar: bottomNavBar,
    );
  }
}
