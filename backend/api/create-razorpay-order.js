const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID || 'rzp_test_TDiYGf92druKaJ';
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '7FYu2OUyI7lTUyHC6wvAZG2Q';

/**
 * POST /api/create-razorpay-order
 * Body: {
 *   "amount": 100, // in Rupees
 *   "userId": "user_id_here"
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

  const { amount, userId } = req.body;

  if (!amount || !userId) {
    return res.status(400).json({ error: 'amount and userId are required' });
  }

  const amountInPaise = Math.round(Number(amount) * 100);

  try {
    const authString = Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString('base64');
    
    const response = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${authString}`
      },
      body: JSON.stringify({
        amount: amountInPaise,
        currency: 'INR',
        receipt: `rcpt_${userId.slice(0, 8)}_${Date.now()}`,
        notes: {
          userId: userId,
          amount: amount.toString()
        }
      })
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('Razorpay Order API error:', data);
      return res.status(response.status).json({ error: data.error || 'Failed to create order with Razorpay' });
    }

    return res.status(200).json({
      id: data.id,
      amount: data.amount,
      currency: data.currency
    });
  } catch (error) {
    console.error('Create order catch error:', error);
    return res.status(500).json({ error: error.message });
  }
};
