
-- ------------------------------------------------------------------------------
-- 1. PIVOT: Ocupación por municipio y mes (Número de reservas confirmadas/completadas)
-- ------------------------------------------------------------------------------
SELECT * FROM (
    SELECT 
        m.nombre AS municipio, 
        TO_CHAR(r.fecha_checkin_global, 'MM') AS mes
    FROM RESERVA r
    JOIN RESERVA_HABITACION rh ON r.id_reserva = rh.id_reserva
    JOIN HABITACION h ON rh.id_habitacion = h.id_habitacion
    JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
    JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio
    WHERE r.estado IN ('confirmada', 'completada')
)
PIVOT (
    COUNT(mes)
    FOR mes IN (
        '01' AS Ene, '02' AS Feb, '03' AS Mar, '04' AS Abr, 
        '05' AS May, '06' AS Jun, '07' AS Jul, '08' AS Ago, 
        '09' AS Sep, '10' AS Oct, '11' AS Nov, '12' AS Dic
    )
)
ORDER BY municipio;

-- ------------------------------------------------------------------------------
-- 2. ROLLUP con GROUPING: Ingresos por municipio, tipo de alojamiento y temporada
-- ------------------------------------------------------------------------------
SELECT 
    DECODE(GROUPING(m.nombre), 1, '*** TOTAL MUNICIPIOS ***', m.nombre) AS municipio,
    DECODE(GROUPING(ta.nombre), 1, '*** TOTAL TIPOS ***', ta.nombre) AS tipo_alojamiento,
    DECODE(GROUPING(t.nombre), 1, '*** TOTAL TEMPORADAS ***', t.nombre) AS temporada,
    SUM(rh.valor_calculado_estadia) AS total_ingresos
FROM RESERVA_HABITACION rh
JOIN HABITACION h ON rh.id_habitacion = h.id_habitacion
JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio
JOIN TIPO_ALOJAMIENTO ta ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
JOIN TARIFA tar ON tar.id_habitacion = h.id_habitacion
JOIN TEMPORADA t ON tar.id_temporada = t.id_temporada
-- Condición simplificada para asociar el ingreso a la temporada donde inició la reserva
WHERE rh.fecha_in_especifica BETWEEN t.fecha_inicio AND t.fecha_fin
GROUP BY ROLLUP(m.nombre, ta.nombre, t.nombre)
ORDER BY m.nombre, ta.nombre, t.nombre;

-- ------------------------------------------------------------------------------
-- 3. RANK con PARTITION BY: Los 3 alojamientos de mayor ingreso dentro de cada municipio
-- ------------------------------------------------------------------------------
WITH IngresosAlojamiento AS (
    SELECT 
        m.nombre AS municipio,
        a.nombre_comercial,
        SUM(rh.valor_calculado_estadia) AS ingresos_totales,
        RANK() OVER (PARTITION BY m.nombre ORDER BY SUM(rh.valor_calculado_estadia) DESC) AS ranking
    FROM RESERVA_HABITACION rh
    JOIN HABITACION h ON rh.id_habitacion = h.id_habitacion
    JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
    JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio
    GROUP BY m.nombre, a.nombre_comercial
)
SELECT municipio, nombre_comercial, ingresos_totales, ranking
FROM IngresosAlojamiento
WHERE ranking <= 3;

-- ------------------------------------------------------------------------------
-- 4. LAG: Variación de ingresos mes contra mes a nivel general
-- ------------------------------------------------------------------------------
WITH IngresosMensuales AS (
    SELECT 
        TO_CHAR(rh.fecha_in_especifica, 'YYYY-MM') AS mes,
        SUM(rh.valor_calculado_estadia) AS ingresos_actuales
    FROM RESERVA_HABITACION rh
    GROUP BY TO_CHAR(rh.fecha_in_especifica, 'YYYY-MM')
)
SELECT 
    mes,
    ingresos_actuales,
    LAG(ingresos_actuales, 1, 0) OVER (ORDER BY mes) AS ingresos_mes_anterior,
    ingresos_actuales - LAG(ingresos_actuales, 1, 0) OVER (ORDER BY mes) AS variacion_neta
FROM IngresosMensuales
ORDER BY mes;

-- ------------------------------------------------------------------------------
-- 5. Consulta parametrizada con variables de enlace: Reservas por rango de fechas
-- ------------------------------------------------------------------------------
VARIABLE b_fecha_inicio VARCHAR2(10);
VARIABLE b_fecha_fin VARCHAR2(10);

-- Se asignan valores a las variables de enlace para que el script corra de forma ininterrumpida
EXEC :b_fecha_inicio := '2024-01-01';
EXEC :b_fecha_fin := '2024-12-31';

SELECT 
    r.id_reserva, 
    c.nombre_completo, 
    r.fecha_checkin_global, 
    r.estado
FROM RESERVA r
JOIN CLIENTE c ON r.id_cliente = c.id_cliente
WHERE r.fecha_checkin_global BETWEEN TO_DATE(:b_fecha_inicio, 'YYYY-MM-DD') AND TO_DATE(:b_fecha_fin, 'YYYY-MM-DD')
ORDER BY r.fecha_checkin_global FETCH FIRST 50 ROWS ONLY;

-- ------------------------------------------------------------------------------
-- 6. UNPIVOT: Transposición de totales de ingresos por método de pago
-- ------------------------------------------------------------------------------
WITH PagosResumen AS (
    SELECT 
        SUM(CASE WHEN metodo = 'Tarjeta de Crédito' THEN monto ELSE 0 END) AS tc,
        SUM(CASE WHEN metodo = 'Efectivo' THEN monto ELSE 0 END) AS efectivo,
        SUM(CASE WHEN metodo = 'PSE' THEN monto ELSE 0 END) AS pse
    FROM PAGO
    WHERE estado = 'exitoso'
)
SELECT metodo_pago, total_recaudado
FROM PagosResumen
UNPIVOT (
    total_recaudado FOR metodo_pago IN (
        tc AS 'Tarjeta de Crédito', 
        efectivo AS 'Efectivo', 
        pse AS 'PSE'
    )
);

-- ------------------------------------------------------------------------------
-- 7. Consulta libre: ¿Cuáles son los clientes con mayor tasa de cancelación (mínimo 5 reservas)?
-- ------------------------------------------------------------------------------
SELECT 
    c.nombre_completo,
    c.telefono,
    COUNT(r.id_reserva) AS total_reservas,
    SUM(CASE WHEN r.estado = 'cancelada' THEN 1 ELSE 0 END) AS reservas_canceladas,
    ROUND(SUM(CASE WHEN r.estado = 'cancelada' THEN 1 ELSE 0 END) * 100.0 / COUNT(r.id_reserva), 2) AS porcentaje_cancelacion
FROM CLIENTE c
JOIN RESERVA r ON c.id_cliente = r.id_cliente
GROUP BY c.nombre_completo, c.telefono
HAVING COUNT(r.id_reserva) >= 5
ORDER BY porcentaje_cancelacion DESC
FETCH FIRST 20 ROWS ONLY;