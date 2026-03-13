import 'package:flutter/material.dart';
import 'background_wrapper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Profile Photo Area
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent.withAlpha(128),
                    width: 2,
                  ),
                ),
                child: Hero(
                  tag: 'profile_pic',
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: ClipOval(
                      child: Transform.scale(
                        scale: 2.8, // High zoom as requested
                        child: Image.asset(
                          'assets/Asim.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 100, color: Colors.white);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              // Name
              const Text(
                'Asim Naseem',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              
              // Professional Titles - Updated to include Event Manager
              const Text(
                'Flutter Developer | Software Engineering Student',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Construction Expert | Car Dealer | Event Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Short Intro - Updated
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Passionate Flutter developer building modern mobile applications while managing expert services in Construction, Car Dealership, and Event Management.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Slider Section
              const Text(
                'My Expertise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              
              SizedBox(
                height: 150,
                child: PageView(
                  controller: PageController(viewportFraction: 0.8),
                  children: [
                    _buildSliderItem(
                      Icons.code,
                      'App Development',
                      'Building high-quality Flutter apps.',
                    ),
                    _buildSliderItem(
                      Icons.construction,
                      'Construction',
                      'Expert in building and civil works.',
                    ),
                    _buildSliderItem(
                      Icons.directions_car,
                      'Car Dealer',
                      'Buying and selling quality vehicles.',
                    ),
                    _buildSliderItem(
                      Icons.event,
                      'Event Management',
                      'Organizing memorable and successful events.',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 60),
                child: Divider(color: Colors.white24, thickness: 1),
              ),
              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
