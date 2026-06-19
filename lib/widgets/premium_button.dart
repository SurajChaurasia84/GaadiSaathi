import 'package:flutter/material.dart';
import '../screens/customer/premium_screen.dart';

class PremiumButton extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Amber/orange style for the premium look
    const Color premiumBorderColor = Color(0xFFFFB300); // Amber 600
    const Color premiumTextColor = Color(0xFFFF8F00); // Amber 900 / dark orange
    final Color premiumBgColor = isDark 
        ? const Color(0xFF2B1F00) // Deep dark gold tint
        : const Color(0xFFFFFDE7); // Very light yellow

    return InkWell(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: premiumBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: premiumBorderColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: premiumBorderColor.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/premium.png',
              height: 16,
              width: 16,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            const Text(
              'PREMIUM',
              style: TextStyle(
                color: premiumTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
