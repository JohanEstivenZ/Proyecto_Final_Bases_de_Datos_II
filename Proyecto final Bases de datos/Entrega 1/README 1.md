# Proyecto_Final_Bases_de_Datos_II

# Plataforma de Reservas Turísticas del Quindío

Proyecto integrador para la asignatura **Bases de Datos II**
Este repositorio contiene el modelo de datos, la lógica de negocio y las consultas analíticas implementadas sobre **Oracle XE 21c** para gestionar la oferta turística, tarifas dinámicas por temporadas y reservas del departamento del Quindío.

## 📁 Estructura del Repositorio

Los archivos están numerados en estricto orden de ejecución para garantizar un despliegue exitoso en una base de datos limpia:

1. **`Modelo y decisiones Bases de datos.docx`**: Diagrama Entidad-Relación (MER), reglas de negocio y sustentación de decisiones de arquitectura.
2. **`Ejecucion 1_DLL_Proyecto_Final.sql`**: Definición del esquema (14 entidades mínimas), llaves primarias, foráneas y restricciones `CHECK`/`UNIQUE`.
3. **`Ejecucion2_ Carga_de_datos.sql`**: Bloque PL/SQL para la inserción asimétrica y masiva de datos (municipios, alojamientos, habitaciones, tarifas dinámicas, 3.000 clientes, 25.000 reservas).
4. **`Ejecucion3_Consultas.sql`**: Consultas analíticas (PIVOT, ROLLUP, RANK, LAG, UNPIVOT).

## Instrucciones de Ejecución
1. Ejecutar el script `Ejecucion 1_DLL_Proyecto_Final.sql` completo.
2. Ejecutar el script `Ejecucion2_ Carga_de_datos.sql` y esperar el mensaje de confirmación en la salida DBMS.
3. Ejecutar las consultas de análisis del archivo `Ejecucion3_Consultas.sql`.

## 👥 Equipo de Trabajo
Johan Estiven Zapata Arcila
