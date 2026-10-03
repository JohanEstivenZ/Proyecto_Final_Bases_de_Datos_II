-- Codigo para asegurar la ejecion borrando las cosas anteriores
DROP TABLE RESERVA_SERVICIO   CASCADE CONSTRAINTS PURGE;
DROP TABLE RESENA             CASCADE CONSTRAINTS PURGE;
DROP TABLE PAGO               CASCADE CONSTRAINTS PURGE;
DROP TABLE RESERVA_HABITACION CASCADE CONSTRAINTS PURGE;
DROP TABLE RESERVA            CASCADE CONSTRAINTS PURGE;
DROP TABLE USUARIO_SISTEMA    CASCADE CONSTRAINTS PURGE;
DROP TABLE SERVICIO           CASCADE CONSTRAINTS PURGE;
DROP TABLE TARIFA             CASCADE CONSTRAINTS PURGE;
DROP TABLE HABITACION         CASCADE CONSTRAINTS PURGE;
DROP TABLE ALOJAMIENTO        CASCADE CONSTRAINTS PURGE;
DROP TABLE TEMPORADA          CASCADE CONSTRAINTS PURGE;
DROP TABLE CLIENTE            CASCADE CONSTRAINTS PURGE;
DROP TABLE TIPO_ALOJAMIENTO   CASCADE CONSTRAINTS PURGE;
DROP TABLE MUNICIPIO          CASCADE CONSTRAINTS PURGE;
/
-- 1. MUNICIPIO
CREATE TABLE MUNICIPIO (
    id_municipio NUMBER PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    codigo_dane VARCHAR2(10)
);
COMMENT ON TABLE MUNICIPIO IS 'Catálogo de los 12 municipios del departamento del Quindío.';

-- 2. TIPO_ALOJAMIENTO
CREATE TABLE TIPO_ALOJAMIENTO (
    id_tipo_alojamiento NUMBER PRIMARY KEY,
    nombre VARCHAR2(50) NOT NULL,
    descripcion VARCHAR2(255)
);
COMMENT ON TABLE TIPO_ALOJAMIENTO IS 'Clasificación de los alojamientos: Finca cafetera, Hotel, Glamping, Hostal, etc.';

-- 3. ALOJAMIENTO
CREATE TABLE ALOJAMIENTO (
    id_alojamiento NUMBER PRIMARY KEY,
    id_municipio NUMBER NOT NULL,
    id_tipo_alojamiento NUMBER NOT NULL,
    nombre_comercial VARCHAR2(150) NOT NULL,
    direccion VARCHAR2(255) NOT NULL,
    estrellas NUMBER DEFAULT 1 NOT NULL,
    telefono_contacto VARCHAR2(20),
    correo_contacto VARCHAR2(100),
    CONSTRAINT chk_alojamiento_estrellas CHECK (estrellas BETWEEN 1 AND 5),
    CONSTRAINT fk_aloj_municipio FOREIGN KEY (id_municipio) REFERENCES MUNICIPIO(id_municipio),
    CONSTRAINT fk_aloj_tipo FOREIGN KEY (id_tipo_alojamiento) REFERENCES TIPO_ALOJAMIENTO(id_tipo_alojamiento)
);
COMMENT ON TABLE ALOJAMIENTO IS 'Establecimientos turísticos registrados en la plataforma.';

-- 4. HABITACION
CREATE TABLE HABITACION (
    id_habitacion NUMBER PRIMARY KEY,
    id_alojamiento NUMBER NOT NULL,
    numero VARCHAR2(20) NOT NULL,
    capacidad_maxima NUMBER NOT NULL,
    tipo VARCHAR2(50) NOT NULL,
    descripcion VARCHAR2(500),
    CONSTRAINT uk_habitacion_alojamiento UNIQUE (id_alojamiento, numero),
    CONSTRAINT chk_habitacion_capacidad CHECK (capacidad_maxima > 0),
    CONSTRAINT fk_hab_alojamiento FOREIGN KEY (id_alojamiento) REFERENCES ALOJAMIENTO(id_alojamiento)
);
COMMENT ON TABLE HABITACION IS 'Habitaciones disponibles por cada alojamiento. El número es único por establecimiento.';

