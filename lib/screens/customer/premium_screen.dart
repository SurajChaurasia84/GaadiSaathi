import 'package:flutter/material.dart';
import '../../providers/app_state.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlanIndex = 1; // Default to annual

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'Monthly Plan',
      'price': '₹199',
      'period': '/ month',
      'subtitle': 'Perfect to try out',
      'badge': null,
    },
    {
      'title': 'Annual Plan',
      'price': '₹999',
      'period': '/ year',
      'subtitle': 'Save 58% yearly',
      'badge': 'Best Value',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buy Premium',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Hero Section
            Center(
              child: Column(
                children: [
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withValues(alpha: isDark ? 0.35 : 0.2),
                          blurRadius: 36,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/premium.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                    ).createShader(bounds),
                    child: const Text(
                      'GaadiSaathi Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock the ultimate rental experience today',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textColor54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Features Title
            Text(
              'EXCLUSIVE PRIVILEGES',
              style: TextStyle(
                color: context.textColor30,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Premium Features Cards
            _buildFeatureCard(
              context: context,
              icon: Icons.flash_on_rounded,
              title: 'Instant Priority Booking',
              description: 'Your booking requests reach owners instantly with top priority approval.',
              iconColor: const Color(0xFFFFB300),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              icon: Icons.verified_rounded,
              title: 'Premium Verified Badge',
              description: 'Stand out from the crowd with a trust badge on your profile screen.',
              iconColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              icon: Icons.percent_rounded,
              title: 'Zero Service Fee on Bookings',
              description: 'Save extra on every rental by skipping all platform service charges.',
              iconColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              icon: Icons.headset_mic_rounded,
              title: '24/7 Priority Support Desk',
              description: 'Enjoy fast dedicated support resolution for your queries.',
              iconColor: const Color(0xFFEC4899),
            ),
            const SizedBox(height: 28),

            // Plans Selector Title
            Text(
              'SELECT A SUBSCRIPTION PLAN',
              style: TextStyle(
                color: context.textColor30,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: List.generate(_plans.length, (index) {
                final plan = _plans[index];
                final isSelected = _selectedPlanIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlanIndex = index;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == _plans.length - 1 ? 0 : 8,
                      ),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFDE7))
                            : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFFFFFFF)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFFB300)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: 2.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan['title'],
                                style: TextStyle(
                                  color: context.textColor70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    plan['price'],
                                    style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    plan['period'],
                                    style: TextStyle(
                                      color: context.textColor54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                plan['subtitle'],
                                style: TextStyle(
                                  color: context.textColor54,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          if (plan['badge'] != null)
                            Positioned(
                              top: -30,
                              right: -10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'BEST VALUE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Get Premium CTA Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Processing payment... Welcome to GaadiSaathi Premium!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Activate Premium Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Cancel anytime. Terms & conditions apply.',
                style: TextStyle(
                  color: context.textColor30,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: context.textColor54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
