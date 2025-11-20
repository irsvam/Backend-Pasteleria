-- ============================================
-- PROCEDIMIENTOS ALMACENADOS PARA SISTEMA DE DESCUENTOS
-- ============================================

-- PROCEDIMIENTO 1: Aplicar descuento a un pedido
CREATE OR REPLACE PROCEDURE sp_aplicar_descuento_pedido(
    p_id_pedido NUMBER,
    p_id_usuario NUMBER,
    p_monto_original DECIMAL,
    p_aplicar_descuento NUMBER DEFAULT 1
)
AS
    v_fecha_nac DATE;
    v_edad NUMBER;
    v_descuento_edad DECIMAL(5, 2);
    v_descuento_codigo DECIMAL(5, 2);
    v_descuento_cupon DECIMAL(5, 2);
    v_descuento_final DECIMAL(5, 2);
    v_monto_descuento DECIMAL(10, 2);
    v_monto_final DECIMAL(10, 2);
    v_razon VARCHAR2(500);
    v_tipo_descuento VARCHAR2(100);
BEGIN
    IF p_aplicar_descuento = 0 THEN
        RETURN;
    END IF;
    
    -- Obtener datos del usuario
    SELECT fecha_nacimiento INTO v_fecha_nac
    FROM usuarios
    WHERE id_usuario = p_id_usuario;
    
    -- Calcular edad
    v_edad := TRUNC((SYSDATE - v_fecha_nac) / 365.25);
    
    -- Determinar descuentos aplicables
    v_descuento_edad := CASE WHEN v_edad >= 50 THEN 50.00 ELSE 0.00 END;
    
    SELECT NVL(descuento_permanente, 0) INTO v_descuento_codigo
    FROM usuarios
    WHERE id_usuario = p_id_usuario;
    
    -- Verificar cupón Duoc
    SELECT COUNT(*) INTO v_descuento_cupon
    FROM cupones_estudiante_duoc
    WHERE id_usuario = p_id_usuario
      AND estado = 'Activo'
      AND SYSDATE >= fecha_cumpleaños - 7
      AND SYSDATE <= fecha_cumpleaños + 7;
    
    v_descuento_cupon := CASE WHEN v_descuento_cupon > 0 THEN 100.00 ELSE 0.00 END;
    
    -- Seleccionar el mayor descuento
    v_descuento_final := GREATEST(v_descuento_edad, v_descuento_codigo, v_descuento_cupon);
    
    -- Calcular montos
    v_monto_descuento := ROUND(p_monto_original * (v_descuento_final / 100), 2);
    v_monto_final := p_monto_original - v_monto_descuento;
    
    -- Determinar tipo de descuento
    IF v_descuento_final = v_descuento_edad THEN
        v_tipo_descuento := 'MAYORES_50_AÑOS';
        v_razon := 'Descuento 50% por mayor de 50 años (Nacimiento: ' || TO_CHAR(v_fecha_nac, 'YYYY-MM-DD') || ')';
    ELSIF v_descuento_final = v_descuento_cupon THEN
        v_tipo_descuento := 'CUPON_DUOC';
        v_razon := 'Torta gratis - Cupón de cumpleaños estudiante Duoc';
    ELSIF v_descuento_final = v_descuento_codigo THEN
        v_tipo_descuento := 'CODIGO_FELICES50';
        v_razon := 'Descuento permanente 10% por código FELICES50';
    ELSE
        v_tipo_descuento := 'SIN_DESCUENTO';
        v_razon := 'No aplica descuento';
    END IF;
    
    -- Registrar en auditoría
    INSERT INTO auditoria_descuentos (
        id_auditoria, id_usuario, id_pedido, tipo_descuento,
        porcentaje_aplicado, monto_original, monto_descuento,
        monto_final, razon, fecha_aplicacion
    ) VALUES (
        seq_auditoria_descuentos.NEXTVAL,
        p_id_usuario,
        p_id_pedido,
        v_tipo_descuento,
        v_descuento_final,
        p_monto_original,
        v_monto_descuento,
        v_monto_final,
        v_razon,
        SYSDATE
    );
    
    -- Actualizar pedido con monto final
    UPDATE pedidos
    SET total = v_monto_final
    WHERE id_pedido = p_id_pedido;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_aplicar_descuento_pedido;
/

-- PROCEDIMIENTO 2: Registrar usuario con código de descuento
CREATE OR REPLACE PROCEDURE sp_registrar_usuario_con_codigo(
    p_nombre VARCHAR2,
    p_email VARCHAR2,
    p_telefono VARCHAR2,
    p_contrasena VARCHAR2,
    p_direccion VARCHAR2,
    p_ciudad VARCHAR2,
    p_codigo_postal VARCHAR2,
    p_fecha_nacimiento DATE,
    p_codigo_descuento VARCHAR2,
    p_id_usuario_generado OUT NUMBER
)
AS
    v_descuento_disponible DECIMAL(5, 2);
    v_usos_disponibles NUMBER;
