require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

// 🔹 IMPORTA AQUÍ TUS RUTAS
// Ajusta estas rutas según cómo se llamen tus archivos:
const authRoutes = require('./routes/auth.routes');
const discountRoutes = require('./routes/discounts.routes');
// Ejemplo extra (si tienes más):
// const productsRoutes = require('./routes/products.routes');

const app = express();

// =============================
// CONFIGURACIONES BÁSICAS
// =============================
const PORT = process.env.PORT || 3001;
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:5173';

// Middlewares
app.use(express.json());

// CORS: permite que el front (Vite) acceda al backend
app.use(
  cors({
    origin: FRONTEND_URL,
    credentials: true
  })
);

// =============================
// RUTAS BASE
// =============================

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Backend Pastelería funcionando',
    timestamp: new Date().toISOString()
  });
});

// Autenticación
app.use('/api/auth', authRoutes);

// Descuentos / checkout
app.use('/api', discountRoutes);

// Ejemplo: productos
// app.use('/api/productos', productsRoutes);

// =============================
// SERVIDOR
// =============================
app.listen(PORT, () => {
  console.log('====================================');
  console.log(`🚀 Servidor backend corriendo en el puerto ${PORT}`);
  console.log(`🌐 URL base: http://localhost:${PORT}/api`);
  console.log('====================================');
});
