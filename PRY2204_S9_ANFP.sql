/* ==========================================================
   EFT Semana 9 - Modelamiento de Bases de Datos
   Caso: ANFP (Asociacion Nacional de Futbol Profesional)
 

/* ------------------------------------------------------------
   1) CREACION DE TABLAS (de las independientes a las dependientes)
   ------------------------------------------------------------ */

-- REGION
CREATE TABLE region (
    id_region  NUMBER(2)    NOT NULL,
    nombre     VARCHAR2(60) NOT NULL,
    CONSTRAINT pk_region PRIMARY KEY (id_region)
);

-- COMUNA (cada comuna pertenece a una region)
CREATE TABLE comuna (
    id_comuna  NUMBER(4)    NOT NULL,
    id_region  NUMBER(2)    NOT NULL,
    nombre     VARCHAR2(60) NOT NULL,
    CONSTRAINT pk_comuna PRIMARY KEY (id_comuna),
    CONSTRAINT fk_comuna_region FOREIGN KEY (id_region)
        REFERENCES region (id_region)
);

-- ASOCIACION: la fecha de creacion debe ser del 31-12-1980 en adelante
CREATE TABLE asociacion (
    id_asociacion      NUMBER(3)    NOT NULL,
    nombre_asociacion  VARCHAR2(80) NOT NULL,
    fecha_creacion     DATE         NOT NULL,
    tipo_asociacion    CHAR(1)      DEFAULT 'P' NOT NULL,
    CONSTRAINT pk_asociacion PRIMARY KEY (id_asociacion),
    CONSTRAINT ck_asociacion_fecha CHECK (fecha_creacion >= DATE '1980-12-31'),
    CONSTRAINT ck_asociacion_tipo CHECK (tipo_asociacion IN ('P', 'A'))   -- P = profesional, A = amateur
);

-- NACIONALIDAD: la PK es autoincremental, parte en 210 y sube de 2 en 2
CREATE TABLE nacionalidad (
    id_nacion    NUMBER(4) GENERATED ALWAYS AS IDENTITY (START WITH 210 INCREMENT BY 2) NOT NULL,
    descripcion  VARCHAR2(40) NOT NULL,
    CONSTRAINT pk_nacionalidad PRIMARY KEY (id_nacion),
    CONSTRAINT un_nacionalidad_descripcion UNIQUE (descripcion)
);

-- Secuencia para el codigo del club: parte en 703 y sube de 4 en 4
CREATE SEQUENCE seq_club_futbol
    START WITH 703
    INCREMENT BY 4
    NOCACHE
    NOCYCLE;

-- CLUB_FUTBOL: el nombre del club no se puede repetir
CREATE TABLE club_futbol (
    id_club          NUMBER(5)    NOT NULL,
    nombre_club      VARCHAR2(60) NOT NULL,
    patrimonio       NUMBER(15)   DEFAULT 0 NOT NULL,
    ubicacion_calle  VARCHAR2(100) NOT NULL,
    tipo_club        VARCHAR2(11) DEFAULT 'Profesional' NOT NULL,
    CONSTRAINT pk_club_futbol PRIMARY KEY (id_club),
    CONSTRAINT un_club_futbol_nombre UNIQUE (nombre_club),
    CONSTRAINT ck_club_futbol_patrimonio CHECK (patrimonio >= 0),
    CONSTRAINT ck_club_futbol_tipo CHECK (tipo_club IN ('Profesional', 'Amateur'))
);

-- ESCUELA_FUTBOL (escuelas donde se formaron los jugadores)
CREATE TABLE escuela_futbol (
    id_escuela        NUMBER(5)    NOT NULL,
    nombre_escuela    VARCHAR2(80) NOT NULL,
    capacidad         NUMBER(6)    NOT NULL,
    fecha_fundacion   DATE         NOT NULL,
    CONSTRAINT pk_escuela_futbol PRIMARY KEY (id_escuela),
    CONSTRAINT ck_escuela_futbol_capacidad CHECK (capacidad > 0)
);

