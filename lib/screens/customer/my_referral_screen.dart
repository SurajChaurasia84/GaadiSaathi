import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state.dart';

class MyReferralScreen extends StatefulWidget {
  const MyReferralScreen({super.key});

  @override
  State<MyReferralScreen> createState() => _MyReferralScreenState();
}

class _MyReferralScreenState extends State<MyReferralScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isRedeeming = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleShareApp(String referralCode) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Hey! Join Gaadi Saathi using my referral code: $referralCode '
            'and start renting cars, e-rickshaws, and loading vehicles easily!\n\n'
            'Download now from Google Play Store:\n'
            'https://play.google.com/store/apps/details?id=com.gaadisaathi.rent.apps',
        title: 'Share Referral Code',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final textColor54 = isDarkMode ? Colors.white54 : Colors.black54;
    final textColor30 = isDarkMode ? Colors.white30 : Colors.black38;
    final cardColor = Theme.of(context).cardColor;

    final referralCode = appState.referralCode ?? '------';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Referral',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: textColor),
            onPressed: () => _handleShareApp(referralCode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Image.asset(
                    'assets/coin.png',
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Refer & Get Coins',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your referral code with friends. For every friend who redeems your code, you will get 1 Gaadi Saathi Coin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor54,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Referral Coins Balance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/coin.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gaadi Saathi Coins',
                          style: TextStyle(
                            color: textColor54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appState.referralCoins} Coins',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Your Referral Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'YOUR REFERRAL CODE',
                    style: TextStyle(
                      color: textColor30,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied to clipboard!'),
                          backgroundColor: Color(0xFF536DFE),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF536DFE).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF536DFE).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            referralCode,
                            style: const TextStyle(
                              color: Color(0xFF536DFE),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.copy_rounded,
                            color: Color(0xFF536DFE),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: appState.redeemedCode != null
                  ? Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Referral Code Redeemed',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Redeemed code: ${appState.redeemedCode}',
                          style: TextStyle(
                            color: textColor54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'REDEEM REFERRAL CODE',
                          style: TextStyle(
                            color: textColor30,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 6,
                                style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Enter 6-digit code',
                                  hintStyle: TextStyle(color: textColor30, fontSize: 13, fontWeight: FontWeight.normal),
                                  filled: true,
                                  fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x10000000),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF536DFE)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _isRedeeming
                                  ? null
                                  : () async {
                                      final code = _codeController.text.trim();
                                      if (code.isEmpty) return;

                                      final messenger = ScaffoldMessenger.of(context);
                                      FocusScope.of(context).unfocus();
                                      setState(() => _isRedeeming = true);

                                      try {
                                        await appState.redeemReferralCode(code);
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Referral code redeemed successfully!'),
                                            backgroundColor: Color(0xFF10B981),
                                          ),
                                        );
                                        _codeController.clear();
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString().replaceAll('Exception: ', '')),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isRedeeming = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF536DFE),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isRedeeming
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Redeem',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
