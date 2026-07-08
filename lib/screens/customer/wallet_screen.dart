import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  // Simulate payment processing and add coins
  Future<void> _purchaseCoins(AppState appState, int amount, double price) async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate 1.5s gateway delay
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      await appState.addCoins(amount, "Added $amount Coins (₹${price.toInt()})");

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show Success Popup Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0x1010B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Recharge Successful',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Added $amount Coins to your wallet successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textColor54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF536DFE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
                                _purchaseCoins(appState, amount, amount.toDouble());
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
        onTap: () => _purchaseCoins(appState, amount, price),
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
