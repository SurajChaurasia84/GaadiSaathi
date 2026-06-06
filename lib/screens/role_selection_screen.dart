import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/theme_selector.dart';
import 'login_screen.dart';
import 'customer/customer_home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          buildThemeSelector(context, appState),
          const SizedBox(width: 8),
        ],
      ),
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
              Center(
                child: Text(
                  'GaadiSaathi',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Instant Car, E-Rickshaw & Loading Rentals',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textColor54,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'CHOOSE YOUR ROLE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textColor30,
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
                subtitle: 'Book vehicles, negotiate rates, and chat with owners instantly.',
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
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final appState = Provider.of<AppState>(context, listen: false);
                    appState.setRole('Customer');
                    appState.loginSimulated('guest.customer@gmail.com', 'Guest Customer');
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF536DFE), size: 16),
                  label: const Text(
                    'Skip Login & Browse as Guest',
                    style: TextStyle(
                      color: Color(0xFF536DFE),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
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
