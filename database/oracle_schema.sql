-- ============================================
-- SCHEMA PARA PASTELERÍA - ORACLE DATABASE
-- ============================================

-- Crear tabla de Usuarios/Clientes
CREATE TABLE usuarios (
    id_usuario NUMBER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    telefono VARCHAR2(20),
    contrasena VARCHAR2(255) NOT NULL,
    direccion VARCHAR2(255),
    ciudad VARCHAR2(50),
    codigo_postal VARCHAR2(10),
    fecha_nacimiento DATE,
    es_duoc_student NUMBER(1) DEFAULT 0,
    codigo_descuento_registrado VARCHAR2(50),
    descuento_permanente DECIMAL(5, 2) DEFAULT 0.00,
    fecha_registro DATE DEFAULT SYSDATE,
    activo NUMBER(1) DEFAULT 1
);

-- Crear tabla de Categorías
CREATE TABLE categorias (
    id_categoria NUMBER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL UNIQUE,
    descripcion VARCHAR2(500),
    imagen_url VARCHAR2(255),
    activa NUMBER(1) DEFAULT 1
);

-- Crear tabla de Productos
CREATE TABLE productos (
    id_producto NUMBER PRIMARY KEY,
    nombre VARCHAR2(150) NOT NULL,
    descripcion VARCHAR2(500),
    precio DECIMAL(10, 2) NOT NULL,
    id_categoria NUMBER NOT NULL,
    imagen_url VARCHAR2(255),
    stock NUMBER(5) DEFAULT 0,
    fecha_creacion DATE DEFAULT SYSDATE,
    activo NUMBER(1) DEFAULT 1,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

-- Crear tabla de Promociones
CREATE TABLE promociones (
    id_promocion NUMBER PRIMARY KEY,
    nombre VARCHAR2(150) NOT NULL,
    descripcion VARCHAR2(500),
    descuento_porcentaje DECIMAL(5, 2),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activa NUMBER(1) DEFAULT 1
);

-- Crear tabla de Productos en Promoción
CREATE TABLE productos_promociones (
    id_producto NUMBER NOT NULL,
    id_promocion NUMBER NOT NULL,
    PRIMARY KEY (id_producto, id_promocion),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_promocion) REFERENCES promociones(id_promocion)
);

