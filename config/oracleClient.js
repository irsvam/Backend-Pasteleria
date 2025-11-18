const oracledb = require('oracledb');
const path = require('path');

function initOracleClient() {
  try {
    // Si usas wallet de Oracle, descomenta y ajusta:
    // const walletPath = path.resolve(__dirname, '..', 'wallet_pasteleria');
    // oracledb.initOracleClient({ configDir: walletPath });

    // Salida como objetos { COLUMNA: valor }
    oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;

    console.log('Cliente Oracle inicializado (wallet opcional).');
  } catch (err) {
    console.error('Error inicializando cliente Oracle:', err.message);
  }
}

module.exports = {
  initOracleClient
};
