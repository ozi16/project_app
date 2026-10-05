import 'package:flutter/material.dart';

class ProfileModel {
  final String? image;
  final String name;
  final String email;
  final String role;
  final String branch;
  final String leader;
  final String notlp;
  final String? password;

  ProfileModel({
    this.image,
    required this.name,
    required this.email,
    required this.role,
    required this.branch,
    required this.leader,
    required this.notlp,
    this.password,
  });

  ProfileModel copyWith({
    String? image,
    String? name,
    String? email,
    String? role,
    String? branch,
    String? leader,
    String? notlp,
    String? password,
  }) {
    return ProfileModel(
      image: image ?? this.image,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      leader: leader ?? this.leader,
      notlp: notlp ?? this.notlp,
      password: password,
    );
  }
}

class EditProfile extends StatefulWidget {
  final ProfileModel data;

  const EditProfile({super.key, required this.data});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController roleController;
  late final TextEditingController branchController;
  late final TextEditingController leaderController;
  late final TextEditingController phoneController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data.name);
    emailController = TextEditingController(text: widget.data.email);
    roleController = TextEditingController(text: widget.data.role);
    branchController = TextEditingController(text: widget.data.branch);
    leaderController = TextEditingController(text: widget.data.leader);
    phoneController = TextEditingController(text: widget.data.notlp);
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    roleController.dispose();
    branchController.dispose();
    leaderController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.data.image != null
                    ? AssetImage(widget.data.image!)
                    : null,
                child: widget.data.image == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 24),

              _inputField("Name", nameController),
              _inputField(
                "Email",
                emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _inputField("Role", roleController),
              _inputField("Branch", branchController),
              _inputField("Leader", leaderController),
              _inputField(
                "Phone",
                phoneController,
                keyboardType: TextInputType.phone,
              ),
              _inputField(
                "Password (optional)",
                passwordController,
                obscureText: true,
                required: false,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: screenWidth * 0.6,
                height: 45,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
    bool required = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '$label tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = widget.data.copyWith(
        name: nameController.text,
        email: emailController.text,
        role: roleController.text,
        branch: branchController.text,
        leader: leaderController.text,
        notlp: phoneController.text,
        password: passwordController.text.isEmpty
            ? null
            : passwordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile berhasil disimpan")),
      );

      Navigator.pop(context, updatedProfile);
    }
  }
}