-- 5. TEMPORADA
CREATE TABLE TEMPORADA (
    id_temporada NUMBER PRIMARY KEY,
    nombre VARCHAR2(50) NOT NULL,
    anio NUMBER NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    CONSTRAINT uk_temporada_anio UNIQUE (nombre, anio),
    CONSTRAINT chk_temporada_fechas CHECK (fecha_inicio <= fecha_fin)
);
COMMENT ON TABLE TEMPORADA IS 'Periodos de tiempo (Alta, Media, Baja) definidos por año que determinan las tarifas.';

-- 6. TARIFA
CREATE TABLE TARIFA (
    id_tarifa NUMBER PRIMARY KEY,
    id_habitacion NUMBER NOT NULL,
    id_temporada NUMBER NOT NULL,
    precio_noche NUMBER(12, 2) NOT NULL,
    CONSTRAINT uk_tarifa_hab_temp UNIQUE (id_habitacion, id_temporada),
    CONSTRAINT chk_tarifa_precio CHECK (precio_noche > 0),
    CONSTRAINT fk_tarifa_habitacion FOREIGN KEY (id_habitacion) REFERENCES HABITACION(id_habitacion),
    CONSTRAINT fk_tarifa_temporada FOREIGN KEY (id_temporada) REFERENCES TEMPORADA(id_temporada)
);
COMMENT ON TABLE TARIFA IS 'Precio por noche de una habitación específica en una temporada determinada.';

-- 7. CLIENTE
CREATE TABLE CLIENTE (
    id_cliente NUMBER PRIMARY KEY,
    tipo_documento VARCHAR2(5) NOT NULL,
    numero_documento VARCHAR2(20) NOT NULL,
    nombre_completo VARCHAR2(150) NOT NULL,
    correo VARCHAR2(100) NOT NULL,
    telefono VARCHAR2(20),
    ciudad_origen VARCHAR2(100) NOT NULL,
    CONSTRAINT uk_cliente_documento UNIQUE (numero_documento),
    CONSTRAINT uk_cliente_correo UNIQUE (correo)
);
COMMENT ON TABLE CLIENTE IS 'Usuarios registrados que realizan las reservas.';

-- 8. RESERVA
CREATE TABLE RESERVA (
    id_reserva NUMBER PRIMARY KEY,
    id_cliente NUMBER NOT NULL,
    fecha_checkin_global DATE NOT NULL,
    fecha_checkout_global DATE NOT NULL,
    estado VARCHAR2(20) NOT NULL,
    fecha_registro TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_reserva_fechas CHECK (fecha_checkin_global < fecha_checkout_global),
    CONSTRAINT chk_reserva_estado CHECK (estado IN ('pendiente', 'confirmada', 'cancelada', 'completada')),
    CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente)
);
COMMENT ON TABLE RESERVA IS 'Cabecera de la reserva asociada a un cliente, puede contener múltiples habitaciones.';

-- 9. RESERVA_HABITACION
CREATE TABLE RESERVA_HABITACION (
    id_reserva NUMBER NOT NULL,
    id_habitacion NUMBER NOT NULL,
    fecha_in_especifica DATE NOT NULL,
    fecha_out_especifica DATE NOT NULL,
    valor_calculado_estadia NUMBER(12, 2) NOT NULL,
    PRIMARY KEY (id_reserva, id_habitacion),
    CONSTRAINT chk_res_hab_fechas CHECK (fecha_in_especifica < fecha_out_especifica),
    CONSTRAINT fk_reshab_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
    CONSTRAINT fk_reshab_habitacion FOREIGN KEY (id_habitacion) REFERENCES HABITACION(id_habitacion)
);
COMMENT ON TABLE RESERVA_HABITACION IS 'Tabla puente que resuelve la relación muchos a muchos entre reservas y habitaciones.';

