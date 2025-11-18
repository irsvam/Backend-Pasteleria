require('dotenv').config();
const express = require('express');
const cors = require('cors');
const oracledb = require('oracledb');
const path = require('path');
const fs = require('fs');

const authRoutes = require('./routes/auth.routes');
const discountsRoutes = require('./routes/discounts.routes');
const adminRoutes = require('./routes/admin.routes');

const app = express();
const port = process.env.PORT || 3001;

// ===============================
// 1. CONFIGURACIÓN ORACLE WALLET
// ===============================
try {
  // Ruta a la carpeta del wallet
  const walletPath = path.resolve(__dirname, 'config', 'Wallet_yayondata2');

  console.log('==============================================');
  console.log('', walletPath);
  console.log('==============================================');

  // Verificar que la carpeta existe
  if (!fs.existsSync(walletPath)) {
    throw new Error(`❌ La carpeta de wallet no existe: ${walletPath}`);
  }

  // Mostrar archivos disponibles en la wallet
  const walletFiles = fs.readdirSync(walletPath);
  console.log('📄 Archivos en wallet:', walletFiles);

  // Verificar archivos críticos
  const requiredFiles = ['tnsnames.ora', 'sqlnet.ora', 'cwallet.sso'];
  const missingFiles = requiredFiles.filter(file => !walletFiles.includes(file));
  
  if (missingFiles.length > 0) {
    console.warn('⚠️  Archivos faltantes en wallet:', missingFiles);
  }

  // Inicializar cliente Oracle con la wallet
  oracledb.initOracleClient({
    configDir: walletPath,
    // Si usas Instant Client en Windows, descomenta y ajusta la ruta:
    // libDir: 'C:\\instantclient_19_8'
  });

  console.log('✅ Cliente Oracle inicializado correctamente');
  console.log('==============================================\n');
} catch (err) {
  console.error('❌ Error inicializando el cliente de Oracle:', err.message);
  process.exit(1);
}

// ===============================
// 2. MIDDLEWARES
// ===============================
app.use(cors());
app.use(express.json());

// ===============================
// 3. CONFIGURACIÓN DE CONEXIÓN BD
// ===============================
const dbConfig = {
  user: process.env.DB_USER || 'admin',
  password: process.env.DB_PASSWORD || 'Duoc25...',
  connectString: process.env.DB_CONNECT_STRING || 'yayondata2_high',
  // Configuración de pool (opcional pero recomendado)
  poolMin: 1,
  poolMax: 5,
  poolIncrement: 1,
};

console.log('🔧 Configuración de BD:');
console.log('   Usuario:', dbConfig.user);
console.log('   Connect String:', dbConfig.connectString);
console.log('   Password:', '****');
console.log('==============================================\n');

// ===============================
// 4. PRUEBA DE CONEXIÓN AL INICIAR
// ===============================
async function testConnection() {
  let connection;
  try {
    console.log('🔄 Probando conexión a la base de datos...');
    connection = await oracledb.getConnection(dbConfig);
    console.log('✅ ¡Conexión a BD exitosa!');
    console.log('   Versión Oracle:', connection.oracleServerVersionString);
    console.log('==============================================\n');
  } catch (err) {
    console.error('❌ Error al conectar a la BD:');
    console.error('   Mensaje:', err.message);
    console.error('   Código:', err.errorNum);
    console.error('\n💡 Verifica:');
    console.error('   1. Credenciales en .env (DB_USER, DB_PASSWORD, DB_CONNECT_STRING)');
    console.error('   2. Que yayondata2_high existe en tnsnames.ora');
    console.error('   3. Que todos los archivos de wallet están presentes');
    console.error('==============================================\n');
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error al cerrar la conexión de prueba:', err.message);
      }
    }
  }
}

// Ejecutar prueba de conexión
testConnection();

// ===============================
// 5. HELPER GENÉRICO PARA CONSULTAS
// ===============================
async function runQuery(query, params = []) {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    
    const result = await connection.execute(query, params, {
      outFormat: oracledb.OUT_FORMAT_OBJECT,
      autoCommit: true, // Para operaciones INSERT/UPDATE/DELETE
    });
    
    return result.rows;
  } catch (err) {
    console.error('❌ Error en consulta a la BD:', err.message);
    console.error('   Query:', query);
    console.error('   Params:', params);
    throw err;
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error al cerrar la conexión:', err.message);
      }
    }
  }
}

// Hacer disponible runQuery para las rutas
app.locals.runQuery = runQuery;

// ===============================
// 6. RUTAS BÁSICAS DE PRUEBA
// ===============================
app.get('/', (req, res) => {
  res.json({ 
    message: '🧁 Backend Pastelería funcionando',
    status: 'OK',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'Backend Pastelería OK 🧁',
    database: 'Oracle Cloud',
    connection: 'Configurada'
  });
});

// Endpoint para probar conexión desde el cliente
app.get('/api/health', async (req, res) => {
  let connection;
  try {
    connection = await oracledb.getConnection(dbConfig);
    res.json({ 
      status: 'healthy',
      database: 'connected',
      version: connection.oracleServerVersionString,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({ 
      status: 'unhealthy',
      database: 'disconnected',
      error: err.message,
      timestamp: new Date().toISOString()
    });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

// Ejemplo de endpoint para productos
app.get('/api/productos', async (req, res) => {
  try {
    const productos = await runQuery('SELECT * FROM ADMIN.productos');
    res.json({
      success: true,
      count: productos.length,
      data: productos
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error al consultar los productos',
      details: err.message,
    });
  }
});

// Ejemplo de endpoint para restaurantes
app.get('/api/restaurantes', async (req, res) => {
  try {
    const restaurantes = await runQuery('SELECT * FROM ADMIN.restaurantes');
    res.json({
      success: true,
      count: restaurantes.length,
      data: restaurantes
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error al consultar los restaurantes',
      details: err.message,
    });
  }
});

// ===============================
// 7. RUTAS MODULARES
// ===============================
app.use('/api/auth', authRoutes);
app.use('/api', discountsRoutes);       // /usuario/:id/descuentos, /checkout/aplicar-descuento
app.use('/api/admin', adminRoutes);     // /admin/reportes/descuentos

// ===============================
// 8. MANEJO DE ERRORES 404 Y 500
// ===============================
app.use((req, res, next) => {
  res.status(404).json({ 
    success: false,
    message: 'Ruta no encontrada',
    path: req.path 
  });
});

app.use((err, req, res, next) => {
  console.error('❌ Error inesperado:', err);
  res.status(500).json({ 
    success: false,
    message: 'Error interno del servidor',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// ===============================
// 9. INICIAR SERVIDOR
// ===============================
app.listen(port, () => {
  console.log('==============================================');
  console.log(`🚀 Servidor backend corriendo`);
  console.log(`   URL: http://localhost:${port}`);
  console.log(`   Ambiente: ${process.env.NODE_ENV || 'development'}`);
  console.log('==============================================\n');
  console.log('📋 Endpoints disponibles:');
  console.log(`   GET  http://localhost:${port}/`);
  console.log(`   GET  http://localhost:${port}/api/test`);
  console.log(`   GET  http://localhost:${port}/api/health`);
  console.log(`   GET  http://localhost:${port}/api/productos`);
  console.log(`   GET  http://localhost:${port}/api/restaurantes`);
  console.log('==============================================\n');
});

// Manejo de cierre graceful
process.on('SIGINT', async () => {
  console.log('\n🛑 Cerrando servidor...');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Cerrando servidor...');
  process.exit(0);
});

module.exports = app