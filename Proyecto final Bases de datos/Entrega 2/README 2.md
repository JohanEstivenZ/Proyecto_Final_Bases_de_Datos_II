
# TurismoUQ - Entrega 2: Capa PL/SQL y Almacenamiento Avanzado

Proyecto integrador para la asignatura **Bases de Datos II** (Periodo 2026-2).  
Esta segunda entrega se centra en la implementación de la lógica de negocio mediante programación en la base de datos (PL/SQL) sobre **Oracle XE 21c**, la protección de la integridad de los datos mediante disparadores (Triggers) y la optimización física del almacenamiento.

## Estructura del Repositorio y Orden de Ejecución

Para cumplir con la regla de ejecución continua sobre una base limpia (después de ejecutar el modelo y carga de la Entrega 1), los scripts deben ejecutarse en el siguiente orden estricto:

1. **`1_Paquete_Reservas.sql`**: 
   * Crea el paquete `PKG_TURISMOUQ_RESERVAS`.
   * Incluye la función `fn_valor_estadia` que calcula el precio noche por noche atravesando temporadas.
   * Incluye el procedimiento `sp_crear_reserva` con validaciones de fechas, capacidad y solapamiento usando `RAISE_APPLICATION_ERROR`.
   * Incluye el cursor explícito parametrizado para la liquidación mensual.

2. **`2_Disparadores_TurismoUQ.sql`**: 
   * `trg_auditoria_tarifa`: Registra el historial de cambios de precios (usuario, fecha, valor anterior y nuevo).
   * `trg_evitar_solapamiento`: Impide el registro de reservas en fechas ocupadas para una misma habitación.

3. **`3_Almacenamiento_TurismoUQ.sql`**: 
   * Creación del Tablespace `TS_HISTORICO_RESERVAS` y reubicación de tablas transaccionales.
   * Creación de la Vista Materializada `MV_OCUPACION_MENSUAL` y su índice asociado.

4. **`4_Pruebas_y_Evidencias.sql`**: 
   * Bloque de pruebas PL/SQL diseñado para invocar exitosamente las reservas, forzar intencionalmente las excepciones personalizadas (`ORA-2000X`), probar el bloqueo de los triggers y mostrar el funcionamiento de la auditoría y el cursor.

5. **`Evidencias_Pruebas_Entrega2.pdf`** *(Opcional/Adjunto)*:
   * Capturas de consola demostrando la salida exitosa del Script 4.

## Justificaciones Técnicas de Arquitectura

* **Disparador de Auditoría (Fila vs Sentencia):** Aunque el requerimiento base plantea un disparador de "sentencia", la captura de los seudoregistros `:OLD` y `:NEW` para guardar el valor tarifario anterior y el nuevo exige, por arquitectura de Oracle, que el disparador sea a nivel de fila (`FOR EACH ROW`).
* **Prevención de Tabla Mutante (ORA-04091):** Para el trigger que evita el solapamiento de reservas en la misma habitación, se implementó la directiva `PRAGMA AUTONOMOUS_TRANSACTION`. Esto aísla la lectura de validación y evita el error de tabla mutante al consultar la tabla `RESERVA_HABITACION` mientras se está insertando en ella.
* **Separación en Tablespace:** Se decidió crear un tablespace propio para el histórico de reservas dado que es la data de mayor crecimiento y volumen transaccional. Separarlo del espacio por defecto evita la fragmentación, mejora el I/O en disco y permite respaldos (backups) independientes.
* **Política de Refresco (Vista Materializada):** Se optó por una actualización completa diaria a la medianoche (`NEXT SYSDATE + 1`). Recalcular la vista materializada con cada commit (`FAST ON COMMIT`) ahogaría el rendimiento transaccional del sistema, y la gerencia solo necesita cortes consolidados diarios para la toma de decisiones.

## Instrucciones de Despliegue
1. Garantizar que el esquema DDL y la carga de datos de la **Entrega 1** estén aplicados.
2. Ejecutar los scripts del **1 al 4** en orden secuencial.
3. Revisar la pestaña de salida de texto (`DBMS_OUTPUT`) en el Script 4 para verificar la captura exitosa de las excepciones de negocio.

## 👥 Equipo de Trabajo
* [Tu Nombre/Código]
* [Nombre/Código Integrante 2]
* [Nombre/Código Integrante 3]