-- 10. PAGO
CREATE TABLE PAGO (
    id_pago NUMBER PRIMARY KEY,
    id_reserva NUMBER NOT NULL,
    fecha_pago TIMESTAMP NOT NULL,
    monto NUMBER(12, 2) NOT NULL,
    metodo VARCHAR2(50) NOT NULL,
    estado VARCHAR2(20) NOT NULL,
    CONSTRAINT chk_pago_monto CHECK (monto > 0),
    CONSTRAINT chk_pago_estado CHECK (estado IN ('exitoso', 'fallido', 'pendiente', 'reembolsado')),
    CONSTRAINT fk_pago_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva)
);
COMMENT ON TABLE PAGO IS 'Registro de abonos o pagos totales asociados a una reserva.';

-- 11. SERVICIO
CREATE TABLE SERVICIO (
    id_servicio NUMBER PRIMARY KEY,
    id_alojamiento NUMBER NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    descripcion VARCHAR2(255),
    precio NUMBER(12, 2) NOT NULL,
    CONSTRAINT chk_servicio_precio CHECK (precio >= 0),
    CONSTRAINT fk_servicio_alojamiento FOREIGN KEY (id_alojamiento) REFERENCES ALOJAMIENTO(id_alojamiento)
);
COMMENT ON TABLE SERVICIO IS 'Servicios complementarios ofrecidos por cada alojamiento.';

-- 12. RESERVA_SERVICIO
CREATE TABLE RESERVA_SERVICIO (
    id_reserva NUMBER NOT NULL,
    id_servicio NUMBER NOT NULL,
    cantidad NUMBER DEFAULT 1 NOT NULL,
    precio_unitario_historico NUMBER(12, 2) NOT NULL,
    PRIMARY KEY (id_reserva, id_servicio),
    CONSTRAINT chk_resserv_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_resserv_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
    CONSTRAINT fk_resserv_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio)
);
COMMENT ON TABLE RESERVA_SERVICIO IS 'Servicios complementarios contratados dentro de una reserva.';

-- 13. RESENA
CREATE TABLE RESENA (
    id_resena NUMBER PRIMARY KEY,
    id_cliente NUMBER NOT NULL,
    id_alojamiento NUMBER NOT NULL,
    calificacion NUMBER NOT NULL,
    comentario VARCHAR2(1000),
    fecha_resena TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5),
    CONSTRAINT fk_resena_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    CONSTRAINT fk_resena_alojamiento FOREIGN KEY (id_alojamiento) REFERENCES ALOJAMIENTO(id_alojamiento)
);
COMMENT ON TABLE RESENA IS 'Calificaciones y opiniones dejadas por los clientes tras hospedarse.';

-- 14. USUARIO_SISTEMA
CREATE TABLE USUARIO_SISTEMA (
    id_usuario NUMBER PRIMARY KEY,
    id_alojamiento NUMBER,
    nombre VARCHAR2(150) NOT NULL,
    correo VARCHAR2(100) NOT NULL,
    rol VARCHAR2(50) NOT NULL,
    password_hash VARCHAR2(255) NOT NULL,
    CONSTRAINT uk_usuario_correo UNIQUE (correo),
    CONSTRAINT chk_usuario_rol CHECK (rol IN ('admin_plataforma', 'encargado_alojamiento', 'recepcion', 'gerencia')),
    CONSTRAINT fk_usuario_alojamiento FOREIGN KEY (id_alojamiento) REFERENCES ALOJAMIENTO(id_alojamiento)
);
COMMENT ON TABLE USUARIO_SISTEMA IS 'Usuarios internos del sistema (administradores y encargados de alojamientos).';

COMMIT;