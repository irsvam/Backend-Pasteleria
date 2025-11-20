-- ============================================
-- CONSULTAS ÚTILES PARA GESTIÓN DE DESCUENTOS
-- ============================================

-- 1. CONSULTAR USUARIOS MAYORES DE 50 AÑOS CON DERECHO A 50% DE DESCUENTO
SELECT * FROM v_usuarios_mayores_50;

-- 2. CONSULTAR USUARIOS CON CÓDIGO FELICES50 Y DESCUENTO DEL 10%
SELECT * FROM v_usuarios_felices50;

-- 3. CONSULTAR ESTUDIANTES DUOC CON CUPONES DE TORTA GRATIS EN CUMPLEAÑOS
SELECT * FROM v_estudiantes_duoc_cupones;

-- 4. RESUMEN DE DESCUENTOS APLICADOS POR USUARIO
SELECT * FROM v_resumen_descuentos_usuario;

-- ============================================
-- CONSULTAS DETALLADAS PARA VALIDAR BENEFICIOS
-- ============================================

-- 5. VALIDAR SI UN USUARIO TIENE DERECHO A DESCUENTO POR EDAD
SELECT 
    u.id_usuario,
    u.nombre,
    u.email,
    u.fecha_nacimiento,
    TRUNC((SYSDATE - u.fecha_nacimiento) / 365.25) AS edad,
    CASE 
        WHEN TRUNC((SYSDATE - u.fecha_nacimiento) / 365.25) >= 50 
        THEN 'SÍ - 50% descuento'
        ELSE 'NO'
    END AS derecho_descuento_edad
FROM usuarios u
WHERE u.activo = 1
ORDER BY u.fecha_nacimiento;

-- 6. VALIDAR SI UN USUARIO ES ESTUDIANTE DUOC Y SU CUMPLEAÑOS
SELECT 
    u.id_usuario,
    u.nombre,
    u.email,
    CASE 
        WHEN u.es_duoc_student = 1 THEN 'Sí'
        ELSE 'No'
    END AS es_estudiante_duoc,
    c.fecha_cumpleaños,
    c.codigo_cupon,
    c.estado AS estado_cupon,
    TRUNC((c.fecha_cumpleaños - SYSDATE)) AS dias_para_cumpleaños
FROM usuarios u
LEFT JOIN cupones_estudiante_duoc c ON u.id_usuario = c.id_usuario
WHERE u.activo = 1
ORDER BY u.nombre;

-- 7. VALIDAR CÓDIGOS DE DESCUENTO ACTIVOS
SELECT 
    codigo,
    nombre,
    descripcion,
    descuento_porcentaje,
    tipo_descuento,
    fecha_inicio,
    fecha_fin,
    maximo_usos,
    usos_actuales,
    (maximo_usos - usos_actuales) AS usos_restantes,
    CASE 
        WHEN SYSDATE BETWEEN fecha_inicio AND fecha_fin THEN 'ACTIVO'
        ELSE 'INACTIVO'
    END AS estado_vigencia
FROM codigos_descuento
ORDER BY fecha_fin DESC;

-- 8. AUDITORÍA - VER TODOS LOS DESCUENTOS APLICADOS
SELECT 
    ad.id_auditoria,
    u.nombre AS usuario,
    p.id_pedido,
    ad.tipo_descuento,
    ad.porcentaje_aplicado,
    ad.monto_original,
    ad.monto_descuento,
    ad.monto_final,
    ad.razon,
    ad.fecha_aplicacion
FROM auditoria_descuentos ad
INNER JOIN usuarios u ON ad.id_usuario = u.id_usuario
LEFT JOIN pedidos p ON ad.id_pedido = p.id_pedido
ORDER BY ad.fecha_aplicacion DESC;

-- 9. AUDITORÍA - DESCUENTOS TOTALES POR TIPO
SELECT 
    tipo_descuento,
    COUNT(*) AS cantidad_aplicaciones,
    SUM(monto_descuento) AS monto_total_descuentado,
    ROUND(AVG(porcentaje_aplicado), 2) AS promedio_descuento
FROM auditoria_descuentos
GROUP BY tipo_descuento
ORDER BY monto_total_descuentado DESC;

-- 10. ESTADO DE CUPONES DUOC
SELECT 
    c.id_cupon,
    u.nombre,
    u.email,
    c.fecha_cumpleaños,
    c.codigo_cupon,
    c.torta_gratis,
    c.descuento_porcentaje,
    c.estado,
    c.fecha_uso,
    CASE 
        WHEN c.estado = 'Usado' THEN 'Cupón Utilizado'
        WHEN SYSDATE BETWEEN c.fecha_cumpleaños - 7 AND c.fecha_cumpleaños + 7 THEN 'En Vigencia de Cumpleaños'
        WHEN SYSDATE > c.fecha_cumpleaños + 7 THEN 'Expirado'
        ELSE 'Pendiente'
    END AS estado_vigencia_cupon
FROM cupones_estudiante_duoc c
INNER JOIN usuarios u ON c.id_usuario = u.id_usuario
ORDER BY c.fecha_cumpleaños;

-- ============================================
-- CONSULTAS PARA GENERAR REPORTES
-- ============================================

