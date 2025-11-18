const oracledb = require('oracledb');

let pool;

const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  connectString: process.env.DB_CONNECTIONSTRING
};

async function initPool() {
  if (pool) return pool;

  if (!dbConfig.user || !dbConfig.password || !dbConfig.connectString) {
    throw new Error('Faltan variables de entorno DB_USER / DB_PASSWORD / DB_CONNECTIONSTRING');
  }

  console.log('Creando pool Oracle...');
  pool = await oracledb.createPool({
    user: dbConfig.user,
    password: dbConfig.password,
    connectString: dbConfig.connectString,
    poolMin: 1,
    poolMax: 5,
    poolIncrement: 1
  });
  console.log('Pool Oracle creado.');
  return pool;
}

async function getConnection() {
  if (!pool) {
    await initPool();
  }
  return pool.getConnection();
}

async function runQuery(sql, binds = {}, options = {}) {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      sql,
      binds,
      {
        autoCommit: options.autoCommit ?? true,
        ...options
      }
    );
    return result;
  } catch (err) {
    console.error('Error en runQuery:', err.message, '\nSQL:', sql, '\nBINDS:', binds);
    throw err;
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (err) {
        console.error('Error al cerrar conexión:', err.message);
      }
    }
  }
}

async function closePool() {
  if (pool) {
    await pool.close(10);
    console.log('Pool Oracle cerrado.');
  }
}

module.exports = {
  initPool,
  getConnection,
  runQuery,
  closePool
};
