import 'package:flutter/material.dart';
import 'background_wrapper.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final skillCategories = [
      {
        'category': 'Development & Tech',
        'icon': Icons.code_rounded,
        'skills': [
          {'name': 'Flutter', 'level': 0.9},
          {'name': 'Dart', 'level': 0.85},
          {'name': 'Firebase', 'level': 0.8},
          {'name': 'Java', 'level': 0.75},
          {'name': 'Python', 'level': 0.7},
          {'name': 'Git/GitHub', 'level': 0.85},
        ]
      },
      {
        'category': 'Business & Management',
        'icon': Icons.trending_up_rounded,
        'skills': [
          {'name': 'Construction Management', 'level': 0.9},
          {'name': 'Car Dealership', 'level': 0.95},
          {'name': 'Event Management', 'level': 0.85},
          {'name': 'Sales & Marketing', 'level': 0.8},
          {'name': 'Client Relations', 'level': 0.9},
        ]
      }
    ];

    return BackgroundWrapper(
      title: 'Skills & Expertise',
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: skillCategories.length,
        itemBuilder: (context, index) {
          final category = skillCategories[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(category['icon'] as IconData, color: Colors.blueAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    category['category'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: (category['skills'] as List<Map<String, dynamic>>).map((skill) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              skill['name'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            Text(
                              '${((skill['level'] as double) * 100).toInt()}%',
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: skill['level'] as double,
                            backgroundColor: Colors.white.withAlpha(10),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