-- 11. REPORTE: USUARIOS CON BENEFICIOS ESPECIALES
SELECT 
    u.id_usuario,
    u.nombre,
    u.email,
    CASE 
        WHEN TRUNC((SYSDATE - u.fecha_nacimiento) / 365.25) >= 50 
        THEN 'Mayor 50 años (50%)'
        ELSE '-'
    END AS beneficio_edad,
    u.codigo_descuento_registrado AS codigo_permanente,
    u.descuento_permanente AS desc_permanente,
    CASE 
        WHEN u.es_duoc_student = 1 THEN 'Sí'
        ELSE 'No'
    END AS estudiante_duoc
FROM usuarios u
WHERE u.activo = 1
  AND (
    TRUNC((SYSDATE - u.fecha_nacimiento) / 365.25) >= 50
    OR u.codigo_descuento_registrado IS NOT NULL
    OR u.es_duoc_student = 1
  )
ORDER BY u.nombre;

-- 12. REPORTE: INGRESOS TOTALES VS DESCUENTOS APLICADOS
SELECT 
    SUM(monto_original) AS ingresos_sin_descuento,
    SUM(monto_descuento) AS total_descuentos_otorgados,
    SUM(monto_final) AS ingresos_netos,
    ROUND(100.0 * SUM(monto_descuento) / SUM(monto_original), 2) AS porcentaje_impacto_descuentos
FROM auditoria_descuentos;

-- 13. REPORTE: INGRESOS Y DESCUENTOS POR USUARIO
SELECT 
    u.id_usuario,
    u.nombre,
    COUNT(ad.id_auditoria) AS transacciones_con_descuento,
    SUM(ad.monto_original) AS monto_sin_descuento,
    SUM(ad.monto_descuento) AS monto_total_descuentado,
    SUM(ad.monto_final) AS monto_pagado,
    ROUND(AVG(ad.porcentaje_aplicado), 2) AS descuento_promedio_usuario
FROM usuarios u
LEFT JOIN auditoria_descuentos ad ON u.id_usuario = ad.id_usuario
WHERE u.activo = 1
GROUP BY u.id_usuario, u.nombre
HAVING COUNT(ad.id_auditoria) > 0
ORDER BY SUM(ad.monto_total_descuentado) DESC;

-- 14. REPORTE: PROYECCIÓN DE INGRESOS POR DESCUENTO FELICES50
-- Usuarios registrados con FELICES50 y su impacto en ingresos mensuales
SELECT 
    u.nombre,
    u.email,
    u.descuento_permanente,
    COUNT(DISTINCT ad.id_pedido) AS pedidos_realizados,
    SUM(ad.monto_descuento) AS total_descuentos_recibidos,
    ROUND(SUM(ad.monto_descuento) / NULLIF(COUNT(DISTINCT ad.id_pedido), 0), 2) AS promedio_descuento_por_pedido
FROM usuarios u
LEFT JOIN auditoria_descuentos ad ON u.id_usuario = ad.id_usuario
WHERE u.codigo_descuento_registrado = 'FELICES50'
GROUP BY u.id_usuario, u.nombre, u.email, u.descuento_permanente
ORDER BY total_descuentos_recibidos DESC;

-- ============================================
-- PROCEDIMIENTOS PARA INSERTAR REGISTROS CON BENEFICIOS
-- ============================================

-- 15. SCRIPT PARA REGISTRAR NUEVO USUARIO MAYOR DE 50 AÑOS
-- Ejecutar con los parámetros específicos:
-- INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, descuento_permanente, activo)
-- VALUES (seq_usuarios.NEXTVAL, '[nombre]', '[email]', '[telefono]', '[hash_password]', '[direccion]', '[ciudad]', '[codigo_postal]', TO_DATE('[YYYY-MM-DD]', 'YYYY-MM-DD'), 0, 50.00, 1);

-- 16. SCRIPT PARA REGISTRAR NUEVO USUARIO CON CÓDIGO FELICES50
-- INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, codigo_descuento_registrado, descuento_permanente, activo)
-- VALUES (seq_usuarios.NEXTVAL, '[nombre]', '[email]', '[telefono]', '[hash_password]', '[direccion]', '[ciudad]', '[codigo_postal]', TO_DATE('[YYYY-MM-DD]', 'YYYY-MM-DD'), 0, 'FELICES50', 10.00, 1);
-- UPDATE codigos_descuento SET usos_actuales = usos_actuales + 1 WHERE codigo = 'FELICES50';

-- 17. SCRIPT PARA REGISTRAR ESTUDIANTE DUOC
-- INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, descuento_permanente, activo)
-- VALUES (seq_usuarios.NEXTVAL, '[nombre]', '[email]@duoc.cl', '[telefono]', '[hash_password]', '[direccion]', '[ciudad]', '[codigo_postal]', TO_DATE('[YYYY-MM-DD]', 'YYYY-MM-DD'), 1, 0.00, 1);
-- INSERT INTO cupones_estudiante_duoc (id_cupon, id_usuario, codigo_cupon, fecha_cumpleaños, torta_gratis, descuento_porcentaje, estado)
-- VALUES (seq_cupones_duoc.NEXTVAL, [id_usuario], 'DUOC-' || TO_CHAR(SYSDATE, 'YYYY') || '-' || TO_CHAR(TO_DATE('[cumpleaños_YYYY-MM-DD]', 'YYYY-MM-DD'), 'MM-DD') || '-001', TO_DATE('[cumpleaños_YYYY-MM-DD]', 'YYYY-MM-DD'), 1, 100.00, 'Activo');

COMMIT;