-- Crear tabla de Pedidos
CREATE TABLE pedidos (
    id_pedido NUMBER PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    fecha_pedido DATE DEFAULT SYSDATE,
    estado VARCHAR2(50) DEFAULT 'Pendiente',
    total DECIMAL(10, 2),
    direccion_entrega VARCHAR2(255),
    fecha_entrega DATE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Crear tabla de Detalles del Pedido
CREATE TABLE detalles_pedido (
    id_detalle NUMBER PRIMARY KEY,
    id_pedido NUMBER NOT NULL,
    id_producto NUMBER NOT NULL,
    cantidad NUMBER(5) NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(10, 2),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- Crear tabla de Carrito de Compras
CREATE TABLE carrito_compras (
    id_carrito NUMBER PRIMARY KEY,
    id_usuario NUMBER NOT NULL UNIQUE,
    fecha_creacion DATE DEFAULT SYSDATE,
    ultima_actualizacion DATE DEFAULT SYSDATE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Crear tabla de Items del Carrito
CREATE TABLE items_carrito (
    id_item NUMBER PRIMARY KEY,
    id_carrito NUMBER NOT NULL,
    id_producto NUMBER NOT NULL,
    cantidad NUMBER(5) NOT NULL,
    fecha_agregado DATE DEFAULT SYSDATE,
    FOREIGN KEY (id_carrito) REFERENCES carrito_compras(id_carrito),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- Crear tabla de Envíos
CREATE TABLE envios (
    id_envio NUMBER PRIMARY KEY,
    id_pedido NUMBER NOT NULL,
    numero_seguimiento VARCHAR2(100) UNIQUE,
    estado_envio VARCHAR2(50) DEFAULT 'Procesando',
    fecha_envio DATE,
    fecha_entrega_estimada DATE,
    fecha_entrega_real DATE,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

-- Crear tabla de Reseñas/Comentarios
CREATE TABLE resenas (
    id_resena NUMBER PRIMARY KEY,
    id_producto NUMBER NOT NULL,
    id_usuario NUMBER NOT NULL,
    calificacion NUMBER(1) CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario VARCHAR2(1000),
    fecha_resena DATE DEFAULT SYSDATE,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Crear tabla de Códigos de Descuento Especiales
CREATE TABLE codigos_descuento (
    id_codigo NUMBER PRIMARY KEY,
    codigo VARCHAR2(50) UNIQUE NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    descripcion VARCHAR2(500),
    tipo_descuento VARCHAR2(50),
    descuento_porcentaje DECIMAL(5, 2),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    maximo_usos NUMBER,
    usos_actuales NUMBER DEFAULT 0,
    activo NUMBER(1) DEFAULT 1
);

-- Crear tabla de Cupones de Cumpleaños para Estudiantes Duoc
CREATE TABLE cupones_estudiante_duoc (
    id_cupon NUMBER PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    codigo_cupon VARCHAR2(100) UNIQUE NOT NULL,
    fecha_cumpleaños DATE NOT NULL,
    torta_gratis NUMBER(1) DEFAULT 1,
    descuento_porcentaje DECIMAL(5, 2) DEFAULT 100.00,
    estado VARCHAR2(50) DEFAULT 'Activo',
    fecha_creacion DATE DEFAULT SYSDATE,
    fecha_uso DATE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Crear tabla de Auditoría de Descuentos Aplicados
CREATE TABLE auditoria_descuentos (
    id_auditoria NUMBER PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    id_pedido NUMBER,
    tipo_descuento VARCHAR2(100),
    porcentaje_aplicado DECIMAL(5, 2),
    monto_original DECIMAL(10, 2),
    monto_descuento DECIMAL(10, 2),
    monto_final DECIMAL(10, 2),
    razon VARCHAR2(500),
    fecha_aplicacion DATE DEFAULT SYSDATE,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

-- Crear SEQUENCES para auto-incremento
CREATE SEQUENCE seq_usuarios START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_categorias START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_productos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_promociones START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_pedidos START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_detalles_pedido START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_carrito START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_items_carrito START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_envios START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_resenas START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_codigos_descuento START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_cupones_duoc START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_auditoria_descuentos START WITH 1 INCREMENT BY 1;

-- ============================================
-- ÍNDICES PARA OPTIMIZAR CONSULTAS
-- ============================================

CREATE INDEX idx_email_usuarios ON usuarios(email);
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_pedidos_usuario ON pedidos(id_usuario);
CREATE INDEX idx_detalles_pedido ON detalles_pedido(id_pedido);
CREATE INDEX idx_carrito_usuario ON carrito_compras(id_usuario);
CREATE INDEX idx_envios_pedido ON envios(id_pedido);
CREATE INDEX idx_resenas_producto ON resenas(id_producto);
CREATE INDEX idx_codigos_descuento ON codigos_descuento(codigo);
CREATE INDEX idx_cupones_duoc_usuario ON cupones_estudiante_duoc(id_usuario);
CREATE INDEX idx_cupones_duoc_estado ON cupones_estudiante_duoc(estado);
CREATE INDEX idx_auditoria_usuario ON auditoria_descuentos(id_usuario);
CREATE INDEX idx_auditoria_pedido ON auditoria_descuentos(id_pedido);
CREATE INDEX idx_usuarios_edad ON usuarios(fecha_nacimiento);
CREATE INDEX idx_usuarios_duoc ON usuarios(es_duoc_student);

-- ============================================
-- DATOS DE PRUEBA (COMPLETO)
-- ============================================

-- ============================================
-- 1. INSERTAR CATEGORÍAS
-- ============================================
INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Tortas Cuadradas', 'Tortas cuadradas personalizables con diseños especiales', '/img/products/tortas_cuadradas.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Tortas Circulares', 'Tortas circulares clásicas para todas las ocasiones', '/img/products/tortas_circulares.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Postres Individuales', 'Deliciosos postres individuales para disfrutar solo', '/img/products/postres_individuales.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Productos Sin Azúcar', 'Opciones saludables sin azúcar refinada', '/img/products/sin_azucar.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Pastelería Tradicional', 'Recetas clásicas y tradicionales de la pastelería', '/img/products/pasteleria_tradicional.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Productos Sin Gluten', 'Productos seguros para celíacos sin gluten', '/img/products/sin_gluten.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Productos Veganos', 'Deliciosos productos hechos sin ingredientes de origen animal', '/img/products/veganos.jpg', 1);

INSERT INTO categorias (id_categoria, nombre, descripcion, imagen_url, activa) 
VALUES (seq_categorias.NEXTVAL, 'Tortas Especiales', 'Tortas diseñadas para momentos especiales y celebraciones', '/img/products/tortas_especiales.jpg', 1);

-- ============================================
-- 2. INSERTAR PRODUCTOS
-- ============================================
-- Tortas Cuadradas
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Cuadrada de Chocolate', 'Deliciosa torta de chocolate con capas de ganache y un toque de avellanas. Personalizable con mensajes especiales', 45000.00, 1, '/img/products/torta_cuadrada_chocolate.jpg', 15, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Cuadrada de Frutas', 'Una mezcla de frutas frescas y crema chantilly sobre un suave bizcocho de vainilla, ideal para celebraciones', 50000.00, 1, '/img/products/torta_cuadrada_frutas.jpg', 12, 1);

-- Tortas Circulares
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Circular de Vainilla', 'Bizcocho de vainilla clásico relleno con crema pastelera y cubierto con un glaseado dulce, perfecto para cualquier ocasión', 40000.00, 2, '/img/products/torta_circular_vainilla.jpg', 18, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Circular de Manjar', 'Torta tradicional chilena con manjar y nueces, un deleite para los amantes de los sabores dulces y clásicos', 42000.00, 2, '/img/products/torta_circular_manjar.jpg', 14, 1);

-- Postres Individuales
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Mousse de Chocolate', 'Postre individual cremoso y suave, hecho con chocolate de alta calidad, ideal para los amantes del chocolate', 5000.00, 3, '/img/products/mousse_chocolate.jpg', 30, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Tiramisú Clásico', 'Un postre italiano individual con capas de café, mascarpone y cacao, perfecto para finalizar cualquier comida', 5500.00, 3, '/img/products/tiramisu_clasico.jpg', 28, 1);

-- Productos Sin Azúcar
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Sin Azúcar de Naranja', 'Torta ligera y deliciosa, endulzada naturalmente, ideal para quienes buscan opciones más saludables', 48000.00, 4, '/img/products/torta_sin_azucar_naranja.jpg', 10, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Cheesecake Sin Azúcar', 'Suave y cremoso, este cheesecake es una opción perfecta para disfrutar sin culpa', 47000.00, 4, '/img/products/cheesecake_sin_azucar.jpg', 12, 1);

-- Pastelería Tradicional
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Empanada de Manzana', 'Pastelería tradicional rellena de manzanas especiadas, perfecta para un dulce desayuno o merienda', 3000.00, 5, '/img/products/empanada_manzana.jpg', 40, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Tarta de Santiago', 'Tradicional tarta española hecha con almendras, azúcar, y huevos, una delicia para los amantes de los postres clásicos', 6000.00, 5, '/img/products/tarta_santiago.jpg', 22, 1);

-- Productos Sin Gluten
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Brownie Sin Gluten', 'Rico y denso, este brownie es perfecto para quienes necesitan evitar el gluten sin sacrificar el sabor', 4000.00, 6, '/img/products/brownie_sin_gluten.jpg', 25, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Pan Sin Gluten', 'Suave y esponjoso, ideal para sándwiches o para acompañar cualquier comida', 3500.00, 6, '/img/products/pan_sin_gluten.jpg', 20, 1);

-- Productos Veganos
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Vegana de Chocolate', 'Torta de chocolate húmeda y deliciosa, hecha sin productos de origen animal, perfecta para veganos', 50000.00, 7, '/img/products/torta_vegana_chocolate.jpg', 16, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Galletas Veganas de Avena', 'Crujientes y sabrosas, estas galletas son una excelente opción para un snack saludable y vegano', 4500.00, 7, '/img/products/galletas_veganas_avena.jpg', 35, 1);

-- Tortas Especiales
INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Especial de Cumpleaños', 'Diseñada especialmente para celebraciones, personalizable con decoraciones y mensajes únicos', 55000.00, 8, '/img/products/torta_cumpleaños.jpg', 8, 1);

INSERT INTO productos (id_producto, nombre, descripcion, precio, id_categoria, imagen_url, stock, activo) 
VALUES (seq_productos.NEXTVAL, 'Torta Especial de Boda', 'Elegante y deliciosa, esta torta está diseñada para ser el centro de atención en cualquier boda', 60000.00, 8, '/img/products/torta_boda.jpg', 6, 1);

-- ============================================
-- 3. INSERTAR USUARIOS
-- ============================================
INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, codigo_descuento_registrado, descuento_permanente, activo) 
VALUES (seq_usuarios.NEXTVAL, 'Juan Pérez', 'juan@example.com', '123456789', 'hash_password_1', 'Calle Principal 123', 'Madrid', '28001', TO_DATE('1970-05-15', 'YYYY-MM-DD'), 0, NULL, 50.00, 1);

INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, codigo_descuento_registrado, descuento_permanente, activo) 
VALUES (seq_usuarios.NEXTVAL, 'María García', 'maria@duoc.cl', '987654321', 'hash_password_2', 'Avenida Central 456', 'Barcelona', '08002', TO_DATE('2003-11-22', 'YYYY-MM-DD'), 1, 'FELICES50', 10.00, 1);

INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, codigo_descuento_registrado, descuento_permanente, activo) 
VALUES (seq_usuarios.NEXTVAL, 'Carlos López', 'carlos@example.com', '555111222', 'hash_password_3', 'Plaza Mayor 789', 'Valencia', '46001', TO_DATE('1972-03-10', 'YYYY-MM-DD'), 0, NULL, 50.00, 1);

INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, codigo_descuento_registrado, descuento_permanente, activo) 
VALUES (seq_usuarios.NEXTVAL, 'Ana Rodríguez', 'ana.rodriguez@duoc.cl', '666333444', 'hash_password_4', 'Calle Menor 321', 'Sevilla', '41001', TO_DATE('2002-07-18', 'YYYY-MM-DD'), 1, NULL, 0.00, 1);

INSERT INTO usuarios (id_usuario, nombre, email, telefono, contrasena, direccion, ciudad, codigo_postal, fecha_nacimiento, es_duoc_student, codigo_descuento_registrado, descuento_permanente, activo) 
VALUES (seq_usuarios.NEXTVAL, 'Luis Martínez', 'luis@example.com', '777888999', 'hash_password_5', 'Paseo del Prado 654', 'Madrid', '28014', TO_DATE('1968-12-25', 'YYYY-MM-DD'), 0, 'FELICES50', 10.00, 1);

