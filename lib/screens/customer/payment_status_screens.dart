import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double amount;
  final String orderId;
  final String transactionId;
  final DateTime timestamp;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.orderId,
    required this.transactionId,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final textColor54 = isDarkMode ? Colors.white54 : Colors.black54;
    final cardColor = Theme.of(context).cardColor;

    final dateStr = '${timestamp.day}/${timestamp.month}/${timestamp.year} | ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Recharge Status',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Success Animation Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0x1010B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 84,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${amount.toStringAsFixed(2)} has been securely added to your wallet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              // Receipt Details Card
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
                  children: [
                    _buildReceiptRow('Amount Paid', '₹${amount.toStringAsFixed(2)}', isBold: true, valueColor: const Color(0xFF10B981)),
                    const Divider(height: 24),
                    _buildReceiptRow('Payment ID', transactionId, copyable: true, context: context),
                    const Divider(height: 24),
                    _buildReceiptRow('Order ID', orderId),
                    const Divider(height: 24),
                    _buildReceiptRow('Date & Time', dateStr),
                  ],
                ),
              ),
              const Spacer(),
              const Spacer(),

              // Done Button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to WalletScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF536DFE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Wallet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    bool copyable = false,
    BuildContext? context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? (isBold ? Colors.black : Colors.grey[700]),
                      fontSize: 13,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable && context != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction ID copied!'),
                          backgroundColor: Color(0xFF536DFE),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFF536DFE),
                      size: 14,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentFailedScreen extends StatelessWidget {
  final String orderId;
  final String reason;

  const PaymentFailedScreen({
    super.key,
    required this.orderId,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final textColor54 = isDarkMode ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Recharge Status',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Failure Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0x10EF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFEF4444),
                    size: 84,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Failed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                reason.isNotEmpty ? reason : 'Your transaction could not be processed due to a technical error.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (orderId.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Order ID: $orderId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),
              const Spacer(),

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Wallet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
