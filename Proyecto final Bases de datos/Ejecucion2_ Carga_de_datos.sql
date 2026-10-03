
SET SERVEROUTPUT ON;

DECLARE
    v_id_alojamiento NUMBER := 1;
    v_id_habitacion NUMBER := 1;
    v_id_tarifa NUMBER := 1;
    v_id_servicio NUMBER := 1;
    v_id_reserva NUMBER := 1;
    v_id_pago NUMBER := 1;
    v_id_resena NUMBER := 1;
    v_habitaciones_crear NUMBER;
    v_fecha_in DATE;
    v_fecha_out DATE;
    v_estado_reserva VARCHAR2(20);
    v_id_cliente NUMBER;
    v_id_hab_reserva NUMBER;
    v_noches NUMBER;
    v_precio_base NUMBER;
BEGIN
    -- 1. Carga de MUNICIPIOS
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (1, 'Armenia', '63001');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (2, 'Buenavista', '63111');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (3, 'Calarcá', '63130');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (4, 'Circasia', '63190');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (5, 'Córdoba', '63212');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (6, 'Filandia', '63272');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (7, 'Génova', '63302');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (8, 'La Tebaida', '63401');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (9, 'Montenegro', '63470');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (10, 'Pijao', '63548');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (11, 'Quimbaya', '63594');
    INSERT INTO MUNICIPIO (id_municipio, nombre, codigo_dane) VALUES (12, 'Salento', '63690');

    -- 2. Carga de TIPO_ALOJAMIENTO
    INSERT INTO TIPO_ALOJAMIENTO (id_tipo_alojamiento, nombre, descripcion) VALUES (1, 'Hotel', 'Establecimiento tradicional urbano o campestre');
    INSERT INTO TIPO_ALOJAMIENTO (id_tipo_alojamiento, nombre, descripcion) VALUES (2, 'Finca Cafetera', 'Alojamiento rural tradicional');
    INSERT INTO TIPO_ALOJAMIENTO (id_tipo_alojamiento, nombre, descripcion) VALUES (3, 'Glamping', 'Acampada de lujo en la naturaleza');
    INSERT INTO TIPO_ALOJAMIENTO (id_tipo_alojamiento, nombre, descripcion) VALUES (4, 'Hostal', 'Alojamiento económico con áreas compartidas');

    -- 3. Carga de TEMPORADAS
    INSERT INTO TEMPORADA (id_temporada, nombre, anio, fecha_inicio, fecha_fin) VALUES (1, 'Alta', 2025, TO_DATE('2025-12-15','YYYY-MM-DD'), TO_DATE('2026-01-15','YYYY-MM-DD'));
    INSERT INTO TEMPORADA (id_temporada, nombre, anio, fecha_inicio, fecha_fin) VALUES (2, 'Media', 2025, TO_DATE('2025-06-01','YYYY-MM-DD'), TO_DATE('2025-08-31','YYYY-MM-DD'));
    INSERT INTO TEMPORADA (id_temporada, nombre, anio, fecha_inicio, fecha_fin) VALUES (3, 'Baja', 2025, TO_DATE('2025-02-01','YYYY-MM-DD'), TO_DATE('2025-05-31','YYYY-MM-DD'));
    INSERT INTO TEMPORADA (id_temporada, nombre, anio, fecha_inicio, fecha_fin) VALUES (4, 'Alta', 2026, TO_DATE('2026-12-15','YYYY-MM-DD'), TO_DATE('2027-01-15','YYYY-MM-DD'));
    INSERT INTO TEMPORADA (id_temporada, nombre, anio, fecha_inicio, fecha_fin) VALUES (5, 'Media', 2026, TO_DATE('2026-06-01','YYYY-MM-DD'), TO_DATE('2026-08-31','YYYY-MM-DD'));
    INSERT INTO TEMPORADA (id_temporada, nombre, anio, fecha_inicio, fecha_fin) VALUES (6, 'Baja', 2026, TO_DATE('2026-02-01','YYYY-MM-DD'), TO_DATE('2026-05-31','YYYY-MM-DD'));

    -- 4. Generación asimétrica de ALOJAMIENTOS y HABITACIONES
    FOR i_mun IN 1..12 LOOP
        FOR i_aloj IN 1..5 LOOP 
            DECLARE
                v_tipo NUMBER := TRUNC(DBMS_RANDOM.VALUE(1, 5));
            BEGIN
                INSERT INTO ALOJAMIENTO (id_alojamiento, id_municipio, id_tipo_alojamiento, nombre_comercial, direccion, estrellas, telefono_contacto, correo_contacto) 
                VALUES (
                    v_id_alojamiento, i_mun, v_tipo, 
                    'Alojamiento ' || v_id_alojamiento || ' Mun ' || i_mun,
                    'Direccion Aleatoria ' || v_id_alojamiento,
                    TRUNC(DBMS_RANDOM.VALUE(1, 6)),
                    '300' || TRUNC(DBMS_RANDOM.VALUE(1000000, 9999999)),
                    'contacto' || v_id_alojamiento || '@turismouq.com'
                );

                IF v_tipo = 1 THEN
                    v_habitaciones_crear := TRUNC(DBMS_RANDOM.VALUE(10, 21));
                ELSE
                    v_habitaciones_crear := TRUNC(DBMS_RANDOM.VALUE(2, 6));
                END IF;

                FOR i_hab IN 1..v_habitaciones_crear LOOP
                    INSERT INTO HABITACION (id_habitacion, id_alojamiento, numero, capacidad_maxima, tipo, descripcion) 
                    VALUES (
                        v_id_habitacion, v_id_alojamiento, 'HAB-' || i_hab,
                        TRUNC(DBMS_RANDOM.VALUE(1, 5)), 
                        CASE TRUNC(DBMS_RANDOM.VALUE(1, 4)) WHEN 1 THEN 'Sencilla' WHEN 2 THEN 'Doble' ELSE 'Suite' END,
                        'Habitación cómoda en el Quindío'
                    );

                    v_precio_base := TRUNC(DBMS_RANDOM.VALUE(50000, 200000));
                    FOR i_temp IN 1..6 LOOP
                        INSERT INTO TARIFA (id_tarifa, id_habitacion, id_temporada, precio_noche) 
                        VALUES (
                            v_id_tarifa, v_id_habitacion, i_temp,
                            CASE 
                                WHEN i_temp IN (1,4) THEN v_precio_base * 1.5 
                                WHEN i_temp IN (2,5) THEN v_precio_base * 1.2 
                                ELSE v_precio_base 
                            END
                        );
                        v_id_tarifa := v_id_tarifa + 1;
                    END LOOP;
                    v_id_habitacion := v_id_habitacion + 1;
                END LOOP;

                INSERT INTO SERVICIO (id_servicio, id_alojamiento, nombre, descripcion, precio) 
                VALUES (v_id_servicio, v_id_alojamiento, 'Desayuno Tradicional', 'Huevos, arepa, café', 15000);
                v_id_servicio := v_id_servicio + 1;

                v_id_alojamiento := v_id_alojamiento + 1;
            END;
        END LOOP;
    END LOOP;

    -- 5. Generación de CLIENTES
    FOR i_cli IN 1..3000 LOOP
        INSERT INTO CLIENTE (id_cliente, tipo_documento, numero_documento, nombre_completo, correo, telefono, ciudad_origen) 
        VALUES (
            i_cli, 'CC', 
            TO_CHAR(10000000 + i_cli), 
            'Cliente Frecuente ' || i_cli, 
            'cliente' || i_cli || '@email.com', 
            '310' || LPAD(i_cli, 7, '0'), 
            CASE TRUNC(DBMS_RANDOM.VALUE(1, 5)) WHEN 1 THEN 'Bogotá' WHEN 2 THEN 'Medellín' WHEN 3 THEN 'Cali' ELSE 'Pereira' END
        );
    END LOOP;

    -- 6. Generación de RESERVAS, PAGOS, SERVICIOS Y RESEÑAS
    FOR i_res IN 1..25000 LOOP
        v_id_cliente := TRUNC(DBMS_RANDOM.VALUE(1, 3001));
        v_fecha_in := TO_DATE('2024-01-01', 'YYYY-MM-DD') + TRUNC(DBMS_RANDOM.VALUE(0, 1000));
        v_noches := TRUNC(DBMS_RANDOM.VALUE(1, 6));
        v_fecha_out := v_fecha_in + v_noches;
        
        v_estado_reserva := CASE TRUNC(DBMS_RANDOM.VALUE(1, 10)) 
            WHEN 1 THEN 'cancelada' 
            WHEN 2 THEN 'pendiente' 
            ELSE 'completada' 
        END;

        INSERT INTO RESERVA (id_reserva, id_cliente, fecha_checkin_global, fecha_checkout_global, estado, fecha_registro) 
        VALUES (
            v_id_reserva, v_id_cliente, v_fecha_in, v_fecha_out, v_estado_reserva, SYSTIMESTAMP
        );

        v_id_hab_reserva := TRUNC(DBMS_RANDOM.VALUE(1, v_id_habitacion));
        INSERT INTO RESERVA_HABITACION (id_reserva, id_habitacion, fecha_in_especifica, fecha_out_especifica, valor_calculado_estadia) 
        VALUES (
            v_id_reserva, v_id_hab_reserva, v_fecha_in, v_fecha_out, 
            TRUNC(DBMS_RANDOM.VALUE(100000, 500000))
        );

        INSERT INTO PAGO (id_pago, id_reserva, fecha_pago, monto, metodo, estado) 
        VALUES (
            v_id_pago, v_id_reserva, SYSTIMESTAMP, TRUNC(DBMS_RANDOM.VALUE(100000, 500000)), 
            'Tarjeta de Crédito', CASE v_estado_reserva WHEN 'completada' THEN 'exitoso' ELSE 'pendiente' END
        );
        v_id_pago := v_id_pago + 1;

        IF v_estado_reserva = 'completada' AND TRUNC(DBMS_RANDOM.VALUE(1, 100)) <= 40 THEN
            INSERT INTO RESENA (id_resena, id_cliente, id_alojamiento, calificacion, comentario, fecha_resena) 
            VALUES (
                v_id_resena, v_id_cliente, 
                (SELECT id_alojamiento FROM HABITACION WHERE id_habitacion = v_id_hab_reserva),
                TRUNC(DBMS_RANDOM.VALUE(3, 6)), 'Excelente lugar.', SYSTIMESTAMP
            );
            v_id_resena := v_id_resena + 1;
        END IF;

        v_id_reserva := v_id_reserva + 1;
    END LOOP;

    -- 7. USUARIOS DEL SISTEMA
    INSERT INTO USUARIO_SISTEMA (id_usuario, id_alojamiento, nombre, correo, rol, password_hash) 
    VALUES (1, NULL, 'Admin General', 'admin@turismouq.com', 'admin_plataforma', 'hash123');
    FOR i_usr IN 2..10 LOOP
        INSERT INTO USUARIO_SISTEMA (id_usuario, id_alojamiento, nombre, correo, rol, password_hash) 
        VALUES (i_usr, i_usr, 'Encargado ' || i_usr, 'encargado'||i_usr||'@turismouq.com', 'encargado_alojamiento', 'hash123');
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Carga masiva finalizada con éxito');
END;
/