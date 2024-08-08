const express = require('express');
const admin = require('firebase-admin');
const serviceAccount = require('./restoinov-firebase-adminsdk-ofvrr-5e76cbc8e2.json');

// Initialisation de l'application Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();

// Fonction pour obtenir un token d'accès OAuth 2.0
async function getAccessToken() {
  const accessToken = await admin.credential.cert(serviceAccount).getAccessToken();
  return accessToken.access_token;
}

// Endpoint API pour fournir le token d'accès
app.get('/get-token', async (req, res) => {
  try {
    const token = await getAccessToken();
    res.json({ accessToken: token });
  } catch (error) {
    console.error('Erreur lors de la génération du token:', error);
    res.status(500).send('Erreur lors de la génération du token');
  }
});

// Démarrer le serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
});