-- ============================================
-- 4. INSERTAR PROMOCIONES
-- ============================================
INSERT INTO promociones (id_promocion, nombre, descripcion, descuento_porcentaje, fecha_inicio, fecha_fin, activa) 
VALUES (seq_promociones.NEXTVAL, 'Descuento Navidad', 'Descuento especial para la temporada navideña', 20.00, TO_DATE('2025-12-01', 'YYYY-MM-DD'), TO_DATE('2025-12-31', 'YYYY-MM-DD'), 1);

INSERT INTO promociones (id_promocion, nombre, descripcion, descuento_porcentaje, fecha_inicio, fecha_fin, activa) 
VALUES (seq_promociones.NEXTVAL, 'Black Friday', 'Descuento especial Black Friday', 30.00, TO_DATE('2025-11-28', 'YYYY-MM-DD'), TO_DATE('2025-12-02', 'YYYY-MM-DD'), 1);

INSERT INTO promociones (id_promocion, nombre, descripcion, descuento_porcentaje, fecha_inicio, fecha_fin, activa) 
VALUES (seq_promociones.NEXTVAL, 'Aniversario', 'Celebra nuestro aniversario con descuentos', 15.00, TO_DATE('2025-11-15', 'YYYY-MM-DD'), TO_DATE('2025-11-30', 'YYYY-MM-DD'), 1);

