const express = require('express');
const { getConnection } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// GET /api/admin/reportes/descuentos
router.get('/reportes/descuentos', authMiddleware, async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    const auditRes = await conn.execute(
      `SELECT id_auditoria, id_usuario, id_pedido, tipo_descuento,
              porcentaje_aplicado, monto_original, monto_descuento,
              monto_final, razon, fecha_aplicacion
       FROM auditoria_descuentos
       ORDER BY fecha_aplicacion DESC`
    );

    const resumenRes = await conn.execute(
      `SELECT id_usuario,
              total_descuentos_aplicados,
              monto_total_descuentado,
              monto_total_compras,
              promedio_descuento
       FROM v_resumen_descuentos_usuario`
    );

    res.json({
      ok: true,
      auditoria: auditRes.rows || [],
      resumen_por_usuario: resumenRes.rows || []
    });
  } catch (err) {
    console.error('Error en GET /admin/reportes/descuentos:', err);
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    if (conn) {
      try { await conn.close(); } catch (e) {}
    }
  }
});

module.exports = router;