-- IDIOMA
CREATE TABLE idioma (
    id_idioma      NUMBER(3) GENERATED ALWAYS AS IDENTITY NOT NULL,
    nombre_idioma  VARCHAR2(40) NOT NULL,
    CONSTRAINT pk_idioma PRIMARY KEY (id_idioma),
    CONSTRAINT un_idioma_nombre UNIQUE (nombre_idioma)
);

-- TRABAJADOR (supertipo): datos comunes de jugadores y personal de planta
CREATE TABLE trabajador (
    cod_inscripcion  NUMBER(9)     NOT NULL,
    numrut           NUMBER(8)     NOT NULL,
    dvrut            CHAR(1)       NOT NULL,
    nombres          VARCHAR2(60)  NOT NULL,
    apellidos        VARCHAR2(60)  NOT NULL,
    sueldo_base      NUMBER(9)     DEFAULT 0 NOT NULL,
    fecha_nacimiento DATE          NOT NULL,
    genero           CHAR(1)       NOT NULL,
    estado_civil     VARCHAR2(12)  NOT NULL,
    telefono_movil   VARCHAR2(15)  NOT NULL,
    email            VARCHAR2(100),
    direccion        VARCHAR2(100) NOT NULL,
    id_comuna        NUMBER(4)     NOT NULL,
    CONSTRAINT pk_trabajador PRIMARY KEY (cod_inscripcion),
    CONSTRAINT un_trabajador_rut UNIQUE (numrut, dvrut),
    CONSTRAINT ck_trabajador_dvrut CHECK (dvrut IN ('0','1','2','3','4','5','6','7','8','9','K')),
    CONSTRAINT ck_trabajador_sueldo CHECK (sueldo_base >= 0),
    CONSTRAINT ck_trabajador_genero CHECK (genero IN ('M', 'F')),
    CONSTRAINT ck_trabajador_estado_civil CHECK (estado_civil IN ('Soltero', 'Casado', 'Divorciado', 'Viudo')),
    CONSTRAINT fk_trabajador_comuna FOREIGN KEY (id_comuna)
        REFERENCES comuna (id_comuna)
);

-- JUGADOR (subtipo de TRABAJADOR): comparte la misma clave
-- La escuela y el anio en que dejo el amateurismo pueden quedar vacios,
-- pero si viene uno debe venir el otro.
CREATE TABLE jugador (
    cod_inscripcion      NUMBER(9)    NOT NULL,
    puesto               VARCHAR2(20) NOT NULL,
    monto_total_premios  NUMBER(12)   DEFAULT 0 NOT NULL,
    id_asociacion        NUMBER(3)    NOT NULL,
    id_escuela           NUMBER(5),
    anio_fin_amateur     NUMBER(4),
    CONSTRAINT pk_jugador PRIMARY KEY (cod_inscripcion),
    CONSTRAINT fk_jugador_trabajador FOREIGN KEY (cod_inscripcion)
        REFERENCES trabajador (cod_inscripcion),
    CONSTRAINT fk_jugador_asociacion FOREIGN KEY (id_asociacion)
        REFERENCES asociacion (id_asociacion),
    CONSTRAINT fk_jugador_escuela FOREIGN KEY (id_escuela)
        REFERENCES escuela_futbol (id_escuela),
    CONSTRAINT ck_jugador_puesto CHECK (puesto IN ('Arquero', 'Defensa', 'Mediocampista', 'Delantero')),
    CONSTRAINT ck_jugador_premios CHECK (monto_total_premios >= 0),
    CONSTRAINT ck_jugador_escuela_anio CHECK (
        (id_escuela IS NULL AND anio_fin_amateur IS NULL)
        OR (id_escuela IS NOT NULL AND anio_fin_amateur IS NOT NULL))
);

-- PERSONAL_PLANTA (subtipo de TRABAJADOR): pertenece a un club
CREATE TABLE personal_planta (
    cod_inscripcion   NUMBER(9)   NOT NULL,
    id_club           NUMBER(5)   NOT NULL,
    horas_trabajadas  NUMBER(5,1),
    valor_hora_extra  NUMBER(8),
    CONSTRAINT pk_personal_planta PRIMARY KEY (cod_inscripcion),
    CONSTRAINT fk_personal_planta_trabajador FOREIGN KEY (cod_inscripcion)
        REFERENCES trabajador (cod_inscripcion),
    CONSTRAINT fk_personal_planta_club FOREIGN KEY (id_club)
        REFERENCES club_futbol (id_club),
    CONSTRAINT ck_personal_planta_horas CHECK (horas_trabajadas >= 0),
    CONSTRAINT ck_personal_planta_valor CHECK (valor_hora_extra >= 0)
);

