import 'package:flutter/material.dart';
import 'background_wrapper.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      title: 'About Me',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professional Summary Section
              _buildGlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Professional Summary',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dedicated Software Engineering student and versatile entrepreneur. I bridge the gap between technology and traditional business, bringing technical expertise to Construction and Car Dealership while crafting modern mobile solutions with Flutter.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('What I Offer'),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
                children: [
                  _buildServiceCard(Icons.app_shortcut, 'Flutter Dev'),
                  _buildServiceCard(Icons.engineering, 'Civil Works'),
                  _buildServiceCard(Icons.directions_car, 'Car Trading'),
                  _buildServiceCard(Icons.event_available, 'Event MGMT'),
                ],
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Work Experience'),
              const SizedBox(height: 15),
              _buildTimelineTile(
                'Manager',
                'Construction & Real Estate',
                '2022 - Present',
                Icons.business_center,
              ),
              _buildTimelineTile(
                'Dealer',
                'Saeed Car Point',
                '2023 - Present',
                Icons.directions_car_filled,
              ),
              _buildTimelineTile(
                'Event Coordinator',
                'Freelance Management',
                '2023 - Present',
                Icons.celebration,
              ),
              const SizedBox(height: 30),

              _buildSectionTitle('Education'),
              const SizedBox(height: 15),
              _buildTimelineTile(
                'BS Computer Science',
                'COMSATS Vehari',
                '2024 - Countinue',
                Icons.school,
              ),
              _buildTimelineTile(
                'ICS (Computer Science)',
                'KIPS College Vehari',
                '2021 - 2023',
                Icons.menu_book,
              ),
              _buildTimelineTile(
                'Matric (PHY, Chem, Maths, COMP)',
                'The Educators School Ghazali Campus Vehari',
                '2019 - 2021',
                Icons.school_outlined,
              ),
              const SizedBox(height: 30),

              // Hobbies & Interests Section
              _buildSectionTitle('Hobbies & Interests'),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildHobbyChip(Icons.code, 'Coding'),
                  _buildHobbyChip(Icons.travel_explore, 'Traveling'),
                  _buildHobbyChip(Icons.sports_cricket, 'Cricket'),
                  _buildHobbyChip(Icons.menu_book, 'Reading'),
                  _buildHobbyChip(Icons.camera_alt, 'Photography'),
                  _buildHobbyChip(Icons.currency_exchange, 'Collecting Coins'),
                ],
              ),
              
              const SizedBox(height: 100), // Bottom padding for navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 25,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildServiceCard(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 35),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTile(String title, String subtitle, String date, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHobbyChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
