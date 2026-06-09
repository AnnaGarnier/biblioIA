delimiter $$
CREATE TRIGGER trg_actualizar_stock_insert
AFTER INSERT ON prestamo
FOR EACH ROW
BEGIN
	IF NEW.estado = 'ACTIVO' THEN 
	  UPDATE libro 
	  SET stock_disponible = stock_disponible - 1
	  WHERE isbn = (SELECT isbn FROM ejemplar WHERE id_ejemplar = NEW.id_ejemplar);
	END IF;
END $$

CREATE TRIGGER trg_actualizar_stock_update
AFTER UPDATE ON prestamo
FOR EACH ROW
BEGIN
	IF OLD.estado = 'ACTIVO' AND NEW.estado = 'DEVUELTO' THEN
	  UPDATE LIBRO
	  SET stock_disponible = stock_disponible + 1
	  WHERE isbn = (SELECT isbn FROM ejemplar WHERE id_ejemplar = NEW.id_ejemplar);
	END IF;
END $$
delimiter ;

delimiter $$
CREATE TRIGGER trg_estado_socio
AFTER INSERT ON sancion
FOR EACH ROW
BEGIN
	UPDATE socio
	SET estado = 'SUSPENDIDO'
	WHERE id_socio = NEW.id_socio AND estado = 'ACTIVO';
END $$
delimiter ;

delimiter $$
CREATE TRIGGER trg_audit_prestamo_insert
AFTER INSERT ON prestamo
FOR EACH ROW
BEGIN
	INSERT INTO auditoria_prestamos (id_prestamo, operacion, estado_nuevo, estado_viejo, usuario_bd)
	VALUES (NEW.id_prestamo, 'INSERT', NEW.estado, NULL, USER());
END $$

CREATE TRIGGER trg_audit_prestamo_update
AFTER UPDATE ON prestamo
FOR EACH ROW
BEGIN
	INSERT INTO auditoria_prestamos (id_prestamo, operacion, estado_nuevo, estado_viejo, usuario_bd)
	VALUES (NEW.id_prestamo, 'UPDATE', NEW.estado, OLD.estado, USER());
END $$

CREATE TRIGGER trg_audit_prestamo_delete
AFTER DELETE ON prestamo
FOR EACH ROW
BEGIN
	INSERT INTO auditoria_prestamos (id_prestamo, operacion, estado_nuevo, estado_viejo, usuario_bd)
	VALUES (NEW.id_prestamo, 'DELETE', NULL , OLD.estado, USER());
END $$
delimiter;