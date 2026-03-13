import 'package:flutter/material.dart';
import 'background_wrapper.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = [
      {
        'title': 'Quiz App',
        'category': 'Education',
        'description': 'An interactive quiz application with multiple categories, timer-based challenges, and a leaderboard system to track scores.',
        'tech': ['Flutter', 'Dart', 'GetX'],
        'icon': Icons.quiz_rounded,
        'status': 'Completed',
      },
      {
        'title': 'MovePK',
        'category': 'Transportation',
        'description': 'A ride-hailing application similar to InDrive, allowing users to book rides with real-time tracking and fare negotiation features.',
        'tech': ['Flutter', 'Google Maps API', 'Firebase'],
        'icon': Icons.local_taxi_rounded,
        'status': 'Production',
      },
      {
        'title': 'Event Flow',
        'category': 'Management Tool',
        'description': 'A seamless platform for organizing large-scale events, handling guest lists, vendor payments, and schedule tracking.',
        'tech': ['Flutter', 'SQLite', 'GetX'],
        'icon': Icons.event_note_rounded,
        'status': 'Beta',
      },
      {
        'title': 'Portfolio CV App',
        'category': 'Personal',
        'description': 'A modern, animated portfolio application showcasing professional skills, projects, and business ventures with a premium dark UI.',
        'tech': ['Flutter', 'Dart', 'Animations'],
        'icon': Icons.person_pin_rounded,
        'status': 'Completed',
      },
    ];

    return BackgroundWrapper(
      title: 'Featured Projects',
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 25),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section with Icon and Status
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(40),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          project['icon'] as IconData,
                          color: Colors.blueAccent,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['category'] as String,
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              project['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          project['status'] as String,
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    project['description'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Tech Stack Tags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (project['tech'] as List<String>).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bottom Action Button
                InkWell(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Case Study',
                          style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.blueAccent, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
