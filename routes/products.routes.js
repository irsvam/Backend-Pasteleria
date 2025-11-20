const express = require('express');
const { runQuery } = require('../config/db');

const router = express.Router();

// GET /api/productos - Obtener todos los productos
router.get('/', async (req, res) => {
  try {
    const result = await runQuery(
      `SELECT 
        p.id_producto,
        p.nombre,
        p.descripcion,
        p.precio,
        p.stock,
        p.imagen_url,
        p.activo,
        c.nombre AS categoria,
        c.id_categoria
       FROM productos p
       INNER JOIN categorias c ON p.id_categoria = c.id_categoria
       WHERE p.activo = 1
       ORDER BY p.nombre`
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows.map(row => ({
        id_producto: row.ID_PRODUCTO,
        nombre: row.NOMBRE,
        descripcion: row.DESCRIPCION,
        precio: row.PRECIO,
        stock: row.STOCK,
        imagen_url: row.IMAGEN_URL,
        categoria: row.CATEGORIA,
        id_categoria: row.ID_CATEGORIA,
        activo: row.ACTIVO
      }))
    });
  } catch (err) {
    console.error('Error en GET /productos:', err);
    res.status(500).json({
      success: false,
      error: 'Error al obtener productos',
      details: err.message
    });
  }
});

// GET /api/productos/:id - Obtener un producto específico
router.get('/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await runQuery(
      `SELECT 
        p.id_producto,
        p.nombre,
        p.descripcion,
        p.precio,
        p.stock,
        p.imagen_url,
        p.activo,
        c.nombre AS categoria,
        c.id_categoria
       FROM productos p
       INNER JOIN categorias c ON p.id_categoria = c.id_categoria
       WHERE p.id_producto = :id AND p.activo = 1`,
      { id: Number(id) }
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Producto no encontrado'
      });
    }

    const row = result.rows[0];
    res.json({
      success: true,
      data: {
        id_producto: row.ID_PRODUCTO,
        nombre: row.NOMBRE,
        descripcion: row.DESCRIPCION,
        precio: row.PRECIO,
        stock: row.STOCK,
        imagen_url: row.IMAGEN_URL,
        categoria: row.CATEGORIA,
        id_categoria: row.ID_CATEGORIA,
        activo: row.ACTIVO
      }
    });
  } catch (err) {
    console.error('Error en GET /productos/:id:', err);
    res.status(500).json({
      success: false,
      error: 'Error al obtener producto',
      details: err.message
    });
  }
});

// GET /api/productos/categoria/:id - Productos por categoría
router.get('/categoria/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const result = await runQuery(
      `SELECT 
        p.id_producto,
        p.nombre,
        p.descripcion,
        p.precio,
        p.stock,
        p.imagen_url,
        c.nombre AS categoria
       FROM productos p
       INNER JOIN categorias c ON p.id_categoria = c.id_categoria
       WHERE p.id_categoria = :id AND p.activo = 1
       ORDER BY p.nombre`,
      { id: Number(id) }
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows.map(row => ({
        id_producto: row.ID_PRODUCTO,
        nombre: row.NOMBRE,
        descripcion: row.DESCRIPCION,
        precio: row.PRECIO,
        stock: row.STOCK,
        imagen_url: row.IMAGEN_URL,
        categoria: row.CATEGORIA
      }))
    });
  } catch (err) {
    console.error('Error en GET /productos/categoria/:id:', err);
    res.status(500).json({
      success: false,
      error: 'Error al obtener productos por categoría',
      details: err.message
    });
  }
});

module.exports = router;