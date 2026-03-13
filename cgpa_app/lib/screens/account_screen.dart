import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isEditing = false;
  final _userManager = UserManager();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _uniController;
  late TextEditingController _batchController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _userManager.currentUser.name);
    _emailController = TextEditingController(text: _userManager.currentUser.email);
    _phoneController = TextEditingController(text: _userManager.currentUser.phone);
    _uniController = TextEditingController(text: _userManager.currentUser.university);
    _batchController = TextEditingController(text: _userManager.currentUser.batch);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _uniController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveInfo() {
    setState(() {
      _userManager.updateUser(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        university: _uniController.text,
        batch: _batchController.text,
      );
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile Updated Successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Info'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save_rounded : Icons.edit_rounded),
            onPressed: _isEditing ? _saveInfo : _toggleEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person, size: 80, color: Colors.white),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary,
                      radius: 18,
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            _isEditing
                ? _buildEditFields()
                : _buildViewFields(),
            const SizedBox(height: 40),
            if (_isEditing)
              ElevatedButton(
                onPressed: _saveInfo,
                child: const Text('SAVE CHANGES'),
              )
            else
              OutlinedButton.icon(
                onPressed: _toggleEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('EDIT PROFILE'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewFields() {
    return Column(
      children: [
        _buildInfoTile(Icons.person_outline, 'Full Name', _userManager.currentUser.name),
        _buildInfoTile(Icons.email_outlined, 'Email Address', _userManager.currentUser.email),
        _buildInfoTile(Icons.phone_outlined, 'Phone Number', _userManager.currentUser.phone),
        _buildInfoTile(Icons.school_outlined, 'University', _userManager.currentUser.university),
        _buildInfoTile(Icons.calendar_today_outlined, 'Batch', _userManager.currentUser.batch),
      ],
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        _buildTextField(_nameController, 'Full Name', Icons.person_outline),
        _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
        _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
        _buildTextField(_uniController, 'University', Icons.school_outlined),
        _buildTextField(_batchController, 'Batch', Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
