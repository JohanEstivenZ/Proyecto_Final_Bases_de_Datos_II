
SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE PKG_TURISMOUQ_RESERVAS AS
    FUNCTION fn_valor_estadia(p_id_habitacion NUMBER, p_fecha_in DATE, p_fecha_out DATE) RETURN NUMBER;
    PROCEDURE sp_crear_reserva(p_id_cliente NUMBER, p_id_habitacion NUMBER, p_fecha_in DATE, p_fecha_out DATE, p_cantidad_huespedes NUMBER);
    PROCEDURE sp_generar_liquidacion(p_mes NUMBER, p_anio NUMBER);
END PKG_TURISMOUQ_RESERVAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_TURISMOUQ_RESERVAS AS

    -- 1. Función de estadía
    FUNCTION fn_valor_estadia(p_id_habitacion NUMBER, p_fecha_in DATE, p_fecha_out DATE) RETURN NUMBER IS
        v_total_estadia NUMBER := 0;
        v_precio_noche NUMBER;
        v_fecha_actual DATE := p_fecha_in;
    BEGIN
        WHILE v_fecha_actual < p_fecha_out LOOP
            BEGIN
                SELECT tar.precio_noche INTO v_precio_noche
                FROM TARIFA tar
                JOIN TEMPORADA temp ON tar.id_temporada = temp.id_temporada
                WHERE tar.id_habitacion = p_id_habitacion
                  AND v_fecha_actual BETWEEN temp.fecha_inicio AND temp.fecha_fin;
                  
                v_total_estadia := v_total_estadia + v_precio_noche;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20004, 'No hay tarifa definida para la fecha: ' || TO_CHAR(v_fecha_actual, 'YYYY-MM-DD'));
            END;
            v_fecha_actual := v_fecha_actual + 1;
        END LOOP;
        RETURN v_total_estadia;
    END fn_valor_estadia;

    -- 2. Procedimiento de crear reserva
    PROCEDURE sp_crear_reserva(
        p_id_cliente NUMBER, p_id_habitacion NUMBER, p_fecha_in DATE, p_fecha_out DATE, p_cantidad_huespedes NUMBER
    ) IS
        v_capacidad_maxima NUMBER;
        v_reservas_cruzadas NUMBER;
        v_nuevo_id_reserva NUMBER;
        v_valor_total NUMBER;
    BEGIN
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(-20001, 'La fecha de checkout debe ser mayor al checkin.');
        END IF;

        SELECT capacidad_maxima INTO v_capacidad_maxima FROM HABITACION WHERE id_habitacion = p_id_habitacion;
        IF p_cantidad_huespedes > v_capacidad_maxima THEN
            RAISE_APPLICATION_ERROR(-20002, 'La cantidad de huéspedes supera la capacidad máxima.');
        END IF;

        SELECT COUNT(*) INTO v_reservas_cruzadas
        FROM RESERVA_HABITACION rh
        JOIN RESERVA r ON rh.id_reserva = r.id_reserva
        WHERE rh.id_habitacion = p_id_habitacion AND r.estado IN ('confirmada', 'pendiente', 'completada')
          AND (p_fecha_in < rh.fecha_out_especifica AND p_fecha_out > rh.fecha_in_especifica);

        IF v_reservas_cruzadas > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Solapamiento de reservas en la habitación.');
        END IF;

        v_valor_total := fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

        SELECT NVL(MAX(id_reserva), 0) + 1 INTO v_nuevo_id_reserva FROM RESERVA;

        INSERT INTO RESERVA (id_reserva, id_cliente, fecha_checkin_global, fecha_checkout_global, estado, fecha_registro)
        VALUES (v_nuevo_id_reserva, p_id_cliente, p_fecha_in, p_fecha_out, 'pendiente', SYSTIMESTAMP);

        INSERT INTO RESERVA_HABITACION (id_reserva, id_habitacion, fecha_in_especifica, fecha_out_especifica, valor_calculado_estadia)
        VALUES (v_nuevo_id_reserva, p_id_habitacion, p_fecha_in, p_fecha_out, v_valor_total);

        COMMIT;
    END sp_crear_reserva;

    -- 3. Procedimiento con Cursor de Liquidación
    PROCEDURE sp_generar_liquidacion(p_mes NUMBER, p_anio NUMBER) IS
        CURSOR c_liquidacion IS
            SELECT a.nombre_comercial, SUM(rh.valor_calculado_estadia) AS total_liquidar
            FROM ALOJAMIENTO a
            JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
            JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
            JOIN RESERVA r ON rh.id_reserva = r.id_reserva
            WHERE EXTRACT(MONTH FROM rh.fecha_in_especifica) = p_mes
              AND EXTRACT(YEAR FROM rh.fecha_in_especifica) = p_anio
              AND r.estado IN ('completada', 'confirmada')
            GROUP BY a.nombre_comercial;
    BEGIN
        FOR reg IN c_liquidacion LOOP
            DBMS_OUTPUT.PUT_LINE('Liquidación ' || reg.nombre_comercial || ': $' || reg.total_liquidar);
        END LOOP;
    END sp_generar_liquidacion;

END PKG_TURISMOUQ_RESERVAS;
/
