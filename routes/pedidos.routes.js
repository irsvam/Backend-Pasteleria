const express = require('express');
const { getConnection } = require('../config/db');
const { authMiddleware } = require('../middleware/auth');
const oracledb = require('oracledb');

const router = express.Router();

// POST /api/pedidos - Crear nuevo pedido
router.post('/', authMiddleware, async (req, res) => {
  const {
    id_usuario,
    items, // [{ id_producto, cantidad, precio_unitario }]
    direccion_entrega,
    fecha_entrega
  } = req.body;

  if (!id_usuario || !items || items.length === 0) {
    return res.status(400).json({
      ok: false,
      error: 'id_usuario y items son obligatorios'
    });
  }

  let conn;
  try {
    conn = await getConnection();

    // 1. Calcular total
    const total = items.reduce((sum, item) => {
      return sum + (item.precio_unitario * item.cantidad);
    }, 0);

    // 2. Crear pedido
    const pedidoResult = await conn.execute(
      `INSERT INTO pedidos (
        id_pedido,
        id_usuario,
        fecha_pedido,
        estado,
        total,
        direccion_entrega,
        fecha_entrega
      ) VALUES (
        seq_pedidos.NEXTVAL,
        :id_usuario,
        SYSDATE,
        'Pendiente',
        :total,
        :direccion_entrega,
        :fecha_entrega
      ) RETURNING id_pedido INTO :id_pedido`,
      {
        id_usuario,
        total,
        direccion_entrega: direccion_entrega || null,
        fecha_entrega: fecha_entrega ? new Date(fecha_entrega) : null,
        id_pedido: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      },
      { autoCommit: false }
    );

    const id_pedido = pedidoResult.outBinds.id_pedido[0];

    // 3. Insertar detalles del pedido (AQUÍ SE ACTIVA EL TRIGGER)
    for (const item of items) {
      const subtotal = item.precio_unitario * item.cantidad;

      await conn.execute(
        `INSERT INTO detalles_pedido (
          id_detalle,
          id_pedido,
          id_producto,
          cantidad,
          precio_unitario,
          subtotal
        ) VALUES (
          seq_detalles_pedido.NEXTVAL,
          :id_pedido,
          :id_producto,
          :cantidad,
          :precio_unitario,
          :subtotal
        )`,
        {
          id_pedido,
          id_producto: item.id_producto,
          cantidad: item.cantidad,
          precio_unitario: item.precio_unitario,
          subtotal
        },
        { autoCommit: false }
      );
    }

    // 4. Commit de la transacción
    await conn.commit();

    res.status(201).json({
      ok: true,
      id_pedido,
      total,
      mensaje: 'Pedido creado exitosamente. El stock se actualizó automáticamente.'
    });

  } catch (err) {
    if (conn) {
      try {
        await conn.rollback();
      } catch (rollbackErr) {
        console.error('Error en rollback:', rollbackErr);
      }
    }

    console.error('Error en POST /pedidos:', err);
    
    // Manejar error de stock insuficiente
    if (err.message.includes('stock')) {
      return res.status(400).json({
        ok: false,
        error: 'Stock insuficiente para uno o más productos'
      });
    }

    res.status(500).json({
      ok: false,
      error: 'Error al crear pedido',
      details: err.message
    });
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (e) {
        console.error('Error cerrando conexión:', e);
      }
    }
  }
});