INSERT INTO promociones (id_promocion, nombre, descripcion, descuento_porcentaje, fecha_inicio, fecha_fin, activa) 
VALUES (seq_promociones.NEXTVAL, 'Verano', 'Descuentos de verano en productos seleccionados', 10.00, TO_DATE('2025-06-01', 'YYYY-MM-DD'), TO_DATE('2025-08-31', 'YYYY-MM-DD'), 1);

-- ============================================
-- 5. INSERTAR PRODUCTOS EN PROMOCIÓN
-- ============================================
INSERT INTO productos_promociones (id_producto, id_promocion) 
SELECT p.id_producto, pr.id_promocion 
FROM productos p, promociones pr 
WHERE p.nombre = 'Torta Cuadrada de Chocolate' AND pr.nombre = 'Descuento Navidad';

INSERT INTO productos_promociones (id_producto, id_promocion) 
SELECT p.id_producto, pr.id_promocion 
FROM productos p, promociones pr 
WHERE p.nombre = 'Torta Circular de Vainilla' AND pr.nombre = 'Descuento Navidad';

INSERT INTO productos_promociones (id_producto, id_promocion) 
SELECT p.id_producto, pr.id_promocion 
FROM productos p, promociones pr 
WHERE p.nombre = 'Galletas Veganas de Avena' AND pr.nombre = 'Black Friday';

INSERT INTO productos_promociones (id_producto, id_promocion) 
SELECT p.id_producto, pr.id_promocion 
FROM productos p, promociones pr 
WHERE p.nombre = 'Brownie Sin Gluten' AND pr.nombre = 'Aniversario';

-- ============================================
-- 6. INSERTAR CARRITOS DE COMPRAS
-- ============================================
INSERT INTO carrito_compras (id_carrito, id_usuario, fecha_creacion, ultima_actualizacion) 
VALUES (seq_carrito.NEXTVAL, 1, SYSDATE, SYSDATE);

INSERT INTO carrito_compras (id_carrito, id_usuario, fecha_creacion, ultima_actualizacion) 
VALUES (seq_carrito.NEXTVAL, 2, SYSDATE, SYSDATE);

INSERT INTO carrito_compras (id_carrito, id_usuario, fecha_creacion, ultima_actualizacion) 
VALUES (seq_carrito.NEXTVAL, 3, SYSDATE, SYSDATE);

INSERT INTO carrito_compras (id_carrito, id_usuario, fecha_creacion, ultima_actualizacion) 
VALUES (seq_carrito.NEXTVAL, 4, SYSDATE, SYSDATE);

INSERT INTO carrito_compras (id_carrito, id_usuario, fecha_creacion, ultima_actualizacion) 
VALUES (seq_carrito.NEXTVAL, 5, SYSDATE, SYSDATE);

-- ============================================
-- 7. INSERTAR ITEMS EN CARRITO
-- ============================================
INSERT INTO items_carrito (id_item, id_carrito, id_producto, cantidad, fecha_agregado) 
VALUES (seq_items_carrito.NEXTVAL, 1, 1, 1, SYSDATE);

INSERT INTO items_carrito (id_item, id_carrito, id_producto, cantidad, fecha_agregado) 
VALUES (seq_items_carrito.NEXTVAL, 1, 5, 2, SYSDATE);

INSERT INTO items_carrito (id_item, id_carrito, id_producto, cantidad, fecha_agregado) 
VALUES (seq_items_carrito.NEXTVAL, 2, 3, 1, SYSDATE);

INSERT INTO items_carrito (id_item, id_carrito, id_producto, cantidad, fecha_agregado) 
VALUES (seq_items_carrito.NEXTVAL, 3, 9, 3, SYSDATE);

INSERT INTO items_carrito (id_item, id_carrito, id_producto, cantidad, fecha_agregado) 
VALUES (seq_items_carrito.NEXTVAL, 4, 2, 1, SYSDATE);

-- ============================================
-- 8. INSERTAR PEDIDOS
-- ============================================
INSERT INTO pedidos (id_pedido, id_usuario, fecha_pedido, estado, total, direccion_entrega) 
VALUES (seq_pedidos.NEXTVAL, 1, SYSDATE - 10, 'Entregado', 105000.00, 'Calle Principal 123, Madrid');

