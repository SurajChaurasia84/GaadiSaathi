const admin = require('firebase-admin');

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
 * POST /api/send-notification
 * Body: {
 *   "fcmToken": "device_token_here",
 *   "title": "New Message",
 *   "body": "Rahul: Hello, is the car available?",
 *   "data": { "threadId": "abc123", "senderName": "Rahul" }
 * }
 */
module.exports = async (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { fcmToken, title, body, data } = req.body;

  if (!fcmToken || !title || !body) {
    return res.status(400).json({ error: 'fcmToken, title, and body are required' });
  }

  try {
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'gaadisaathi_messages',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      data: data
        ? Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)])
          )
        : {},
    };

    const response = await admin.messaging().send(message);
    return res.status(200).json({ success: true, messageId: response });
  } catch (error) {
    console.error('FCM send error:', error.code, error.message);
    // Token expired/invalid — caller should remove it from Firestore
    if (error.code === 'messaging/registration-token-not-registered') {
      return res.status(410).json({ error: 'token_invalid', code: error.code });
    }
    return res.status(500).json({ error: error.message, code: error.code });
  }
};
