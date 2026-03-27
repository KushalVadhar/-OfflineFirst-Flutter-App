import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                   CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.black,
                    child: const Text(
                      "K", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 40, 
                        fontWeight: FontWeight.w900
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.edit, color: Colors.black, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Kushal",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Text(
              "@kushal_dev",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat("Articles", "12"),
                _buildStat("Following", "1.2k"),
                _buildStat("Followers", "850"),
              ],
            ),
            const SizedBox(height: 40),
            _buildProfileOption(Icons.person_outline, "Edit Profile"),
            _buildProfileOption(Icons.notifications_none, "Notifications"),
            _buildProfileOption(Icons.lock_outline, "Security"),
            _buildProfileOption(Icons.help_outline, "Help & Support"),
            const Divider(height: 48),
            _buildProfileOption(Icons.logout, "Logout", isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDestructive ? Colors.red : Colors.black, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : Colors.black,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
