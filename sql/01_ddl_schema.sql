
-- ============================================================
--  GÉNERO
-- ============================================================
CREATE TABLE GENERO (
    id_genero   INT            NOT NULL AUTO_INCREMENT,
    nombre      VARCHAR(60)    NOT NULL,
    descripcion VARCHAR(255),
    CONSTRAINT pk_genero     PRIMARY KEY (id_genero),
    CONSTRAINT uq_genero_nom UNIQUE (nombre)
);

-- ============================================================
--  AUTOR
-- ============================================================
CREATE TABLE AUTOR (
    id_autor     INT           NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(80)   NOT NULL,
    apellido     VARCHAR(80)   NOT NULL,
    nacionalidad VARCHAR(60),
    CONSTRAINT pk_autor PRIMARY KEY (id_autor)
);

-- ============================================================
--  LIBRO
-- ============================================================
CREATE TABLE LIBRO (
    isbn              VARCHAR(20)   NOT NULL,
    titulo            VARCHAR(200)  NOT NULL,
    anio_publicacion  YEAR          NOT NULL,
    stock_total       SMALLINT      NOT NULL DEFAULT 1,
    stock_disponible  SMALLINT      NOT NULL DEFAULT 1,
    CONSTRAINT pk_libro                PRIMARY KEY (isbn),
    CONSTRAINT chk_stock_total_pos     CHECK (stock_total >= 0),
    CONSTRAINT chk_stock_disp_pos      CHECK (stock_disponible >= 0),
    CONSTRAINT chk_stock_disp_lte_tot  CHECK (stock_disponible <= stock_total),
    CONSTRAINT chk_anio_pub            CHECK (anio_publicacion BETWEEN 1000 AND 2100)
);

CREATE INDEX idx_libro_titulo ON LIBRO (titulo);

