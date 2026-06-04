import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Logo & Slogan
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF536DFE).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF536DFE).withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: Color(0xFF536DFE),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Rent Wheels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Instant Car, E-Rickshaw & Loading Rides',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'CHOOSE YOUR ROLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Customer Selection Button Card
              _buildRoleCard(
                context: context,
                title: 'I am a Customer',
                subtitle: 'Find rides, negotiate rates, and chat with owners instantly.',
                icon: Icons.search_rounded,
                gradientColors: [const Color(0xFF536DFE), const Color(0xFF3F51B5)],
                role: 'Customer',
              ),
              const SizedBox(height: 16),
              // Owner Selection Button Card
              _buildRoleCard(
                context: context,
                title: 'I am an Owner',
                subtitle: 'Register your vehicle, set your rate/Km, and toggle availability.',
                icon: Icons.vpn_key_rounded,
                gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                role: 'Owner',
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required String role,
  }) {
    return GestureDetector(
      onTap: () {
        Provider.of<AppState>(context, listen: false).setRole(role);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientColors[0].withOpacity(0.85),
              gradientColors[1].withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
