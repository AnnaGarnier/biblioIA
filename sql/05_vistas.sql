CREATE OR REPLACE VIEW v_catalogo_libros AS
SELECT
l.isbn,
l.titulo,
l.anio_publicacion,
l.stock_total,
l.stock_disponible,
GROUP_CONCAT(DISTINCT CONCAT(a.nombre, ' ', a.apellido) -- use ese group concat para q no se
ORDER BY a.apellido SEPARATOR ', ') AS autores, -- repitan,si tal libro tiene 2 géneros y 1 autor
GROUP_CONCAT(DISTINCT g.nombre  -- ibamos a ver 2 filas para ese libro, con group concat no
ORDER BY g.nombre SEPARATOR ', ') AS generos
FROM LIBRO l
LEFT JOIN LIBRO_AUTOR la ON la.isbn = l.isbn
LEFT JOIN AUTOR a ON a.id_autor = la.id_autor
LEFT JOIN LIBRO_GENERO lg ON lg.isbn = l.isbn
LEFT JOIN GENERO g ON g.id_genero = lg.id_genero
GROUP BY l.isbn, l.titulo, l.anio_publicacion, l.stock_total, l.stock_disponible;

CREATE OR REPLACE VIEW v_libros_disponibles AS
SELECT
l.isbn,
l.titulo,
l.stock_disponible,
GROUP_CONCAT(DISTINCT g.nombre ORDER BY g.nombre SEPARATOR ', ') AS generos,
GROUP_CONCAT(DISTINCT CONCAT(a.nombre, ' ', a.apellido) 
ORDER BY a.apellido SEPARATOR ', ') AS autores
FROM LIBRO l
JOIN LIBRO_GENERO lg ON lg.isbn = l.isbn
JOIN GENERO g ON g.id_genero = lg.id_genero
JOIN LIBRO_AUTOR la ON la.isbn = l.isbn
JOIN AUTOR a ON a.id_autor = la.id_autor
WHERE l.stock_disponible > 0
AND EXISTS (
SELECT 1 FROM EJEMPLAR e
WHERE e.isbn = l.isbn
AND e.estado_fisico IN ('BUENO', 'DETERIORADO')
)
GROUP BY l.isbn, l.titulo, l.stock_disponible;

CREATE OR REPLACE VIEW v_prestamos_activos AS
SELECT
p.id_prestamo,
s.id_socio,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
s.email,
l.isbn,
l.titulo,
e.nro_ejemplar,
p.fecha_prestamo,
p.fecha_vencimiento,
DATEDIFF(CURDATE(), p.fecha_vencimiento) AS dias_vencido
FROM PRESTAMO p
JOIN SOCIO s ON s.id_socio = p.id_socio
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
JOIN LIBRO l ON l.isbn = e.isbn
WHERE p.estado = 'ACTIVO';

CREATE OR REPLACE VIEW v_prestamos_vencidos AS
SELECT
p.id_prestamo,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
l.titulo,
p.fecha_prestamo,
p.fecha_vencimiento,
DATEDIFF(CURDATE(), p.fecha_vencimiento) AS dias_de_mora
FROM PRESTAMO p
JOIN SOCIO s ON s.id_socio = p.id_socio
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
JOIN LIBRO l ON l.isbn = e.isbn
WHERE p.estado = 'VENCIDO'
AND p.fecha_devolucion IS NULL;

CREATE OR REPLACE VIEW v_socios_sancionados AS
SELECT
s.id_socio,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
s.estado,
sa.tipo,
sa.fecha_inicio,
sa.fecha_fin,
sa.motivo,
DATEDIFF(sa.fecha_fin, CURDATE()) AS dias_restantes
FROM SOCIO s
JOIN SANCION sa ON sa.id_socio = s.id_socio
WHERE CURDATE() BETWEEN sa.fecha_inicio AND sa.fecha_fin;

CREATE OR REPLACE VIEW v_libros_mas_prestados AS
SELECT
l.isbn,
l.titulo,
GROUP_CONCAT(DISTINCT CONCAT(a.nombre, ' ', a.apellido)
ORDER BY a.apellido SEPARATOR ', ') AS autores,
COUNT(p.id_prestamo) AS total_prestamos
FROM PRESTAMO p
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
JOIN LIBRO l ON l.isbn = e.isbn
JOIN LIBRO_AUTOR la ON la.isbn = l.isbn
JOIN AUTOR a ON a.id_autor = la.id_autor
GROUP BY l.isbn, l.titulo
ORDER BY total_prestamos DESC;

CREATE OR REPLACE VIEW v_historial_socios AS
SELECT
s.id_socio,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
l.isbn,
l.titulo,
p.fecha_prestamo,
p.fecha_vencimiento,
p.fecha_devolucion,
p.estado AS estado_prestamo
FROM PRESTAMO p
JOIN SOCIO s ON s.id_socio = p.id_socio
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
JOIN LIBRO l ON l.isbn = e.isbn
ORDER BY s.id_socio, p.fecha_prestamo DESC;

CREATE OR REPLACE VIEW v_autores_prolíficos AS
SELECT
a.id_autor,
CONCAT(a.nombre, ' ', a.apellido) AS autor,
a.nacionalidad,
COUNT(la.isbn) AS cantidad_libros
FROM AUTOR a
JOIN LIBRO_AUTOR la ON la.id_autor = a.id_autor
GROUP BY a.id_autor, a.nombre, a.apellido, a.nacionalidad
HAVING COUNT(la.isbn) > 1
ORDER BY cantidad_libros DESC;

CREATE OR REPLACE VIEW v_generos_por_socio AS
SELECT DISTINCT
s.id_socio,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
g.id_genero,
g.nombre AS genero
FROM SOCIO s
JOIN PRESTAMO p ON p.id_socio = s.id_socio
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
JOIN LIBRO_GENERO lg ON lg.isbn = e.isbn
JOIN GENERO g ON g.id_genero = lg.id_genero;

CREATE OR REPLACE VIEW v_autores_por_socio AS
SELECT DISTINCT
s.id_socio,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
a.id_autor,
CONCAT(a.nombre, ' ', a.apellido) AS autor
FROM SOCIO s
JOIN PRESTAMO p ON p.id_socio = s.id_socio
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
JOIN LIBRO_AUTOR la ON la.isbn = e.isbn
JOIN AUTOR a ON a.id_autor = la.id_autor;

CREATE OR REPLACE VIEW v_libros_no_leidos_por_socio AS
SELECT
s.id_socio,
s.dni,
CONCAT(s.nombre, ' ', s.apellido) AS socio,
l.isbn,
l.titulo,
l.stock_disponible
FROM SOCIO s
JOIN LIBRO l ON l.stock_disponible > 0
WHERE NOT EXISTS (
SELECT 1
FROM PRESTAMO p
JOIN EJEMPLAR e ON e.id_ejemplar = p.id_ejemplar
WHERE p.id_socio = s.id_socio
AND e.isbn = l.isbn
);