-- ============================================================
--  LIBRO_AUTOR  (N:M)
-- ============================================================
CREATE TABLE LIBRO_AUTOR (
    isbn      VARCHAR(20) NOT NULL,
    id_autor  INT         NOT NULL,
    CONSTRAINT pk_libro_autor  PRIMARY KEY (isbn, id_autor),
    CONSTRAINT fk_la_isbn      FOREIGN KEY (isbn)     REFERENCES LIBRO (isbn)
                               ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_la_autor     FOREIGN KEY (id_autor) REFERENCES AUTOR (id_autor)
                               ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
--  LIBRO_GENERO  (N:M)
-- ============================================================
CREATE TABLE LIBRO_GENERO (
    isbn       VARCHAR(20) NOT NULL,
    id_genero  INT         NOT NULL,
    CONSTRAINT pk_libro_genero PRIMARY KEY (isbn, id_genero),
    CONSTRAINT fk_lg_isbn      FOREIGN KEY (isbn)      REFERENCES LIBRO (isbn)
                               ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_lg_genero    FOREIGN KEY (id_genero) REFERENCES GENERO (id_genero)
                               ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
--  SOCIO
-- ============================================================
CREATE TABLE SOCIO (
    id_socio   INT          NOT NULL AUTO_INCREMENT,
    dni        VARCHAR(15)  NOT NULL,
    nombre     VARCHAR(80)  NOT NULL,
    apellido   VARCHAR(80)  NOT NULL,
    email      VARCHAR(120) NOT NULL,
    fecha_alta DATE         NOT NULL DEFAULT (CURRENT_DATE),
    estado     VARCHAR(12)  NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_socio        PRIMARY KEY (id_socio),
    CONSTRAINT uq_socio_dni    UNIQUE (dni),
    CONSTRAINT uq_socio_email  UNIQUE (email),
    CONSTRAINT chk_socio_estado
        CHECK (estado IN ('ACTIVO', 'SUSPENDIDO', 'BAJA'))
);

CREATE INDEX idx_socio_dni   ON SOCIO (dni);
CREATE INDEX idx_socio_email ON SOCIO (email);

-- ============================================================
--  EJEMPLAR
-- ============================================================
CREATE TABLE EJEMPLAR (
    id_ejemplar   INT          NOT NULL AUTO_INCREMENT,
    isbn          VARCHAR(20)  NOT NULL,
    nro_ejemplar  SMALLINT     NOT NULL,
    estado_fisico VARCHAR(12)  NOT NULL DEFAULT 'BUENO',
    CONSTRAINT pk_ejemplar        PRIMARY KEY (id_ejemplar),
    CONSTRAINT uq_ejemplar_isbn_nro UNIQUE (isbn, nro_ejemplar),
    CONSTRAINT fk_ejemplar_isbn   FOREIGN KEY (isbn) REFERENCES LIBRO (isbn)
                                  ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_estado_fisico
        CHECK (estado_fisico IN ('BUENO', 'DETERIORADO', 'BAJA'))
);

CREATE INDEX idx_ejemplar_isbn ON EJEMPLAR (isbn);

-- ============================================================
--  PRÉSTAMO
-- ============================================================
CREATE TABLE PRESTAMO (
    id_prestamo       INT         NOT NULL AUTO_INCREMENT,
    id_socio          INT         NOT NULL,
    id_ejemplar       INT         NOT NULL,
    fecha_prestamo    DATE        NOT NULL DEFAULT (CURRENT_DATE),
    fecha_vencimiento DATE        NOT NULL,
    fecha_devolucion  DATE,
    estado            VARCHAR(12) NOT NULL DEFAULT 'ACTIVO',
    CONSTRAINT pk_prestamo   PRIMARY KEY (id_prestamo),
    CONSTRAINT fk_prest_socio    FOREIGN KEY (id_socio)    REFERENCES SOCIO (id_socio)
                                 ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_prest_ejemplar FOREIGN KEY (id_ejemplar) REFERENCES EJEMPLAR (id_ejemplar)
                                 ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_prestamo_estado
        CHECK (estado IN ('ACTIVO', 'DEVUELTO', 'VENCIDO')),
    CONSTRAINT chk_venc_after_prest
        CHECK (fecha_vencimiento > fecha_prestamo),
    CONSTRAINT chk_devol_after_prest
        CHECK (fecha_devolucion IS NULL OR fecha_devolucion >= fecha_prestamo)
);

CREATE INDEX idx_prestamo_socio    ON PRESTAMO (id_socio);
CREATE INDEX idx_prestamo_ejemplar ON PRESTAMO (id_ejemplar);
CREATE INDEX idx_prestamo_estado   ON PRESTAMO (estado);

-- ============================================================
--  SANCION
-- ============================================================
CREATE TABLE SANCION (
    id_sancion   INT          NOT NULL AUTO_INCREMENT,
    id_socio     INT          NOT NULL,
    tipo         VARCHAR(20)  NOT NULL DEFAULT 'MORA',
    fecha_inicio DATE         NOT NULL DEFAULT (CURRENT_DATE),
    fecha_fin    DATE         NOT NULL,
    motivo       VARCHAR(255),
    CONSTRAINT pk_sancion      PRIMARY KEY (id_sancion),
    CONSTRAINT fk_sancion_socio FOREIGN KEY (id_socio) REFERENCES SOCIO (id_socio)
                                ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_sancion_tipo
        CHECK (tipo IN ('MORA', 'DAÑO', 'PERDIDA', 'OTRO')),
    CONSTRAINT chk_sancion_fin
        CHECK (fecha_fin >= fecha_inicio)
);

CREATE INDEX idx_sancion_socio ON SANCION (id_socio);

-- ============================================================
--  AUDITORÍA DE PRÉSTAMOS
-- ============================================================
CREATE TABLE AUDITORIA_PRESTAMOS (
    id_audit      INT          NOT NULL AUTO_INCREMENT,
    id_prestamo   INT          NOT NULL,
    operacion     VARCHAR(10)  NOT NULL,          -- INSERT / UPDATE / DELETE
    estado_nuevo  VARCHAR(12),
    estado_viejo  VARCHAR(12),
    usuario_bd    VARCHAR(80)  NOT NULL DEFAULT (CURRENT_USER()),
    fecha_hora    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_audit PRIMARY KEY (id_audit),
    CONSTRAINT chk_audit_op CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);