BEGIN
    -- Validar que el código exista y esté activo
    SELECT descuento_porcentaje, (maximo_usos - usos_actuales)
    INTO v_descuento_disponible, v_usos_disponibles
    FROM codigos_descuento
    WHERE codigo = p_codigo_descuento
      AND activo = 1
      AND SYSDATE BETWEEN fecha_inicio AND fecha_fin;
    
    IF v_usos_disponibles <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Código de descuento agotado');
    END IF;
    
    -- Insertar usuario
    INSERT INTO usuarios (
        id_usuario, nombre, email, telefono, contrasena,
        direccion, ciudad, codigo_postal, fecha_nacimiento,
        codigo_descuento_registrado, descuento_permanente, activo
    ) VALUES (
        seq_usuarios.NEXTVAL, p_nombre, p_email, p_telefono,
        p_contrasena, p_direccion, p_ciudad, p_codigo_postal,
        p_fecha_nacimiento, p_codigo_descuento,
        v_descuento_disponible, 1
    )
    RETURNING id_usuario INTO p_id_usuario_generado;
    
    -- Actualizar contador de uso
    UPDATE codigos_descuento
    SET usos_actuales = usos_actuales + 1
    WHERE codigo = p_codigo_descuento;
    
    -- Crear carrito automático
    INSERT INTO carrito_compras (
        id_carrito, id_usuario, fecha_creacion, ultima_actualizacion
    ) VALUES (
        seq_carrito.NEXTVAL, p_id_usuario_generado, SYSDATE, SYSDATE
    );
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Código de descuento no válido o expirado');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_registrar_usuario_con_codigo;
/

-- PROCEDIMIENTO 3: Registrar estudiante Duoc
CREATE OR REPLACE PROCEDURE sp_registrar_estudiante_duoc(
    p_nombre VARCHAR2,
    p_email VARCHAR2,
    p_telefono VARCHAR2,
    p_contrasena VARCHAR2,
    p_direccion VARCHAR2,
    p_ciudad VARCHAR2,
    p_codigo_postal VARCHAR2,
    p_fecha_nacimiento DATE,
    p_fecha_cumpleaños DATE,
    p_id_usuario_generado OUT NUMBER
)
AS
    v_id_usuario NUMBER;
BEGIN
    -- Validar que el email sea @duoc.cl
    IF NOT p_email LIKE '%@duoc.cl' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Email debe ser del dominio @duoc.cl');
    END IF;
    
    -- Insertar usuario
    INSERT INTO usuarios (
        id_usuario, nombre, email, telefono, contrasena,
        direccion, ciudad, codigo_postal, fecha_nacimiento,
        es_duoc_student, descuento_permanente, activo
    ) VALUES (
        seq_usuarios.NEXTVAL, p_nombre, p_email, p_telefono,
        p_contrasena, p_direccion, p_ciudad, p_codigo_postal,
        p_fecha_nacimiento, 1, 0.00, 1
    )
    RETURNING id_usuario INTO v_id_usuario;
    
    p_id_usuario_generado := v_id_usuario;
    
    -- Crear cupón de cumpleaños
    INSERT INTO cupones_estudiante_duoc (
        id_cupon, id_usuario, codigo_cupon, fecha_cumpleaños,
        torta_gratis, descuento_porcentaje, estado
    ) VALUES (
        seq_cupones_duoc.NEXTVAL,
        v_id_usuario,
        'DUOC-' || TO_CHAR(p_fecha_cumpleaños, 'YYYY-MM-DD') || '-' || 
        LPAD(v_id_usuario, 3, '0'),
        p_fecha_cumpleaños,
        1,
        100.00,
        'Activo'
    );
    
    -- Crear carrito automático
    INSERT INTO carrito_compras (
        id_carrito, id_usuario, fecha_creacion, ultima_actualizacion
    ) VALUES (
        seq_carrito.NEXTVAL, v_id_usuario, SYSDATE, SYSDATE
    );
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_registrar_estudiante_duoc;
/

-- PROCEDIMIENTO 4: Usar cupón Duoc
CREATE OR REPLACE PROCEDURE sp_usar_cupon_duoc(
    p_id_usuario NUMBER,
    p_id_pedido NUMBER
)
AS
    v_id_cupon NUMBER;
BEGIN
    -- Obtener cupón activo
    SELECT id_cupon INTO v_id_cupon
    FROM cupones_estudiante_duoc
    WHERE id_usuario = p_id_usuario
      AND estado = 'Activo'
      AND SYSDATE >= fecha_cumpleaños - 7
      AND SYSDATE <= fecha_cumpleaños + 7;
    
    -- Marcar cupón como usado
    UPDATE cupones_estudiante_duoc
    SET estado = 'Usado', fecha_uso = SYSDATE
    WHERE id_cupon = v_id_cupon;
    
    -- Registrar en auditoría
    INSERT INTO auditoria_descuentos (
        id_auditoria, id_usuario, id_pedido, tipo_descuento,
        porcentaje_aplicado, razon, fecha_aplicacion
    ) VALUES (
        seq_auditoria_descuentos.NEXTVAL,
        p_id_usuario,
        p_id_pedido,
        'CUPON_DUOC',
        100.00,
        'Torta gratis - Cupón de cumpleaños usado',
        SYSDATE
    );
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004, 'No hay cupón disponible');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sp_usar_cupon_duoc;
/

