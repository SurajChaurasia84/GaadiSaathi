const admin = require('firebase-admin');
const crypto = require('crypto');

const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '7FYu2OUyI7lTUyHC6wvAZG2Q';

// Initialize Firebase Admin once (singleton pattern for serverless)
if (!admin.apps.length) {
  const serviceAccount = JSON.parse(
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '{}'
  );
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

/**
 * POST /api/verify-razorpay-payment
 * Body: {
 *   "razorpay_order_id": "order_id_here",
 *   "razorpay_payment_id": "payment_id_here",
 *   "razorpay_signature": "signature_here",
 *   "userId": "user_id_here",
 *   "amount": 100
 * }
 */
module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const {
    razorpay_order_id,
    razorpay_payment_id,
    razorpay_signature,
    userId,
    amount
  } = req.body;

  if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !userId || !amount) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }

  // 1. Verify Razorpay cryptographic signature
  const secret = RAZORPAY_KEY_SECRET;
  const generatedSignature = crypto
    .createHmac('sha256', secret)
    .update(`${razorpay_order_id}|${razorpay_payment_id}`)
    .digest('hex');

  const db = admin.firestore();
  const userRef = db.collection('users').doc(userId);
  const transactionRef = userRef.collection('transactions').doc(razorpay_payment_id);

  if (generatedSignature !== razorpay_signature) {
    console.error('Razorpay signature mismatch.');
    
    // Log failed attempt
    try {
      await transactionRef.set({
        amount: Number(amount),
        description: 'Failed payment verification (Signature mismatch)',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        razorpayOrderId: razorpay_order_id,
        status: 'failed'
      });
    } catch (e) {
      console.error('Failed to log failed transaction:', e);
    }

    return res.status(400).json({ success: false, error: 'Signature verification failed' });
  }

  let method = 'Unknown';
  let paymentViaDetail = 'N/A';

  try {
    const authString = Buffer.from(`${process.env.RAZORPAY_KEY_ID || 'rzp_test_TDiYGf92druKaJ'}:${secret}`).toString('base64');
    const paymentResponse = await fetch(`https://api.razorpay.com/v1/payments/${razorpay_payment_id}`, {
      headers: {
        'Authorization': `Basic ${authString}`
      }
    });
    if (paymentResponse.ok) {
      const paymentData = await paymentResponse.json();
      method = paymentData.method || 'Unknown';
      if (method === 'upi') {
        paymentViaDetail = paymentData.vpa || 'UPI';
      } else if (method === 'bank' || method === 'netbanking') {
        paymentViaDetail = paymentData.bank || 'Netbanking';
      } else if (method === 'wallet') {
        paymentViaDetail = paymentData.wallet || 'Wallet';
      } else if (method === 'card') {
        paymentViaDetail = paymentData.card ? (paymentData.card.network || 'Card') : 'Card';
      }
    }
  } catch (err) {
    console.error('Failed to fetch payment info from Razorpay:', err);
  }

  try {
    // 2. Perform Firestore Transaction to safely add coins
    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) {
        throw new Error('User document not found');
      }

      // Check if transaction was already processed (idempotency check)
      const txDoc = await transaction.get(transactionRef);
      if (txDoc.exists && txDoc.data().status === 'success') {
        // Already processed, do nothing
        return;
      }

      const userData = userDoc.data();
      const currentCoins = Number(userData.coins || 0);
      const newCoins = currentCoins + Number(amount);

      // Update user coins
      transaction.update(userRef, { coins: newCoins });

      // Save successful transaction log
      transaction.set(transactionRef, {
        amount: Number(amount),
        description: `Added ₹${amount} Coins (Razorpay)`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        razorpayOrderId: razorpay_order_id,
        status: 'success',
        method: method.toUpperCase(),
        paymentViaDetail: paymentViaDetail
      });
    });

    return res.status(200).json({
      success: true,
      transactionId: razorpay_payment_id,
      amount: Number(amount),
      timestamp: Date.now()
    });
  } catch (error) {
    console.error('Verify payment transaction catch error:', error);
    
    // Log failed attempt in catch block
    try {
      await transactionRef.set({
        amount: Number(amount),
        description: `Failed payment process: ${error.message}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        razorpayOrderId: razorpay_order_id,
        status: 'failed'
      });
    } catch (e) {}

    return res.status(500).json({ success: false, error: error.message });
  }
};
