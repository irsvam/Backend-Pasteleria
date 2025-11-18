const express = require('express');
const bcrypt = require('bcryptjs');
const oracledb = require('oracledb');
const { runQuery } = require('../config/db');
const { generateToken } = require('../middleware/auth');

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const {
    nombre,
    email,
    telefono,
    contrasena,
    direccion,
    ciudad,
    codigo_postal,
    fecha_nacimiento,      // '2000-01-01'
    es_duoc_student,
    codigo_descuento       // ej: 'FELICES50'
  } = req.body;

  if (!nombre || !email || !contrasena) {
    return res.status(400).json({ ok: false, error: 'nombre, email y contrasena son obligatorios' });
  }

  try {
    // Verificar si ya existe
    const exists = await runQuery(
      'SELECT id_usuario FROM usuarios WHERE email = :email AND activo = 1',
      { email }
    );
    if (exists.rows.length > 0) {
      return res.status(400).json({ ok: false, error: 'El email ya está registrado' });
    }

    const hashed = await bcrypt.hash(contrasena, 10);

    const result = await runQuery(
      `INSERT INTO usuarios (
          id_usuario,
          nombre,
          email,
          telefono,
          contrasena,
          direccion,
          ciudad,
          codigo_postal,
          fecha_nacimiento,
          es_duoc_student,
          codigo_descuento_registrado,
          descuento_permanente,
          fecha_registro,
          activo
        )
        VALUES (
          seq_usuarios.NEXTVAL,
          :nombre,
          :email,
          :telefono,
          :contrasena,
          :direccion,
          :ciudad,
          :codigo_postal,
          :fecha_nacimiento,
          :es_duoc_student,
          :codigo_descuento_registrado,
          0,
          SYSDATE,
          1
        )
        RETURNING id_usuario INTO :id_usuario`,
      {
        nombre,
        email,
        telefono,
        contrasena: hashed,
        direccion,
        ciudad,
        codigo_postal,
        fecha_nacimiento: fecha_nacimiento ? new Date(fecha_nacimiento) : null,
        es_duoc_student: es_duoc_student ? 1 : 0,
        codigo_descuento_registrado: codigo_descuento || null,
        id_usuario: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
      }
    );

    const newId = result.outBinds.id_usuario[0];
    const token = generateToken({ id_usuario: newId, email });

    res.status(201).json({
      ok: true,
      id_usuario: newId,
      nombre,
      email,
      token
    });
  } catch (err) {
    console.error('Error en /auth/register:', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, contrasena } = req.body;

  if (!email || !contrasena) {
    return res.status(400).json({ ok: false, error: 'email y contrasena son obligatorios' });
  }

  try {
    const result = await runQuery(
      `SELECT id_usuario, nombre, email, contrasena
       FROM usuarios
       WHERE email = :email AND activo = 1`,
      { email },
      { autoCommit: false }
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ ok: false, error: 'Credenciales inválidas' });
    }

    const user = result.rows[0];
    const match = await bcrypt.compare(contrasena, user.CONTRASENA);
    if (!match) {
      return res.status(401).json({ ok: false, error: 'Credenciales inválidas' });
    }

    const token = generateToken({ id_usuario: user.ID_USUARIO, email: user.EMAIL });

    res.json({
      ok: true,
      id_usuario: user.ID_USUARIO,
      nombre: user.NOMBRE,
      email: user.EMAIL,
      token
    });
  } catch (err) {
    console.error('Error en /auth/login:', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
