const express = require('express');
const os = require('os');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Kubernetes!',
    hostname: os.hostname(),
    platform: process.env.CLOUD_PROVIDER || 'unknown',
    region: process.env.CLOUD_REGION || 'unknown',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.listen(port, () => {
  console.log(`API running on port ${port}`);
});