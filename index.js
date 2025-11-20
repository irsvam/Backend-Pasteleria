require('dotenv').config();
const express = require('express');
const cors = require('cors');

// Rutas
const authRoutes = require('./routes/auth.routes');
const discountRoutes = require('./routes/discounts.routes');
const adminRoutes = require('./routes/admin.routes');
const productsRoutes = require('./routes/products.routes'); // NUEVO
const pedidosRoutes = require('./routes/pedidos.routes');   // NUEVO

const app = express();
const PORT = process.env.PORT || 3001;
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:5173';

// Middlewares
app.use(express.json());
app.use(cors({
  origin: FRONTEND_URL,
  credentials: true
}));

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Backend Pastelería funcionando',
    timestamp: new Date().toISOString()
  });
});

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api', discountRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/productos', productsRoutes);  // NUEVO
app.use('/api/pedidos', pedidosRoutes);     // NUEVO

// Error 404
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Ruta no encontrada',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Error interno del servidor'
  });
});

// Iniciar servidor
app.listen(PORT, () => {
  console.log('====================================');
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
  console.log('====================================');
});