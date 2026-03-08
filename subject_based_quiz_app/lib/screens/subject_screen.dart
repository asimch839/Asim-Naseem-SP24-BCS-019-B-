import 'package:flutter/material.dart';
import '../data/questions_data.dart';
import '../models/question_model.dart';
import 'history_screen.dart';

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium Gradient Mixture
    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
          : [const Color(0xFF4F46E5), const Color(0xFF7C3AED), const Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    final subjects = [
      {"name": "Web Tech", "icon": Icons.language, "color": Colors.green},
      {"name": "Stats", "icon": Icons.analytics, "color": Colors.amber},
      {"name": "OS", "icon": Icons.settings_input_component, "color": Colors.blue},
      {"name": "DAA", "icon": Icons.account_tree, "color": Colors.pink},
      {"name": "Assembly", "icon": Icons.developer_board, "color": Colors.purple},
      {"name": "App Dev", "icon": Icons.smartphone, "color": Colors.teal},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F2F5),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 150,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, bottom: 20),
              decoration: gradientDecoration,
              alignment: Alignment.bottomLeft,
              child: const Text(
                "Menu", 
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('History'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                    title: const Text('Rate Our App'),
                    onTap: () {
                      Navigator.pop(context);
                      _showRatingDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_rounded, color: Colors.blue),
                    title: const Text('Share Our App'),
                    onTap: () {
                      Navigator.pop(context);
                      _shareApp(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () => Navigator.pushReplacementNamed(context, '/'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Performance Header with overflow fix
          SliverAppBar(
            expandedHeight: 380, // Increased height to prevent overflow
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5), 
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: gradientDecoration,
                child: Stack(
                  children: [
                    // Decorative Background Shapes
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    
                    // Main Performance Card Design
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 70, 24, 20), // Adjusted top padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Your Learning Progress",
                            style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1),
                          ),
                          const SizedBox(height: 10),
                          // Big Glowing Percentage with Circle
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withAlpha(10),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${AppData.overallPercentage.toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 44, // Slightly reduced size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  "Overall",
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20), // Reduced spacing
                          // Stats Row with Glass effect
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withAlpha(30)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard("${AppData.totalQuizzes}", "Tests", Icons.assignment_outlined),
                                _buildStatCard("${AppData.totalPoints}", "Points", Icons.stars_rounded),
                                _buildStatCard(AppData.bestSubject, "Best", Icons.emoji_events_outlined),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F2F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Subjects",
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final sub = subjects[index];
                          return HoverSubjectCard(subject: sub, isDark: isDark);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Recent History",
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (AppData.history.isEmpty)
                      Center(
                        child: Text(
                          "Take a quiz to see your progress!",
                          style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(153)),
                        ),
                      )
                    else
                      Column(
                        children: AppData.history.reversed.take(3).map((record) => HistoryTile(record: record)).toList(),
                      ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 4),
        Text(
          value, 
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rate Us"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How much do you like this app?"),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber),
                Icon(Icons.star, color: Colors.amber),
                Icon(Icons.star, color: Colors.amber),
                Icon(Icons.star, color: Colors.amber),
                Icon(Icons.star, color: Colors.amber),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks for rating!")));
            }, 
            child: const Text("SUBMIT")
          ),
        ],
      ),
    );
  }

  void _shareApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("App link copied to clipboard! (Simulation)"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class HoverSubjectCard extends StatefulWidget {
  final Map<String, dynamic> subject;
  final bool isDark;
  const HoverSubjectCard({super.key, required this.subject, required this.isDark});

  @override
  State<HoverSubjectCard> createState() => _HoverSubjectCardState();
}

class _HoverSubjectCardState extends State<HoverSubjectCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        margin: EdgeInsets.only(
          right: 16, 
          top: isHovered ? 0 : 5, 
          bottom: isHovered ? 10 : 5
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isHovered ? (widget.isDark ? 80 : 30) : (widget.isDark ? 50 : 10)),
              blurRadius: isHovered ? 15 : 10,
              offset: Offset(0, isHovered ? 8 : 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
             String dataKey = widget.subject['name'] as String;
             if(dataKey == "Web Tech") dataKey = "Web Technologies";
             else if(dataKey == "Stats") dataKey = "Statistics";
             else if(dataKey == "OS") dataKey = "Operating System";
             else if(dataKey == "DAA") dataKey = "Design & Analysis";
             else if(dataKey == "Assembly") dataKey = "Assembly Language";
             else if(dataKey == "App Dev") dataKey = "Mobile Application";
             
             Navigator.pushNamed(
              context,
              '/quiz',
              arguments: dataKey,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedScale(
                  scale: isHovered ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (widget.subject['color'] as Color).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.subject['icon'] as IconData, color: widget.subject['color'] as Color),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.subject['name'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "5 Questions",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withAlpha(153), 
                    fontSize: 12
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
