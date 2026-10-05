import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:teknisi_aag/loginPage.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String name = "";
  String email = "";
  String levelLabel = "";
  String photo = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() {
    final box = Hive.box('loginBox');

    setState(() {
      name = box.get('name', defaultValue: "");
      email = box.get('email', defaultValue: "");
      levelLabel = box.get('level_label', defaultValue: "");
      photo = box.get('photo', defaultValue: "");
    });

    // DEBUG
    print("NAME: $name");
    print("EMAIL: $email");
    print("PHOTO: $photo");
  }

  void _handleSignOut() {
    final box = Hive.box('loginBox');
    box.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget buildProfileImage() {
    if (photo.isNotEmpty && photo.startsWith('http')) {
      return Image.network(
        photo,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            "assets/icons/login.png",
            width: 160,
            height: 160,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      return Image.asset(
        "assets/icons/login.png",
        width: 160,
        height: 160,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 6, 12, 98),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 6, 12, 98),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            /// FOTO PROFILE
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              child: ClipOval(child: buildProfileImage()),
            ),

            const SizedBox(height: 16),

            /// NAMA & EMAIL
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              email,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 30),

            /// BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _infoTile(
                          icon: Icons.person,
                          title: "Nama",
                          subtitle: name,
                        ),
                        _infoTile(
                          icon: Icons.email,
                          title: "Email",
                          subtitle: email,
                        ),
                        _infoTile(
                          icon: Icons.verified_user,
                          title: "Role",
                          subtitle: levelLabel,
                        ),
                      ],
                    ),

                    /// LOGOUT BUTTON
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          fixedSize: const Size(160, 45),
                        ),
                        onPressed: _handleSignOut,
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.white),
                        ),
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

/// WIDGET INFO
Widget _infoTile({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle.isNotEmpty ? subtitle : "-"),
      ),
      const Divider(height: 5),
    ],
  );
}
