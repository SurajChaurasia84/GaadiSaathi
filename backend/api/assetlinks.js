// api/.well-known/assetlinks.json.js
// Serves the Digital Asset Links JSON for Android App Link verification
module.exports = (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.status(200).json([
    {
      "relation": [
        "delegate_permission/common.handle_all_urls"
      ],
      "target": {
        "namespace": "android_app",
        "package_name": "com.gaadisaathi.rent.apps",
        "sha256_cert_fingerprints": [
          "15:73:19:4f:27:4d:24:a6:72:dc:45:24:50:52:c8:bb:b7:bb:0d:1c:91:cf:08:6e:13:30:ce:d0:35:87:66:81",
          "3e:1f:c7:17:f6:4c:c9:5d:cf:f0:37:45:fb:2f:88:a8:bb:a2:a7:8f:96:34:3c:92:a9:87:fe:07:a6:3d:fc:a3"
        ]
      }
    }
  ]);
};
