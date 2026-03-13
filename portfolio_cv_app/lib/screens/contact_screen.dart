import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'background_wrapper.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late PageController _pageController;
  double _currentPage = 0;
  int? _hoveredSliderIndex;
  int? _pressedSliderIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page!;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      title: 'Contact Me',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildContactCard(
                Icons.email,
                'Email',
                'asimnaseem019@gmail.com',
                () => _launchURL('mailto:asimnaseem019@gmail.com'),
              ),
              const SizedBox(height: 15),
              _buildContactCard(
                Icons.phone,
                'Phone',
                '0334 7165839',
                () => _launchURL('tel:+923347165839'),
              ),
              const SizedBox(height: 15),
              _buildContactCard(
                Icons.link,
                'LinkedIn',
                'View Profile',
                () => _launchURL('https://www.linkedin.com/in/asim-naseem-13161339a'),
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'Stay Connected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    // Page view animation logic
                    double pageScale = (1 - (_currentPage - index).abs() * 0.2).clamp(0.8, 1.0);
                    double opacity = (1 - (_currentPage - index).abs() * 0.5).clamp(0.4, 1.0);
                    
                    // Interaction animation logic
                    bool isHovered = _hoveredSliderIndex == index;
                    bool isPressed = _pressedSliderIndex == index;
                    double interactionScale = isPressed ? 0.9 : (isHovered ? 1.05 : 1.0);

                    return Transform.scale(
                      scale: pageScale * interactionScale,
                      child: Opacity(
                        opacity: opacity,
                        child: _buildSliderItem(index),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 10,
                  shadowColor: Colors.blueAccent.withAlpha(100),
                ),
                onPressed: () => _launchURL('https://wa.me/923347165839'),
                child: const Text('Send Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueAccent.withAlpha(40),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderItem(int index) {
    final items = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': 'WhatsApp',
        'subtitle': 'Available for quick chats.',
        'url': 'https://wa.me/923347165839'
      },
      {
        'icon': Icons.alternate_email,
        'title': 'Email Support',
        'subtitle': 'Fast response for formal queries.',
        'url': 'mailto:asimnaseem019@gmail.com'
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Location',
        'subtitle': 'Based in Pakistan.',
        'url': 'https://www.google.com/maps/search/?api=1&query=Pakistan'
      },
    ];

    final item = items[index];
    bool isHovered = _hoveredSliderIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSliderIndex = index),
      onExit: (_) => setState(() => _hoveredSliderIndex = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedSliderIndex = index),
        onTapUp: (_) => setState(() => _pressedSliderIndex = null),
        onTapCancel: () => setState(() => _pressedSliderIndex = null),
        onTap: () => _launchURL(item['url'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHovered 
                ? [Colors.blueAccent.withAlpha(60), Colors.blueAccent.withAlpha(20)]
                : [Colors.white.withAlpha(30), Colors.white.withAlpha(10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isHovered ? Colors.blueAccent.withAlpha(150) : Colors.white12,
              width: isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? Colors.blueAccent.withAlpha(60) : Colors.black.withAlpha(50),
                blurRadius: isHovered ? 20 : 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 300),
                scale: isHovered ? 1.2 : 1.0,
                child: Icon(item['icon'] as IconData, 
                  color: isHovered ? Colors.white : Colors.blueAccent, 
                  size: 45
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item['title'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: isHovered ? [
                    const Shadow(color: Colors.blueAccent, blurRadius: 10)
                  ] : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['subtitle'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
