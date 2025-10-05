const express = require('express');
const path = require('path');
const app = express();
const PORT = 5000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static('public'));
app.use('/flutter-source', express.static('life_management_app'));

app.get('/', (req, res) => {
  res.render('index');
});

app.get('/setup', (req, res) => {
  res.render('setup');
});

app.get('/database', (req, res) => {
  res.render('database');
});

app.get('/deployment', (req, res) => {
  res.render('deployment');
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`📚 Flutter Life Management App Documentation Server running on port ${PORT}`);
  console.log(`🚀 Access the documentation at http://localhost:${PORT}`);
});
