

-- 1. Tabla de Auditoría
CREATE TABLE AUDITORIA_TARIFA (
    id_auditoria NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_bd VARCHAR2(100), 
    fecha_cambio TIMESTAMP,
    id_tarifa NUMBER, 
    valor_anterior NUMBER(12,2), 
    valor_nuevo NUMBER(12,2)
);

-- 2. Disparador de Auditoría (Fila)
CREATE OR REPLACE TRIGGER trg_auditoria_tarifa
AFTER UPDATE OF precio_noche ON TARIFA
FOR EACH ROW
BEGIN
    IF :OLD.precio_noche <> :NEW.precio_noche THEN
        INSERT INTO AUDITORIA_TARIFA (usuario_bd, fecha_cambio, id_tarifa, valor_anterior, valor_nuevo) 
        VALUES (USER, SYSTIMESTAMP, :OLD.id_tarifa, :OLD.precio_noche, :NEW.precio_noche);
    END IF;
END;
/

-- 3. Disparador de Solapamiento (Transacción Autónoma)
CREATE OR REPLACE TRIGGER trg_evitar_solapamiento
BEFORE INSERT OR UPDATE ON RESERVA_HABITACION
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_cruzadas NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_cruzadas 
    FROM RESERVA_HABITACION rh JOIN RESERVA r ON rh.id_reserva = r.id_reserva
    WHERE rh.id_habitacion = :NEW.id_habitacion AND r.estado IN ('confirmada', 'completada', 'pendiente')
      AND (:NEW.fecha_in_especifica < rh.fecha_out_especifica AND :NEW.fecha_out_especifica > rh.fecha_in_especifica)
      AND rh.id_reserva != :NEW.id_reserva;

    IF v_cruzadas > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'TRIGGER: La habitación presenta solapamiento de fechas.');
    END IF;
    COMMIT; 
END;
/
