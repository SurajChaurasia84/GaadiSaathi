// api/profile.js
// Serves the profile fallback page when the app is not installed
module.exports = (req, res) => {
  const username = req.query.u || '';

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.status(200).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GaadiSaathi - View Profile</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root { --primary: #536DFE; --bg: #0f172a; --card: rgba(30,41,59,0.7); --text: #f8fafc; --muted: #94a3b8; }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }
    body { background: radial-gradient(circle at top right, #1e1b4b 0%, var(--bg) 60%); color: var(--text); min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 24px; }
    .glow1 { position: absolute; top: -10%; left: -10%; width: 40vw; height: 40vw; background: radial-gradient(circle, rgba(83,109,254,0.15), transparent 70%); pointer-events: none; }
    .glow2 { position: absolute; bottom: -10%; right: -10%; width: 50vw; height: 50vw; background: radial-gradient(circle, rgba(99,102,241,0.1), transparent 70%); pointer-events: none; }
    .card { background: var(--card); border: 1px solid rgba(255,255,255,0.08); backdrop-filter: blur(20px); border-radius: 28px; padding: 40px 32px; width: 100%; max-width: 440px; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.3); z-index: 10; animation: fadeUp 0.8s cubic-bezier(0.16,1,0.3,1) forwards; }
    @keyframes fadeUp { from { opacity:0; transform:translateY(30px); } to { opacity:1; transform:translateY(0); } }
    .logo { margin-bottom: 24px; display: inline-flex; align-items: center; justify-content: center; width: 72px; height: 72px; background: linear-gradient(135deg, var(--primary), #818cf8); border-radius: 20px; box-shadow: 0 10px 20px rgba(83,109,254,0.3); font-size: 36px; }
    h1 { font-size: 24px; font-weight: 700; margin-bottom: 8px; }
    .badge { display: inline-block; background: rgba(83,109,254,0.15); border: 1px solid rgba(83,109,254,0.3); color: #a5b4fc; padding: 6px 14px; border-radius: 100px; font-weight: 600; font-size: 15px; margin-bottom: 24px; }
    .spinner-row { display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 13px; color: #60a5fa; margin-bottom: 20px; }
    .spinner { width: 16px; height: 16px; border: 2px solid rgba(96,165,250,0.2); border-top-color: #60a5fa; border-radius: 50%; animation: spin 1s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .msg { font-size: 15px; line-height: 1.6; color: var(--muted); margin-bottom: 32px; }
    .btn { display: block; width: 100%; padding: 16px 24px; font-size: 16px; font-weight: 600; border-radius: 16px; text-decoration: none; transition: all 0.2s ease; margin-bottom: 12px; border: none; cursor: pointer; }
    .primary { background: var(--primary); color: white; box-shadow: 0 8px 16px rgba(83,109,254,0.2); }
    .primary:hover { background: #4355db; transform: translateY(-2px); }
    .secondary { background: rgba(255,255,255,0.05); color: var(--text); border: 1px solid rgba(255,255,255,0.1); }
    .secondary:hover { background: rgba(255,255,255,0.1); transform: translateY(-2px); }
    .footer { margin-top: 32px; font-size: 12px; color: rgba(255,255,255,0.2); z-index: 10; }
  </style>
</head>
<body>
  <div class="glow1"></div>
  <div class="glow2"></div>
  <div class="card">
    <div class="logo">🚗</div>
    <h1>GaadiSaathi Profile</h1>
    <div class="badge" id="badge">${username || 'User'}</div>
    <div class="spinner-row"><div class="spinner"></div><span>Opening in GaadiSaathi App...</span></div>
    <p class="msg">If the app didn't open automatically, tap the button below to open it manually.</p>
    <a href="gaadisaathi://profile?u=${username}" class="btn primary" id="openBtn">Open in App</a>
    <a href="https://play.google.com/store/apps/details?id=com.gaadisaathi.rent.apps" class="btn secondary">Download App</a>
  </div>
  <div class="footer">&copy; 2026 GaadiSaathi. All rights reserved.</div>
  <script>
    setTimeout(() => {
      window.location.href = "gaadisaathi://profile?u=${username}";
    }, 500);
  </script>
</body>
</html>`);
};
