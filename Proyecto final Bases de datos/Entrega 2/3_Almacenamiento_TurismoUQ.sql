-- ==============================================================================
-- Script 3: Almacenamiento Avanzado (Histórico Real y Vista Materializada)
-- ==============================================================================

-- 1. Creación del Tablespace (Ignorar error ORA-01543 si ya existe en tu PC)
CREATE TABLESPACE TS_HISTORICO_RESERVAS
    DATAFILE 'historico_reservas_02.dbf' SIZE 100M
    AUTOEXTEND ON NEXT 50M MAXSIZE 2G;

-- 2. Creación de la Tabla Histórica dentro del nuevo Tablespace
CREATE TABLE HISTORICO_RESERVAS (
    id_reserva NUMBER PRIMARY KEY,
    id_cliente NUMBER NOT NULL,
    fecha_checkin_global DATE,
    fecha_checkout_global DATE,
    estado VARCHAR2(20),
    fecha_archivo TIMESTAMP DEFAULT SYSTIMESTAMP
) TABLESPACE TS_HISTORICO_RESERVAS;

-- 3. Vista Materializada de Ocupación
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
    m.nombre, a.nombre_comercial, EXTRACT(YEAR FROM rh.fecha_in_especifica), EXTRACT(MONTH FROM rh.fecha_in_especifica);

CREATE INDEX idx_mv_ocupacion_mes ON MV_OCUPACION_MENSUAL(mes, anio);