-- JUGADOR_CLUB: historial de los clubes por los que ha pasado cada jugador
CREATE TABLE jugador_club (
    cod_inscripcion  NUMBER(9) NOT NULL,
    id_club          NUMBER(5) NOT NULL,
    fecha_inicio     DATE      NOT NULL,
    fecha_termino    DATE,
    CONSTRAINT pk_jugador_club PRIMARY KEY (cod_inscripcion, id_club, fecha_inicio),
    CONSTRAINT fk_jugador_club_jugador FOREIGN KEY (cod_inscripcion)
        REFERENCES jugador (cod_inscripcion),
    CONSTRAINT fk_jugador_club_club FOREIGN KEY (id_club)
        REFERENCES club_futbol (id_club),
    CONSTRAINT ck_jugador_club_fechas CHECK (fecha_termino IS NULL OR fecha_termino >= fecha_inicio)
);

-- Un jugador solo puede tener un periodo abierto (club actual) a la vez
CREATE UNIQUE INDEX un_jugador_club_vigente
    ON jugador_club (CASE WHEN fecha_termino IS NULL THEN cod_inscripcion END);

-- JUGADOR_IDIOMA: idiomas que domina cada jugador y su nivel
CREATE TABLE jugador_idioma (
    cod_inscripcion  NUMBER(9)    NOT NULL,
    id_idioma        NUMBER(3)    NOT NULL,
    nivel_dominio    VARCHAR2(12) NOT NULL,
    CONSTRAINT pk_jugador_idioma PRIMARY KEY (cod_inscripcion, id_idioma),
    CONSTRAINT fk_jugador_idioma_jugador FOREIGN KEY (cod_inscripcion)
        REFERENCES jugador (cod_inscripcion),
    CONSTRAINT fk_jugador_idioma_idioma FOREIGN KEY (id_idioma)
        REFERENCES idioma (id_idioma),
    CONSTRAINT ck_jugador_idioma_nivel CHECK (nivel_dominio IN ('Basico', 'Intermedio', 'Avanzado', 'Nativo'))
);

-- JUGADOR_NACIONALIDAD: un jugador puede tener mas de una nacionalidad
CREATE TABLE jugador_nacionalidad (
    cod_inscripcion  NUMBER(9) NOT NULL,
    id_nacion        NUMBER(4) NOT NULL,
    CONSTRAINT pk_jugador_nacionalidad PRIMARY KEY (cod_inscripcion, id_nacion),
    CONSTRAINT fk_jugador_nacionalidad_jugador FOREIGN KEY (cod_inscripcion)
        REFERENCES jugador (cod_inscripcion),
    CONSTRAINT fk_jugador_nacionalidad_nacion FOREIGN KEY (id_nacion)
        REFERENCES nacionalidad (id_nacion)
);


/* ------------------------------------------------------------
   2) POBLAMIENTO (respetando el orden de dependencia)
   ------------------------------------------------------------ */

-- REGION