-- PROCEDIMIENTO 5: Obtener información de descuentos para un usuario
CREATE OR REPLACE FUNCTION fn_obtener_info_descuentos(p_id_usuario NUMBER)
RETURN VARCHAR2
IS
    v_info VARCHAR2(4000);
    v_edad NUMBER;
    v_fecha_nac DATE;
    v_es_duoc NUMBER;
    v_codigo VARCHAR2(50);
    v_descuento DECIMAL(5, 2);
    v_tiene_cupon NUMBER;
BEGIN
    SELECT u.fecha_nacimiento, u.es_duoc_student, u.codigo_descuento_registrado,
           u.descuento_permanente
    INTO v_fecha_nac, v_es_duoc, v_codigo, v_descuento
    FROM usuarios u
    WHERE u.id_usuario = p_id_usuario;
    
    v_edad := TRUNC((SYSDATE - v_fecha_nac) / 365.25);
    
    SELECT COUNT(*) INTO v_tiene_cupon
    FROM cupones_estudiante_duoc
    WHERE id_usuario = p_id_usuario
      AND estado = 'Activo'
      AND SYSDATE >= fecha_cumpleaños - 7
      AND SYSDATE <= fecha_cumpleaños + 7;
    
    v_info := 'Edad: ' || v_edad || ' años | ';
    
    IF v_edad >= 50 THEN
        v_info := v_info || 'Descuento 50% (Mayor edad) | ';
    END IF;
    
    IF v_codigo IS NOT NULL THEN
        v_info := v_info || 'Descuento ' || v_descuento || '% (Código: ' || v_codigo || ') | ';
    END IF;
    
    IF v_tiene_cupon > 0 THEN
        v_info := v_info || '¡CUPÓN ACTIVO! Torta Gratis por Cumpleaños (Duoc)';
    END IF;
    
    RETURN v_info;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Usuario no encontrado';
    WHEN OTHERS THEN
        RETURN 'Error al obtener información de descuentos';
END fn_obtener_info_descuentos;
/

-- EJEMPLOS DE USO
-- ============================================

-- Ejemplo 1: Aplicar descuento a un pedido existente
-- BEGIN
--     sp_aplicar_descuento_pedido(
--         p_id_pedido => 1,
--         p_id_usuario => 1,
--         p_monto_original => 105000.00,
--         p_aplicar_descuento => 1
--     );
-- END;
-- /

-- Ejemplo 2: Registrar usuario con código FELICES50
-- DECLARE
--     v_nuevo_id NUMBER;
-- BEGIN
--     sp_registrar_usuario_con_codigo(
--         p_nombre => 'Nueva Persona',
--         p_email => 'nueva@example.com',
--         p_telefono => '1234567890',
--         p_contrasena => 'hash_password',
--         p_direccion => 'Calle 123',
--         p_ciudad => 'Santiago',
--         p_codigo_postal => '8320000',
--         p_fecha_nacimiento => TO_DATE('1995-05-15', 'YYYY-MM-DD'),
--         p_codigo_descuento => 'FELICES50',
--         p_id_usuario_generado => v_nuevo_id
--     );
--     DBMS_OUTPUT.PUT_LINE('Usuario creado con ID: ' || v_nuevo_id);
-- END;
-- /

-- Ejemplo 3: Registrar estudiante Duoc
-- DECLARE
--     v_nuevo_id NUMBER;
-- BEGIN
--     sp_registrar_estudiante_duoc(
--         p_nombre => 'Nuevo Estudiante',
--         p_email => 'nuevo.estudiante@duoc.cl',
--         p_telefono => '9876543210',
--         p_contrasena => 'hash_password',
--         p_direccion => 'Avenida Duoc',
--         p_ciudad => 'Santiago',
--         p_codigo_postal => '8320000',
--         p_fecha_nacimiento => TO_DATE('2004-03-10', 'YYYY-MM-DD'),
--         p_fecha_cumpleaños => TO_DATE('2025-12-25', 'YYYY-MM-DD'),
--         p_id_usuario_generado => v_nuevo_id
--     );
--     DBMS_OUTPUT.PUT_LINE('Estudiante Duoc registrado con ID: ' || v_nuevo_id);
-- END;
-- /

-- Ejemplo 4: Obtener información de descuentos
-- SELECT fn_obtener_info_descuentos(1) FROM DUAL;

COMMIT;
