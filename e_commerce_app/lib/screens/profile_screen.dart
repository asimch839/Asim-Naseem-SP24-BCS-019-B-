import 'package:flutter/material.dart';
import '../models/auth_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = AuthManager();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditProfileDialog)
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: isWide 
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: _buildAvatarSection()),
                      Expanded(flex: 2, child: _buildDetailsSection()),
                    ],
                  )
                : Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 20),
                      _buildDetailsSection(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 70,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 90, color: Colors.white),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 22, color: Colors.blueAccent),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(auth.userName ?? 'Guest', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(auth.userEmail ?? '', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      children: [
        _buildInfoCard(),
        const SizedBox(height: 20),
        _buildProfileItem(Icons.shopping_bag, 'My Orders', () {
          Navigator.pushNamed(context, '/orders');
        }),
        _buildProfileItem(Icons.favorite, 'Wishlist', () {
          Navigator.pushNamed(context, '/wishlist');
        }),
        _buildProfileItem(Icons.settings, 'Settings', () {
          _showSettingsDialog();
        }),
        const Divider(),
        _buildProfileItem(Icons.logout, 'Logout', () {
          auth.logout();
          Navigator.pushReplacementNamed(context, '/auth');
        }, color: Colors.red),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.phone, 'Phone', auth.userPhone ?? 'Not set'),
          const Divider(height: 25),
          _buildDetailRow(Icons.location_on, 'Address', auth.userAddress ?? 'Not set'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blueAccent),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: auth.userName);
    final phoneController = TextEditingController(text: auth.userPhone);
    final addressController = TextEditingController(text: auth.userAddress);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                auth.updateProfile(name: nameController.text, phone: phoneController.text, address: addressController.text);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Notifications'),
              value: true,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: false,
              onChanged: (val) {},
            ),
            ListTile(
              title: const Text('Language'),
              trailing: const Text('English'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
