CREATE OR REPLACE TRIGGER trg_actualizar_stock_detalle
AFTER INSERT OR UPDATE OR DELETE ON detalles_pedido
FOR EACH ROW
BEGIN
  -- 🟢 INSERT: baja stock del producto nuevo
  IF INSERTING THEN
    UPDATE productos
    SET stock = stock - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;
  END IF;

  -- 🟡 DELETE: devuelve stock del producto eliminado
  IF DELETING THEN
    UPDATE productos
    SET stock = stock + :OLD.cantidad
    WHERE id_producto = :OLD.id_producto;
  END IF;

  -- 🔵 UPDATE: puede cambiar cantidad y/o producto
  IF UPDATING THEN
    -- Si es el mismo producto, ajustamos por diferencia de cantidad
    IF :OLD.id_producto = :NEW.id_producto THEN
      UPDATE productos
      SET stock = stock + (:OLD.cantidad - :NEW.cantidad)
      WHERE id_producto = :NEW.id_producto;
    ELSE
      -- Si cambió el producto, devolvemos al viejo y descontamos del nuevo
      UPDATE productos
      SET stock = stock + :OLD.cantidad
      WHERE id_producto = :OLD.id_producto;

      UPDATE productos
      SET stock = stock - :NEW.cantidad
      WHERE id_producto = :NEW.id_producto;
    END IF;
  END IF;
END;
/