INSERT INTO pedidos (id_pedido, id_usuario, fecha_pedido, estado, total, direccion_entrega) 
VALUES (seq_pedidos.NEXTVAL, 2, SYSDATE - 5, 'En Proceso', 38000.00, 'Avenida Central 456, Barcelona');

INSERT INTO pedidos (id_pedido, id_usuario, fecha_pedido, estado, total, direccion_entrega) 
VALUES (seq_pedidos.NEXTVAL, 3, SYSDATE - 2, 'Pendiente', 45000.00, 'Plaza Mayor 789, Valencia');

INSERT INTO pedidos (id_pedido, id_usuario, fecha_pedido, estado, total, direccion_entrega) 
VALUES (seq_pedidos.NEXTVAL, 4, SYSDATE - 1, 'En Proceso', 50000.00, 'Calle Menor 321, Sevilla');

INSERT INTO pedidos (id_pedido, id_usuario, fecha_pedido, estado, total, direccion_entrega) 
VALUES (seq_pedidos.NEXTVAL, 5, SYSDATE, 'Pendiente', 115000.00, 'Paseo del Prado 654, Madrid');

-- ============================================
-- 9. INSERTAR DETALLES DE PEDIDOS
-- ============================================
INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 1, 1, 1, 45000.00, 45000.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 1, 5, 2, 30000.00, 60000.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 2, 3, 1, 40000.00, 40000.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 2, 6, 1, 5500.00, 5500.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 3, 2, 1, 50000.00, 50000.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 4, 9, 2, 25000.00, 50000.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 5, 11, 1, 48000.00, 48000.00);

INSERT INTO detalles_pedido (id_detalle, id_pedido, id_producto, cantidad, precio_unitario, subtotal) 
VALUES (seq_detalles_pedido.NEXTVAL, 5, 14, 1, 50000.00, 50000.00);

-- ============================================
-- 10. INSERTAR ENVÍOS
-- ============================================
INSERT INTO envios (id_envio, id_pedido, numero_seguimiento, estado_envio, fecha_envio, fecha_entrega_estimada, fecha_entrega_real) 
VALUES (seq_envios.NEXTVAL, 1, 'TRACK001', 'Entregado', SYSDATE - 10, SYSDATE - 7, SYSDATE - 5);

INSERT INTO envios (id_envio, id_pedido, numero_seguimiento, estado_envio, fecha_envio, fecha_entrega_estimada) 
VALUES (seq_envios.NEXTVAL, 2, 'TRACK002', 'En Tránsito', SYSDATE - 3, SYSDATE + 2);

INSERT INTO envios (id_envio, id_pedido, numero_seguimiento, estado_envio, fecha_envio, fecha_entrega_estimada) 
VALUES (seq_envios.NEXTVAL, 3, 'TRACK003', 'Procesando', SYSDATE, SYSDATE + 5);

INSERT INTO envios (id_envio, id_pedido, numero_seguimiento, estado_envio, fecha_envio, fecha_entrega_estimada) 
VALUES (seq_envios.NEXTVAL, 4, 'TRACK004', 'En Tránsito', SYSDATE - 1, SYSDATE + 3);

INSERT INTO envios (id_envio, id_pedido, numero_seguimiento, estado_envio, fecha_envio, fecha_entrega_estimada) 
VALUES (seq_envios.NEXTVAL, 5, 'TRACK005', 'Procesando', SYSDATE, SYSDATE + 4);

-- ============================================
-- 11. INSERTAR RESEÑAS
-- ============================================
INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 1, 1, 5, 'Excelente Torta Cuadrada de Chocolate, personalización perfecta!', SYSDATE - 8);

INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 5, 1, 4, 'Mousse muy cremoso y delicioso, presentación impecable', SYSDATE - 7);

INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 2, 2, 5, 'Torta Cuadrada de Frutas, frutas muy frescas y sabrosa!', SYSDATE - 5);

INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 3, 2, 4, 'Torta Circular de Vainilla excelente, crema pastelera muy buena', SYSDATE - 4);

INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 14, 3, 5, 'Galletas Veganas de Avena, no creía que fueran tan sabrosas!', SYSDATE - 3);

INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 11, 4, 4, 'Brownie Sin Gluten muy bueno, sin sacrificar sabor', SYSDATE - 2);

INSERT INTO resenas (id_resena, id_producto, id_usuario, calificacion, comentario, fecha_resena) 
VALUES (seq_resenas.NEXTVAL, 16, 5, 5, 'Torta Especial de Boda simplemente perfecta, decoraciones hermosas!', SYSDATE - 1);

-- ============================================
-- 12. INSERTAR CÓDIGOS DE DESCUENTO ESPECIALES
-- ============================================
INSERT INTO codigos_descuento (id_codigo, codigo, nombre, descripcion, tipo_descuento, descuento_porcentaje, fecha_inicio, fecha_fin, maximo_usos, usos_actuales, activo) 
VALUES (seq_codigos_descuento.NEXTVAL, 'FELICES50', 'Código Felices 50', 'Descuento de por vida del 10% para usuarios que se registran con este código', 'DESCUENTO_PERMANENTE', 10.00, TO_DATE('2025-01-01', 'YYYY-MM-DD'), TO_DATE('2099-12-31', 'YYYY-MM-DD'), 999, 2, 1);

INSERT INTO codigos_descuento (id_codigo, codigo, nombre, descripcion, tipo_descuento, descuento_porcentaje, fecha_inicio, fecha_fin, maximo_usos, usos_actuales, activo) 
VALUES (seq_codigos_descuento.NEXTVAL, 'BIENVENIDA20', 'Bienvenida 20%', 'Código de bienvenida con 20% de descuento', 'BIENVENIDA', 20.00, TO_DATE('2025-01-01', 'YYYY-MM-DD'), TO_DATE('2025-12-31', 'YYYY-MM-DD'), 100, 5, 1);

INSERT INTO codigos_descuento (id_codigo, codigo, nombre, descripcion, tipo_descuento, descuento_porcentaje, fecha_inicio, fecha_fin, maximo_usos, usos_actuales, activo) 
VALUES (seq_codigos_descuento.NEXTVAL, 'REFERRAL15', 'Código Referral', 'Descuento por referencia de amigos', 'REFERRAL', 15.00, TO_DATE('2025-01-01', 'YYYY-MM-DD'), TO_DATE('2099-12-31', 'YYYY-MM-DD'), 999, 0, 1);

-- ============================================
-- 13. INSERTAR CUPONES DE CUMPLEAÑOS PARA ESTUDIANTES DUOC
-- ============================================
INSERT INTO cupones_estudiante_duoc (id_cupon, id_usuario, codigo_cupon, fecha_cumpleaños, torta_gratis, descuento_porcentaje, estado, fecha_creacion) 
VALUES (seq_cupones_duoc.NEXTVAL, 2, 'DUOC-2025-11-22-001', TO_DATE('2025-11-22', 'YYYY-MM-DD'), 1, 100.00, 'Activo', SYSDATE);

INSERT INTO cupones_estudiante_duoc (id_cupon, id_usuario, codigo_cupon, fecha_cumpleaños, torta_gratis, descuento_porcentaje, estado, fecha_creacion) 
VALUES (seq_cupones_duoc.NEXTVAL, 4, 'DUOC-2025-07-18-001', TO_DATE('2025-07-18', 'YYYY-MM-DD'), 1, 100.00, 'Activo', SYSDATE);

-- ============================================
-- 14. INSERTAR AUDITORÍA DE DESCUENTOS APLICADOS
-- ============================================
INSERT INTO auditoria_descuentos (id_auditoria, id_usuario, id_pedido, tipo_descuento, porcentaje_aplicado, monto_original, monto_descuento, monto_final, razon, fecha_aplicacion) 
VALUES (seq_auditoria_descuentos.NEXTVAL, 1, 1, 'MAYORES_50_AÑOS', 50.00, 105000.00, 52500.00, 52500.00, 'Descuento por mayor de 50 años (Nac: 1970-05-15)', SYSDATE - 10);

