DELIMITER $$
CREATE PROCEDURE sp_registrar_prestamo(IN idsocio INT, IN idejemplar INT)
BEGIN
    DECLARE estadosocio VARCHAR(20);
    DECLARE prestamosactivos INT;
    DECLARE estadoejemplar VARCHAR(20);
    DECLARE stockdisp INT;
    
    -- ACID: revertir transacción si algo falla (atomicity)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION -- captura cualquier error y hace rollback
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al registrar el préstamo. Transacción revertida.';
    END;

    -- 1. Validar estadosocio
    SELECT estado INTO estadosocio FROM SOCIO WHERE id_socio = idsocio;
    IF estadosocio = 'SUSPENDIDO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio está suspendido y no puede realizar préstamos.';
    END IF;

    -- 2. Validar límite préstamos
    SELECT COUNT(*) INTO prestamosactivos FROM PRESTAMO WHERE id_socio = idsocio AND estado = 'ACTIVO';
    IF prestamosactivos >= 3 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio ya alcanzó el límite de 3 préstamos activos.';
    END IF;

    -- 3. Validar estado físico ejemplar
    SELECT estado_fisico INTO estadoejemplar FROM EJEMPLAR WHERE id_ejemplar = idejemplar;
    IF estadoejemplar = 'BAJA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El ejemplar está dado de baja.';
    END IF;

    -- 4. Validar disponibilidad stock
    SELECT l.stock_disponible INTO stockdisp FROM LIBRO l 
    JOIN EJEMPLAR e ON l.isbn = e.isbn WHERE e.id_ejemplar = idejemplar;
    
    IF stockdisp <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No hay stock disponible para este título.';
    END IF;

    START TRANSACTION;
    -- Insertar préstamo (el trigger trg_actualizar_stock_insert se encarga stock)
    INSERT INTO PRESTAMO (id_socio, id_ejemplar, fecha_vencimiento, estado)
    VALUES (idsocio, idejemplar, DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'ACTIVO');
    COMMIT;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_generar_sancion(IN idsocio INT, IN tiposancion VARCHAR(20), IN diasmora INT)
BEGIN
    DECLARE diassancion INT;

    -- Regla negocio: 2 días suspensión por cada día mora
    SET diassancion = diasmora * 2;

    -- Se inserta sancion y trigger trg_estado_socio se activa
    INSERT INTO SANCION (id_socio, tipo, fecha_inicio, fecha_fin, motivo)
    VALUES (idsocio, tiposancion, CURDATE(), DATE_ADD(CURDATE(), INTERVAL diassancion DAY), 
           CONCAT('Sanción automática. Días de mora: ', diasmora)
           );
END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_registrar_devolucion(IN idprestamo INT)
BEGIN
    DECLARE idsocio INT;
    DECLARE fechavenc DATE;
    DECLARE estadoactual VARCHAR(12);
    DECLARE diasmora INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al procesar la devolución. Transacción abortada.';
    END;

    -- 1. Rescatar datos de prestamo
    SELECT id_socio, fecha_vencimiento, estado 
    INTO idsocio, fechavenc, estadoactual
    FROM PRESTAMO 
    WHERE id_prestamo = idprestamo;

    -- 2. Validar que no intente devolver algo ya devuelto
    IF estadoactual = 'DEVUELTO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este préstamo ya fue registrado como devuelto.';
    END IF;

    START TRANSACTION;
    -- 3. Actualizar préstamo a DEVUELTO (dispara trigger de stock)
    UPDATE PRESTAMO SET estado = 'DEVUELTO', fecha_devolucion = CURDATE()
    WHERE id_prestamo = idprestamo;

    -- 4. Verificar si hay mora y delegar sanción
    IF CURDATE() > fechavenc THEN
        SET diasmora = DATEDIFF(CURDATE(), fechavenc);
        -- Llamada SP creado anteriormente
        CALL sp_generar_sancion(idsocio, 'MORA', diasmora);
    END IF;
    COMMIT;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_renovar_prestamo(IN idprestamo INT)
BEGIN
    DECLARE idsocio INT;
    DECLARE estadosocio VARCHAR(20);
    DECLARE estadoprestamo VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error al procesar la renovación.';
    END;

    -- Recuperar info actual
    SELECT id_socio, estado INTO idsocio, estadoprestamo FROM PRESTAMO 
    WHERE id_prestamo = idprestamo;

    -- 1. Validar préstamo activo (no vencido ni devuelto)
    IF estadoprestamo != 'ACTIVO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden renovar préstamos en estado ACTIVO.';
    END IF;

    -- 2. Validar integridad socio (que no tenga sanciones)
    SELECT estado INTO estadosocio FROM SOCIO WHERE id_socio = idsocio;
    IF estadosocio = 'SUSPENDIDO' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El socio registra sanciones activas. Renovación denegada.';
    END IF;

    START TRANSACTION;
    -- 3. Extender el vencimiento por 14 días adicionales desde su vencimiento original
    UPDATE PRESTAMO SET fecha_vencimiento = DATE_ADD(fecha_vencimiento, INTERVAL 14 DAY)
    WHERE id_prestamo = idprestamo;
    COMMIT;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_procesar_vencimientos_diarios()
BEGIN
    DECLARE filasafectadas INT;

    -- Actualizar estado prestamos cuya fecha de vencimiento ya pasó
    UPDATE PRESTAMO SET estado = 'VENCIDO'
    WHERE estado = 'ACTIVO' AND fecha_vencimiento < CURDATE();
    SET filasafectadas = ROW_COUNT();
    
    SELECT CONCAT('Proceso completado. Préstamos vencidos actualizados: ', filasafectadas) AS Resultado;

END $$
DELIMITER;


DELIMITER $$
CREATE PROCEDURE sp_anonimizar_socio_baja(IN idsocio INT)
BEGIN
    -- Reemplaza datos personales por anon manteniendo ID para historial
    UPDATE SOCIO
    SET 
        dni = CONCAT('ANON-', idsocio),
        nombre = 'Usuario',
        apellido = 'Anónimo',
        email = CONCAT('anon', idsocio, '@biblioteca.local'),
        estado = 'BAJA'
    WHERE id_socio = idsocio;
    
    SELECT 'Datos de socio anonimizados correctamente por cumplimiento de privacidad.' AS Confirmacion;

END $$
DELIMITER ;


DELIMITER $$
CREATE PROCEDURE sp_reporte_salud_biblioteca()
BEGIN
    DECLARE totallibros INT;
    DECLARE libroscirculando INT;
    DECLARE tasamora DECIMAL(5,2);
    
    SELECT SUM(stock_total) INTO totallibros FROM LIBRO;
    SELECT COUNT(*) INTO libroscirculando FROM PRESTAMO WHERE estado IN ('ACTIVO', 'VENCIDO');
    
    SELECT (COUNT(DISTINCT id_socio) * 100 / (SELECT COUNT(*) FROM SOCIO WHERE estado != 'BAJA')) INTO tasamora 
    FROM SANCION WHERE CURDATE() BETWEEN fecha_inicio AND fecha_fin;

    SELECT 
        totallibros AS 'Total inventario',
        libroscirculando AS 'Ejemplares en circulación',
        CONCAT(ROUND((libroscirculando / totallibros) * 100, 2), '%') AS 'Tasa ocupación',
        CONCAT(IFNULL(ROUND(tasamora, 2), 0), '%') AS 'Porcentaje socios sancionados';

END $$
DELIMITER ;