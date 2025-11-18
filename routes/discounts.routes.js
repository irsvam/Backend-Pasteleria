const express = require('express');
const { runQuery, getConnection } = require('../config/db');

const router = express.Router();

// GET /api/usuario/:id/descuentos
router.get('/usuario/:id/descuentos', async (req, res) => {
  const id = Number(req.params.id);

  if (Number.isNaN(id)) {
    return res.status(400).json({ ok: false, error: 'ID inválido' });
  }

  try {
    const userRes = await runQuery(
      `SELECT id_usuario, nombre, email, fecha_nacimiento, es_duoc_student,
              codigo_descuento_registrado, descuento_permanente
       FROM usuarios
       WHERE id_usuario = :id AND activo = 1`,
      { id }
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({ ok: false, error: 'Usuario no encontrado' });
    }

    const usuario = userRes.rows[0];
    const discounts = [];

    // MAYOR 50
    const mayorRes = await runQuery(
      `SELECT id_usuario FROM v_usuarios_mayores_50 WHERE id_usuario = :id`,
      { id }
    );
    if (mayorRes.rows.length > 0) {
      discounts.push({
        code: 'MAYOR_50',
        label: 'Descuento 50% por ser mayor de 50 años',
        porcentaje: 50
      });
    }

    // FELICES50
    const felicesRes = await runQuery(
      `SELECT id_usuario FROM v_usuarios_felices50 WHERE id_usuario = :id`,
      { id }
    );
    if (felicesRes.rows.length > 0) {
      discounts.push({
        code: 'FELICES50',
        label: 'Descuento 10% por código FELICES50',
        porcentaje: 10
      });
    }

    // DUOC cumple
    const duocRes = await runQuery(
      `SELECT id_usuario FROM v_estudiantes_duoc_cupones WHERE id_usuario = :id`,
      { id }
    );
    if (duocRes.rows.length > 0) {
      discounts.push({
        code: 'DUOC_CUMPLE',
        label: 'CUPÓN DUOC: torta gratis en cumpleaños',
        porcentaje: 100
      });
    }

    // Descuento permanente
    if (usuario.DESCUENTO_PERMANENTE && usuario.DESCUENTO_PERMANENTE > 0) {
      discounts.push({
        code: 'PERMANENTE',
        label: 'Descuento permanente del usuario',
        porcentaje: usuario.DESCUENTO_PERMANENTE
      });
    }

    res.json({
      ok: true,
      usuario: {
        id_usuario: usuario.ID_USUARIO,
        nombre: usuario.NOMBRE,
        email: usuario.EMAIL
      },
      discounts
    });
  } catch (err) {
    console.error('Error en GET /usuario/:id/descuentos:', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /api/checkout/aplicar-descuento
router.post('/checkout/aplicar-descuento', async (req, res) => {
  const { id_pedido, id_usuario, monto_original, aplicar_descuento = 1 } = req.body;

  if (!id_pedido || !id_usuario || typeof monto_original !== 'number') {
    return res.status(400).json({
      ok: false,
      error: 'id_pedido, id_usuario y monto_original son obligatorios'
    });
  }

  let conn;
  try {
    conn = await getConnection();

    await conn.execute(
      `BEGIN
         sp_aplicar_descuento_pedido(
           :p_id_pedido,
           :p_id_usuario,
           :p_monto_original,
           :p_aplicar_descuento
         );
       END;`,
      {
        p_id_pedido: id_pedido,
        p_id_usuario: id_usuario,
        p_monto_original: monto_original,
        p_aplicar_descuento: aplicar_descuento ? 1 : 0
      },
      { autoCommit: true }
    );

    const auditRes = await conn.execute(
      `SELECT id_auditoria, id_usuario, id_pedido, tipo_descuento,
              porcentaje_aplicado, monto_original, monto_descuento,
              monto_final, razon, fecha_aplicacion
       FROM auditoria_descuentos
       WHERE id_usuario = :id_usuario
         AND id_pedido = :id_pedido
       ORDER BY fecha_aplicacion DESC`,
      { id_usuario, id_pedido }
    );

    const audit = auditRes.rows[0] || null;

    res.json({
      ok: true,
      auditoria: audit
        ? {
            id_auditoria: audit.ID_AUDITORIA,
            id_usuario: audit.ID_USUARIO,
            id_pedido: audit.ID_PEDIDO,
            tipo_descuento: audit.TIPO_DESCUENTO,
            porcentaje: audit.PORCENTAJE_APLICADO,
            monto_original: audit.MONTO_ORIGINAL,
            monto_descuento: audit.MONTO_DESCUENTO,
            monto_final: audit.MONTO_FINAL,
            razon: audit.RAZON,
            fecha_aplicacion: audit.FECHA_APLICACION
          }
        : null
    });
  } catch (err) {
    console.error('Error en POST /checkout/aplicar-descuento:', err);
    res.status(500).json({ ok: false, error: err.message });
  } finally {
    if (conn) {
      try { await conn.close(); } catch (e) {}
    }
  }
});

module.exports = router;