// GET /api/pedidos/usuario/:id - Obtener pedidos de un usuario
router.get('/usuario/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  let conn;
  try {
    conn = await getConnection();

    const pedidosResult = await conn.execute(
      `SELECT 
        p.id_pedido,
        p.fecha_pedido,
        p.estado,
        p.total,
        p.direccion_entrega,
        p.fecha_entrega
       FROM pedidos p
       WHERE p.id_usuario = :id
       ORDER BY p.fecha_pedido DESC`,
      { id: Number(id) }
    );

    const pedidos = [];

    for (const pedido of pedidosResult.rows) {
      const detallesResult = await conn.execute(
        `SELECT 
          d.id_detalle,
          d.cantidad,
          d.precio_unitario,
          d.subtotal,
          pr.nombre AS producto_nombre,
          pr.imagen_url
         FROM detalles_pedido d
         INNER JOIN productos pr ON d.id_producto = pr.id_producto
         WHERE d.id_pedido = :id_pedido`,
        { id_pedido: pedido.ID_PEDIDO }
      );

      pedidos.push({
        id_pedido: pedido.ID_PEDIDO,
        fecha_pedido: pedido.FECHA_PEDIDO,
        estado: pedido.ESTADO,
        total: pedido.TOTAL,
        direccion_entrega: pedido.DIRECCION_ENTREGA,
        fecha_entrega: pedido.FECHA_ENTREGA,
        items: detallesResult.rows.map(d => ({
          id_detalle: d.ID_DETALLE,
          cantidad: d.CANTIDAD,
          precio_unitario: d.PRECIO_UNITARIO,
          subtotal: d.SUBTOTAL,
          producto_nombre: d.PRODUCTO_NOMBRE,
          imagen_url: d.IMAGEN_URL
        }))
      });
    }

    res.json({
      ok: true,
      count: pedidos.length,
      data: pedidos
    });

  } catch (err) {
    console.error('Error en GET /pedidos/usuario/:id:', err);
    res.status(500).json({
      ok: false,
      error: 'Error al obtener pedidos',
      details: err.message
    });
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (e) {}
    }
  }
});

// GET /api/pedidos/:id - Obtener detalle de un pedido
router.get('/:id', authMiddleware, async (req, res) => {
  const { id } = req.params;

  let conn;
  try {
    conn = await getConnection();

    const pedidoResult = await conn.execute(
      `SELECT 
        p.id_pedido,
        p.id_usuario,
        p.fecha_pedido,
        p.estado,
        p.total,
        p.direccion_entrega,
        p.fecha_entrega,
        u.nombre AS usuario_nombre,
        u.email AS usuario_email
       FROM pedidos p
       INNER JOIN usuarios u ON p.id_usuario = u.id_usuario
       WHERE p.id_pedido = :id`,
      { id: Number(id) }
    );

    if (pedidoResult.rows.length === 0) {
      return res.status(404).json({
        ok: false,
        error: 'Pedido no encontrado'
      });
    }

    const pedido = pedidoResult.rows[0];

    const detallesResult = await conn.execute(
      `SELECT 
        d.id_detalle,
        d.cantidad,
        d.precio_unitario,
        d.subtotal,
        pr.id_producto,
        pr.nombre AS producto_nombre,
        pr.imagen_url
       FROM detalles_pedido d
       INNER JOIN productos pr ON d.id_producto = pr.id_producto
       WHERE d.id_pedido = :id`,
      { id: Number(id) }
    );

    res.json({
      ok: true,
      data: {
        id_pedido: pedido.ID_PEDIDO,
        id_usuario: pedido.ID_USUARIO,
        fecha_pedido: pedido.FECHA_PEDIDO,
        estado: pedido.ESTADO,
        total: pedido.TOTAL,
        direccion_entrega: pedido.DIRECCION_ENTREGA,
        fecha_entrega: pedido.FECHA_ENTREGA,
        usuario: {
          nombre: pedido.USUARIO_NOMBRE,
          email: pedido.USUARIO_EMAIL
        },
        items: detallesResult.rows.map(d => ({
          id_detalle: d.ID_DETALLE,
          id_producto: d.ID_PRODUCTO,
          cantidad: d.CANTIDAD,
          precio_unitario: d.PRECIO_UNITARIO,
          subtotal: d.SUBTOTAL,
          producto_nombre: d.PRODUCTO_NOMBRE,
          imagen_url: d.IMAGEN_URL
        }))
      }
    });

  } catch (err) {
    console.error('Error en GET /pedidos/:id:', err);
    res.status(500).json({
      ok: false,
      error: 'Error al obtener pedido',
      details: err.message
    });
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (e) {}
    }
  }
});

module.exports = router;