INSERT INTO auditoria_descuentos (id_auditoria, id_usuario, id_pedido, tipo_descuento, porcentaje_aplicado, monto_original, monto_descuento, monto_final, razon, fecha_aplicacion) 
VALUES (seq_auditoria_descuentos.NEXTVAL, 2, 2, 'CODIGO_FELICES50', 10.00, 38000.00, 3800.00, 34200.00, 'Descuento permanente por código FELICES50', SYSDATE - 5);

INSERT INTO auditoria_descuentos (id_auditoria, id_usuario, id_pedido, tipo_descuento, porcentaje_aplicado, monto_original, monto_descuento, monto_final, razon, fecha_aplicacion) 
VALUES (seq_auditoria_descuentos.NEXTVAL, 3, 3, 'MAYORES_50_AÑOS', 50.00, 45000.00, 22500.00, 22500.00, 'Descuento por mayor de 50 años (Nac: 1972-03-10)', SYSDATE - 2);

INSERT INTO auditoria_descuentos (id_auditoria, id_usuario, id_pedido, tipo_descuento, porcentaje_aplicado, monto_original, monto_descuento, monto_final, razon, fecha_aplicacion) 
VALUES (seq_auditoria_descuentos.NEXTVAL, 4, 4, 'SIN_DESCUENTO', 0.00, 50000.00, 0.00, 50000.00, 'Usuario estudiante Duoc sin aplicar descuento aún', SYSDATE - 1);

INSERT INTO auditoria_descuentos (id_auditoria, id_usuario, id_pedido, tipo_descuento, porcentaje_aplicado, monto_original, monto_descuento, monto_final, razon, fecha_aplicacion) 
VALUES (seq_auditoria_descuentos.NEXTVAL, 5, 5, 'COMBINADO', 60.00, 115000.00, 69000.00, 46000.00, 'Combinación: Mayor 50 años (50%) + Código FELICES50 (10%)', SYSDATE);

COMMIT;

-- ============================================
-- VISTAS ÚTILES PARA CONSULTAS
-- ============================================

-- Vista: Usuarios mayores de 50 años con derecho a descuento
CREATE VIEW v_usuarios_mayores_50 AS
SELECT 
    id_usuario,
    nombre,
    email,
    fecha_nacimiento,
    TRUNC((SYSDATE - fecha_nacimiento) / 365.25) AS edad,
    50.00 AS descuento_aplicable,
    'Mayor de 50 años' AS razon_descuento
FROM usuarios
WHERE TRUNC((SYSDATE - fecha_nacimiento) / 365.25) >= 50
  AND activo = 1;

-- Vista: Usuarios con descuento permanente por código FELICES50
CREATE VIEW v_usuarios_felices50 AS
SELECT 
    id_usuario,
    nombre,
    email,
    codigo_descuento_registrado,
    descuento_permanente,
    'Código FELICES50' AS tipo_descuento
FROM usuarios
WHERE codigo_descuento_registrado = 'FELICES50'
  AND descuento_permanente = 10.00
  AND activo = 1;

-- Vista: Estudiantes Duoc con cupones activos
CREATE VIEW v_estudiantes_duoc_cupones AS
SELECT 
    u.id_usuario,
    u.nombre,
    u.email,
    c.id_cupon,
    c.codigo_cupon,
    c.fecha_cumpleaños,
    c.torta_gratis,
    c.descuento_porcentaje,
    c.estado,
    c.fecha_creacion,
    TRUNC((c.fecha_cumpleaños - SYSDATE)) AS dias_para_cumpleaños
FROM usuarios u
INNER JOIN cupones_estudiante_duoc c ON u.id_usuario = c.id_usuario
WHERE u.es_duoc_student = 1
  AND u.activo = 1
  AND c.estado = 'Activo';

-- Vista: Resumen de descuentos aplicados por usuario
CREATE VIEW v_resumen_descuentos_usuario AS
SELECT 
    id_usuario,
    COUNT(*) AS total_descuentos_aplicados,
    SUM(monto_descuento) AS monto_total_descuentado,
    SUM(monto_original) AS monto_total_compras,
    ROUND(AVG(porcentaje_aplicado), 2) AS promedio_descuento
FROM auditoria_descuentos
GROUP BY id_usuario;