INSERT INTO region (id_region, nombre) VALUES (1, 'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO region (id_region, nombre) VALUES (2, 'ANTOFAGASTA');
INSERT INTO region (id_region, nombre) VALUES (3, 'ATACAMA Y COQUIMBO');
INSERT INTO region (id_region, nombre) VALUES (5, 'VALPARAISO');
INSERT INTO region (id_region, nombre) VALUES (8, 'BIOBIO');
INSERT INTO region (id_region, nombre) VALUES (13, 'METROPOLITANA');
INSERT INTO region (id_region, nombre) VALUES (16, 'NUBLE');

-- COMUNA
INSERT INTO comuna (id_comuna, id_region, nombre) VALUES (101, 13, 'Santiago');
INSERT INTO comuna (id_comuna, id_region, nombre) VALUES (102, 5, 'Valparaíso');
INSERT INTO comuna (id_comuna, id_region, nombre) VALUES (103, 8, 'Concepción');
INSERT INTO comuna (id_comuna, id_region, nombre) VALUES (104, 2, 'Antofagasta');
INSERT INTO comuna (id_comuna, id_region, nombre) VALUES (105, 16, 'Chillán');

-- ASOCIACION
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (25, 'Asociación de Fútbol de Santiago', TO_DATE('15-05-2001', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (26, 'Asociación Nacional de Fútbol Amateur', TO_DATE('10-03-1998', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (27, 'Asociación de Fútbol de Valparaíso', TO_DATE('21-07-1987', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (28, 'Asociación de Fútbol de Concepción', TO_DATE('30-11-1995', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (29, 'Asociación de Fútbol de Antofagasta', TO_DATE('25-06-2003', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (30, 'Asociación de Fútbol de Temuco', TO_DATE('12-01-2010', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (31, 'Asociación de Fútbol de Rancagua', TO_DATE('08-09-1999', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (32, 'Asociación de Fútbol de Puerto Montt', TO_DATE('20-04-2005', 'DD-MM-YYYY'), 'A');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (33, 'Asociación de Fútbol de La Serena', TO_DATE('14-08-2012', 'DD-MM-YYYY'), 'P');
INSERT INTO asociacion (id_asociacion, nombre_asociacion, fecha_creacion, tipo_asociacion)
    VALUES (34, 'Asociación de Fútbol de Chillán', TO_DATE('01-12-2018', 'DD-MM-YYYY'), 'A');

-- NACIONALIDAD (no se escribe el id: lo genera la columna IDENTITY, 210, 212, 214...)
INSERT INTO nacionalidad (descripcion) VALUES ('Chilena');
INSERT INTO nacionalidad (descripcion) VALUES ('Argentina');
INSERT INTO nacionalidad (descripcion) VALUES ('Peruana');
INSERT INTO nacionalidad (descripcion) VALUES ('Boliviana');
INSERT INTO nacionalidad (descripcion) VALUES ('Brasileña');

-- CLUB_FUTBOL (el codigo sale de la secuencia: 703, 707, 711...)
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
    VALUES (seq_club_futbol.NEXTVAL, 'Colo-Colo', 500000000, 'Av. Marathon 5300', 'Profesional');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
    VALUES (seq_club_futbol.NEXTVAL, 'Universidad de Chile', 450000000, 'Av. El Parrón 0931', 'Profesional');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
    VALUES (seq_club_futbol.NEXTVAL, 'Deportes Antofagasta', 180000000, 'Avenida Angamos 01606', 'Profesional');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
    VALUES (seq_club_futbol.NEXTVAL, 'Huachipato', 220000000, 'Avenida Desiderio García 909', 'Profesional');
INSERT INTO club_futbol (id_club, nombre_club, patrimonio, ubicacion_calle, tipo_club)
    VALUES (seq_club_futbol.NEXTVAL, 'Ñublense', 170000000, 'Avenida Pedro Aguirre Cerda 1003', 'Profesional');

COMMIT;


/* ------------------------------------------------------------
   3) CONSULTAS
   ------------------------------------------------------------ */

-- Informe 1: asociaciones profesionales creadas despues del anio 2000,
-- de la mas nueva a la mas antigua
SELECT 'ID:' || id_asociacion || ' * ' || nombre_asociacion AS "ASOCIACION",
       fecha_creacion                                      AS "CREADA",
       tipo_asociacion                                     AS "TIPO"
FROM   asociacion
WHERE  tipo_asociacion = 'P'
AND    EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER BY fecha_creacion DESC;

-- Informe 2: patrimonio de los clubes en pesos y en dolares (tipo de cambio $955)
-- Solo clubes profesionales con una "a" en el nombre y patrimonio sobre $200.000.000
SELECT id_club                 AS "CLUB",
       nombre_club             AS "NOMBRE CLUB",
       patrimonio              AS "PATRIMONIO EN PESOS",
       patrimonio / 955        AS "PATRIMONIO EN DOLARES"
FROM   club_futbol
WHERE  UPPER(nombre_club) LIKE '%A%'
AND    patrimonio > 200000000
AND    tipo_club = 'Profesional'
ORDER BY id_club DESC;
