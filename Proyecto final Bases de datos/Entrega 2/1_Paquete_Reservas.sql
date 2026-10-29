
SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE PKG_TURISMOUQ_RESERVAS AS

    CURSOR c_liquidacion_mensual(p_mes NUMBER, p_anio NUMBER) IS
        SELECT 
            a.id_alojamiento, 
            a.nombre_comercial, 
            SUM(rh.valor_calculado_estadia) AS total_liquidar,
            COUNT(rh.id_reserva) AS total_reservas
        FROM ALOJAMIENTO a
        JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
        JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
        WHERE EXTRACT(MONTH FROM rh.fecha_in_especifica) = p_mes
          AND EXTRACT(YEAR FROM rh.fecha_in_especifica) = p_anio
        GROUP BY a.id_alojamiento, a.nombre_comercial;


    FUNCTION fn_valor_estadia(p_id_habitacion NUMBER, p_fecha_in DATE, p_fecha_out DATE) RETURN NUMBER;

    PROCEDURE sp_crear_reserva(
        p_id_cliente NUMBER,
        p_id_habitacion NUMBER,
        p_fecha_in DATE,
        p_fecha_out DATE,
        p_cantidad_huespedes NUMBER
    );
END PKG_TURISMOUQ_RESERVAS;
/

-- 2. CUERPO DEL PAQUETE

CREATE OR REPLACE PACKAGE BODY PKG_TURISMOUQ_RESERVAS AS

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
     
                    RAISE_APPLICATION_ERROR(-20004, 'No hay tarifa o temporada definida para la fecha: ' || TO_CHAR(v_fecha_actual, 'YYYY-MM-DD'));
            END;
            
         
            v_fecha_actual := v_fecha_actual + 1;
        END LOOP;
        
        RETURN v_total_estadia;
    END fn_valor_estadia;

    PROCEDURE sp_crear_reserva(
        p_id_cliente NUMBER,
        p_id_habitacion NUMBER,
        p_fecha_in DATE,
        p_fecha_out DATE,
        p_cantidad_huespedes NUMBER
    ) IS
        v_capacidad_maxima NUMBER;
        v_reservas_cruzadas NUMBER;
        v_nuevo_id_reserva NUMBER;
        v_valor_total NUMBER;
    BEGIN
   
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error: La fecha de checkout debe ser estrictamente mayor a la fecha de checkin.');
        END IF;


        SELECT capacidad_maxima INTO v_capacidad_maxima
        FROM HABITACION
        WHERE id_habitacion = p_id_habitacion;

        IF p_cantidad_huespedes > v_capacidad_maxima THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error: La cantidad de huéspedes (' || p_cantidad_huespedes || ') supera la capacidad máxima de la habitación (' || v_capacidad_maxima || ').');
        END IF;


        SELECT COUNT(*) INTO v_reservas_cruzadas
        FROM RESERVA_HABITACION rh
        JOIN RESERVA r ON rh.id_reserva = r.id_reserva
        WHERE rh.id_habitacion = p_id_habitacion
          AND r.estado IN ('confirmada', 'pendiente', 'completada') -- Se ignoran las canceladas
          AND (p_fecha_in < rh.fecha_out_especifica AND p_fecha_out > rh.fecha_in_especifica);

        IF v_reservas_cruzadas > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error: La habitación no está disponible para las fechas solicitadas. Existe solapamiento de reservas.');
        END IF;

        v_valor_total := fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

        SELECT NVL(MAX(id_reserva), 0) + 1 INTO v_nuevo_id_reserva FROM RESERVA;

        INSERT INTO RESERVA (id_reserva, id_cliente, fecha_checkin_global, fecha_checkout_global, estado, fecha_registro)
        VALUES (v_nuevo_id_reserva, p_id_cliente, p_fecha_in, p_fecha_out, 'pendiente', SYSTIMESTAMP);

        INSERT INTO RESERVA_HABITACION (id_reserva, id_habitacion, fecha_in_especifica, fecha_out_especifica, valor_calculado_estadia)
        VALUES (v_nuevo_id_reserva, p_id_habitacion, p_fecha_in, p_fecha_out, v_valor_total);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Reserva ' || v_nuevo_id_reserva || ' creada con éxito por un valor de $' || v_valor_total);
        
    END sp_crear_reserva;

END PKG_TURISMOUQ_RESERVAS;
/