
-- 1. TABLESPACE: HISTÓRICO DE RESERVAS
CREATE TABLESPACE TS_HISTORICO_RESERVAS
    DATAFILE 'historico_reservas_01.dbf' SIZE 100M
    AUTOEXTEND ON NEXT 50M MAXSIZE 2G
    LOGGING
    ONLINE
    SEGMENT SPACE MANAGEMENT AUTO;

ALTER TABLE RESERVA_HABITACION MOVE TABLESPACE TS_HISTORICO_RESERVAS;
ALTER TABLE RESERVA MOVE TABLESPACE TS_HISTORICO_RESERVAS;


-- 2. VISTA MATERIALIZADA: OCUPACIÓN MENSUAL

CREATE MATERIALIZED VIEW MV_OCUPACION_MENSUAL
    BUILD IMMEDIATE
    REFRESH COMPLETE 
    START WITH SYSDATE 
    NEXT SYSDATE + 1
AS
SELECT 
    m.nombre AS municipio,
    a.nombre_comercial AS alojamiento,
    EXTRACT(YEAR FROM rh.fecha_in_especifica) AS anio,
    EXTRACT(MONTH FROM rh.fecha_in_especifica) AS mes,
    COUNT(rh.id_reserva) AS cantidad_reservas,
    SUM(rh.valor_calculado_estadia) AS ingresos_mensuales
FROM RESERVA_HABITACION rh
JOIN HABITACION h ON rh.id_habitacion = h.id_habitacion
JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio
JOIN RESERVA r ON rh.id_reserva = r.id_reserva
WHERE r.estado IN ('completada', 'confirmada')
GROUP BY 
    m.nombre, 
    a.nombre_comercial, 
    EXTRACT(YEAR FROM rh.fecha_in_especifica), 
    EXTRACT(MONTH FROM rh.fecha_in_especifica);

CREATE INDEX idx_mv_ocupacion_mes ON MV_OCUPACION_MENSUAL(mes, anio);