SET SERVEROUTPUT ON;

DECLARE
    v_id_cliente NUMBER := 1;      
    v_id_habitacion NUMBER := 1;   
BEGIN
    DBMS_OUTPUT.PUT_LINE(' INICIANDO PRUEBAS DE LA CAPA PL/SQL Y TRIGGERS');


    -- PRUEBA 1: Crear una reserva exitosa en fechas con temporada definida (Julio)

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '>>> PRUEBA 1: Creación de reserva exitosa (Checkin: 2026-07-10 a 2026-07-15)');
    BEGIN
        PKG_TURISMOUQ_RESERVAS.sp_crear_reserva(
            p_id_cliente => v_id_cliente,
            p_id_habitacion => v_id_habitacion,
            p_fecha_in => TO_DATE('2026-07-10', 'YYYY-MM-DD'),
            p_fecha_out => TO_DATE('2026-07-15', 'YYYY-MM-DD'),
            p_cantidad_huespedes => 1
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado en Prueba 1: ' || SQLERRM);
    END;


    -- PRUEBA 2: Validar Excepción de Fechas Incongruentes 

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '>>> PRUEBA 2: Forzar error de fechas incongruentes');
    BEGIN
        PKG_TURISMOUQ_RESERVAS.sp_crear_reserva(
            p_id_cliente => v_id_cliente,
            p_id_habitacion => v_id_habitacion,
            p_fecha_in => TO_DATE('2026-12-10', 'YYYY-MM-DD'),
            p_fecha_out => TO_DATE('2026-12-05', 'YYYY-MM-DD'), 
            p_cantidad_huespedes => 1
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ÉXITO - Excepción capturada: ' || SQLERRM);
    END;

¿
    -- PRUEBA 3: Validar Excepción de Capacidad Excedida

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '>>> PRUEBA 3: Forzar error de capacidad máxima');
    BEGIN
        PKG_TURISMOUQ_RESERVAS.sp_crear_reserva(
            p_id_cliente => v_id_cliente,
            p_id_habitacion => v_id_habitacion,
            p_fecha_in => TO_DATE('2026-07-20', 'YYYY-MM-DD'),
            p_fecha_out => TO_DATE('2026-07-25', 'YYYY-MM-DD'),
            p_cantidad_huespedes => 99 
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ÉXITO - Excepción capturada: ' || SQLERRM);
    END;


    -- PRUEBA 4: Validar Trigger de Solapamiento (Habitación Ocupada)

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '>>> PRUEBA 4: Forzar solapamiento de fechas (Trigger / SP)');
    BEGIN
        -- Intentamos reservar pisando las fechas de la Prueba 1 (Julio 11 al 13)
        PKG_TURISMOUQ_RESERVAS.sp_crear_reserva(
            p_id_cliente => 2,
            p_id_habitacion => v_id_habitacion,
            p_fecha_in => TO_DATE('2026-07-11', 'YYYY-MM-DD'),
            p_fecha_out => TO_DATE('2026-07-13', 'YYYY-MM-DD'),
            p_cantidad_huespedes => 1
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ÉXITO - Solapamiento evitado: ' || SQLERRM);
    END;

    -- PRUEBA 5: Ejecución del Cursor Parametrizado (Liquidación Mensual)

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '>>> PRUEBA 5: Ejecutando Cursor de Liquidación para Julio 2026');
    FOR reg IN PKG_TURISMOUQ_RESERVAS.c_liquidacion_mensual(7, 2026) LOOP
        DBMS_OUTPUT.PUT_LINE('Alojamiento: ' || reg.nombre_comercial || 
                             ' | Reservas: ' || reg.total_reservas || 
                             ' | Total a Liquidar: $' || reg.total_liquidar);
    END LOOP;

END;
/


-- PRUEBA 6: Trigger de Auditoría de Tarifas

PROMPT >>> PRUEBA 6: Modificando una tarifa para disparar la auditoria...
UPDATE TARIFA SET precio_noche = precio_noche * 1.10 WHERE id_tarifa = 2;
COMMIT;

PROMPT >>> Resultados de la tabla de auditoria:
SELECT id_auditoria, usuario_bd, fecha_cambio, id_tarifa, valor_anterior, valor_nuevo 
FROM AUDITORIA_TARIFA 
ORDER BY id_auditoria DESC 
FETCH FIRST 3 ROWS ONLY;