const express = require('express');
const app = express();

app.get('/get-token', async (req, res) => {
  try {
    const token = await getAccessToken();
    res.json({ accessToken: token });
  } catch (error) {
    res.status(500).send('Erreur lors de la génération du token');
  }
});

app.listen(3000, () => {
  console.log('Serveur démarré sur le port 3000');
});
