import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state.dart';
import '../widgets/theme_selector.dart';
import 'customer/customer_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'name': firebaseUser.displayName ?? '',
          'email': firebaseUser.email ?? '',
          'photoUrl': firebaseUser.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        appState.loginSimulated(
          firebaseUser.email ?? '',
          firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
        );

        // Save FCM device token so others can send push notifications to this user
        await appState.saveFcmToken();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  void _handleGuestLogin() {
    final appState = Provider.of<AppState>(context, listen: false);

    appState.loginSimulated(
      'guest.customer@gmail.com',
      'Guest Customer',
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button on landing screen
        actions: [
          buildThemeSelector(context, appState),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // App Logo / Icon Header
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Gaadi Saathi',
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
                  'Rent Cars, E-Rickshaws & Loading Vehicles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textColor54,
                    fontSize: 15,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF536DFE),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Authenticating Google Account...',
                        style: TextStyle(color: Color(0xFF536DFE), fontSize: 13, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                )
              else ...[
                // Custom Google Sign In Button
                ElevatedButton(
                  onPressed: _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: context.textColor,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2E3B4E) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/google_logo.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sign In with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Continue as Guest Button
                OutlinedButton(
                  onPressed: _handleGuestLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFF536DFE),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF536DFE),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue as Guest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF536DFE),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
