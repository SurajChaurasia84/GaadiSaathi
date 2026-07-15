import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_status_screens.dart';
import '../../providers/app_state.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isProcessing = false;
  final _customAmountController = TextEditingController();
  Stream<QuerySnapshot>? _transactionsStream;

  late Razorpay _razorpay;
  double? _pendingAmount;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _transactionsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _startRazorpayPayment(AppState appState, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to recharge.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _pendingAmount = amount;
    });

    try {
      // 1. Create order on the Vercel backend
      final response = await http.post(
        Uri.parse('https://gaadisaathi-backend.vercel.app/api/create-razorpay-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'userId': user.uid,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create order');
      }

      final data = jsonDecode(response.body);
      final String orderId = data['id'];
      _pendingOrderId = orderId;

      // 2. Launch Razorpay Checkout UI
      var options = {
        'key': 'rzp_test_TDiYGf92druKaJ',
        'amount': amount * 100, // in paise
        'name': 'Gaadi Saathi',
        'order_id': orderId,
        'description': 'Add ₹${amount.toInt()} Coins',
        'prefill': {
          'contact': appState.currentUserPhone ?? '',
          'email': appState.currentGmail ?? '',
        },
        'timeout': 300, // in seconds
      };

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      // Show failed screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentFailedScreen(
            orderId: '',
            reason: e.toString().replaceAll('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _pendingAmount == null || _pendingOrderId == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    final nav = Navigator.of(context);

    try {
      // 3. Verify payment on Vercel backend
      final verificationResponse = await http.post(
        Uri.parse('https://gaadisaathi-backend.vercel.app/api/verify-razorpay-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'userId': user.uid,
          'amount': _pendingAmount,
        }),
      );

      setState(() {
        _isProcessing = false;
      });

      if (verificationResponse.statusCode == 200) {
        // Success payment screen
        nav.push(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              amount: _pendingAmount!,
              orderId: response.orderId ?? _pendingOrderId ?? '',
              transactionId: response.paymentId ?? '',
              timestamp: DateTime.now(),
            ),
          ),
        );
      } else {
        final errorMsg = jsonDecode(verificationResponse.body)['error'] ?? 'Verification failed';
        // Failed payment screen
        nav.push(
          MaterialPageRoute(
            builder: (context) => PaymentFailedScreen(
              orderId: response.orderId ?? _pendingOrderId ?? '',
              reason: errorMsg,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      nav.push(
        MaterialPageRoute(
          builder: (context) => PaymentFailedScreen(
            orderId: response.orderId ?? _pendingOrderId ?? '',
            reason: 'Network/Server error during payment verification: $e',
          ),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFailedScreen(
          orderId: _pendingOrderId ?? '',
          reason: response.message ?? 'Payment failed or cancelled.',
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Wallet',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Wallet Balance Section (Flat layout)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'YOUR BALANCE',
                            style: TextStyle(
                              color: context.textColor30,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Icon(Icons.account_balance_wallet_rounded, color: context.textColor30, size: 22),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${appState.userCoins}',
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Wallet balance is non-refundable and used for promoting shop posts and ads listings.',
                        style: TextStyle(
                          color: context.textColor54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Coin Packages Section
                Text(
                  'ADD MONEY',
                  style: TextStyle(
                    color: context.textColor30,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                // Package grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildCoinPackage(appState, 50, 50, null),
                    _buildCoinPackage(appState, 100, 100, null),
                  ],
                ),
                const SizedBox(height: 16),

                // Custom amount input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customAmountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add custom amount',
                          hintStyle: TextStyle(color: context.textColor30, fontSize: 13),
                          prefixText: '₹ ',
                          prefixStyle: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 14),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF536DFE)),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _customAmountController.text.trim().isEmpty
                          ? null
                          : () {
                              final amountStr = _customAmountController.text.trim();
                              final amount = int.tryParse(amountStr);
                              if (amount != null && amount > 0) {
                                FocusScope.of(context).unfocus();
                                _startRazorpayPayment(appState, amount.toDouble());
                                _customAmountController.clear();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF536DFE),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF536DFE).withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Transaction History Title with "See All" button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRANSACTION HISTORY',
                      style: TextStyle(
                        color: context.textColor30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (user != null)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllTransactionsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Color(0xFF536DFE),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transaction List (Firestore sync)
                if (user == null)
                  Center(
                    child: Text(
                      'Log in to view transaction history',
                      style: TextStyle(color: context.textColor54, fontSize: 13),
                    ),
                  )
                else
                  StreamBuilder<QuerySnapshot>(
                    stream: _transactionsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(color: Color(0xFF536DFE)),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No Transactions Yet',
                              style: TextStyle(
                                color: context.textColor30,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }

                      // Limit to last 5 transactions on Home wallet
                      final txDocs = snapshot.data!.docs.take(5).toList();

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: txDocs.length,
                        separatorBuilder: (context, index) => Divider(
                          color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final tx = txDocs[index].data() as Map<String, dynamic>;
                          return _buildTransactionTile(context, tx);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF536DFE)),
                        const SizedBox(height: 16),
                        Text(
                          'Processing payment...',
                          style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinPackage(AppState appState, int amount, double price, String? badge) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
        ),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _startRazorpayPayment(appState, price),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹$amount',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF536DFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Add ₹${price.toInt()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  color: const Color(0xFFFF9100),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Transaction item helper widget
Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> tx) {
  final amount = tx['amount'] as int? ?? 0;
  final description = tx['description'] as String? ?? 'Coin adjustment';
  final timestamp = tx['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
  final dateStr = DateTime.fromMillisecondsSinceEpoch(timestamp)
      .toLocal()
      .toString()
      .substring(0, 16);

  final isEarned = amount > 0;

  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: CircleAvatar(
      radius: 18,
      backgroundColor: isEarned
          ? const Color(0x1010B981)
          : const Color(0x10FF5252),
      child: Icon(
        isEarned ? Icons.call_received_rounded : Icons.call_made_rounded,
        color: isEarned ? const Color(0xFF10B981) : const Color(0xFFFF5252),
        size: 16,
      ),
    ),
    title: Text(
      description,
      style: TextStyle(
        color: context.textColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      dateStr,
      style: TextStyle(
        color: context.textColor30,
        fontSize: 11,
      ),
    ),
    trailing: Text(
      '${isEarned ? "+" : "-"} ₹${amount.abs()}',
      style: TextStyle(
        color: isEarned ? const Color(0xFF10B981) : const Color(0xFFFF5252),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    ),
  );
}

// Screen that shows all transactions (Newest First)
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  Stream<QuerySnapshot>? _transactionsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _transactionsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Transactions',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: user == null
          ? Center(
              child: Text(
                'Log in to view transactions',
                style: TextStyle(color: context.textColor54, fontSize: 14),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _transactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF536DFE)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No Transactions Found',
                      style: TextStyle(
                        color: context.textColor30,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                final txDocs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: txDocs.length,
                  separatorBuilder: (context, index) => Divider(
                    color: context.isDarkMode ? const Color(0x0AFFFFFF) : const Color(0x08000000),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final tx = txDocs[index].data() as Map<String, dynamic>;
                    return _buildTransactionTile(context, tx);
                  },
                );
              },
            ),
    );
  }
}
