CREATE DATABASE BibliotecaUniversitaria;
GO

USE BibliotecaUniversitaria;
GO


-- ============================================
-- TABLA LIBRO
-- ============================================

CREATE TABLE Libro
(
    IdLibro INT IDENTITY(1,1) PRIMARY KEY,
    Titulo VARCHAR(150) NOT NULL,
    EjemplaresTotales INT NOT NULL,
    EjemplaresDisponibles INT NOT NULL
);
GO


-- ============================================
-- TABLA SOCIO
-- ============================================

CREATE TABLE Socio
(
    IdSocio INT IDENTITY(1,1) PRIMARY KEY,
    NomSocio VARCHAR(100) NOT NULL,
    MaxPrestamosSimultaneos INT NOT NULL
);
GO


-- ============================================
-- TABLA PRESTAMO
-- ============================================

CREATE TABLE Prestamo
(
    IdPrestamo INT IDENTITY(1,1) PRIMARY KEY,
    IdLibro INT NOT NULL,
    IdSocio INT NOT NULL,
    FechaPrestamo DATETIME NOT NULL,
    FechaDevolucion DATETIME NULL,

    CONSTRAINT FK_Prestamo_Libro
        FOREIGN KEY (IdLibro)
        REFERENCES Libro(IdLibro),

    CONSTRAINT FK_Prestamo_Socio
        FOREIGN KEY (IdSocio)
        REFERENCES Socio(IdSocio)
);
GO


-- ============================================
-- INSERTAR LIBROS
-- ============================================

INSERT INTO Libro
(Titulo, EjemplaresTotales, EjemplaresDisponibles)
VALUES
('Programacion en Python', 3, 3),
('Bases de Datos', 2, 2),
('Redes de Computadoras', 1, 1),
('Sistemas Operativos', 4, 4),
('Ingenieria de Software', 3, 3);
GO


-- ============================================
-- INSERTAR SOCIOS
-- ============================================

INSERT INTO Socio
(NomSocio, MaxPrestamosSimultaneos)
VALUES
('Ana Torres', 3),
('Luis Quispe', 2),
('Maria Flores', 1),
('Carlos Mendoza', 2);
GO


-- ============================================
-- INSERTAR PRESTAMOS DE PRUEBA
-- ============================================

INSERT INTO Prestamo
(IdLibro, IdSocio, FechaPrestamo, FechaDevolucion)
VALUES
(1, 1, '2026-09-10', '2026-09-15'),
(2, 2, '2026-09-12', '2026-09-18'),
(3, 3, '2026-09-20', NULL);
GO


-- ============================================
-- MOSTRAR DATOS
-- ============================================

SELECT * FROM Libro;
SELECT * FROM Socio;
SELECT * FROM Prestamo;
GO

-- 1
CREATE TRIGGER trg_DevolverEjemplar
ON Prestamo
AFTER UPDATE
AS
BEGIN

    UPDATE l

    SET l.EjemplaresDisponibles =
        l.EjemplaresDisponibles + x.Cantidad

    FROM Libro l

    INNER JOIN
    (
        SELECT
            d.IdLibro,
            COUNT(*) AS Cantidad

        FROM deleted d

        INNER JOIN inserted i
            ON d.IdPrestamo = i.IdPrestamo

        WHERE
            d.FechaDevolucion IS NULL
            AND i.FechaDevolucion IS NOT NULL

        GROUP BY d.IdLibro

    ) x
        ON l.IdLibro = x.IdLibro;

END;
GO
-- Primero revisa el libro 1
SELECT * 
FROM Libro
WHERE IdLibro = 1;

-- Ahora registra un préstamo:
INSERT INTO Prestamo
(IdLibro, IdSocio, FechaPrestamo, FechaDevolucion)
VALUES
(1, 1, GETDATE(), NULL);

-- Vuelve a consultar:
SELECT * FROM Libro
WHERE IdLibro = 1;

--También verifica que el préstamo se creó:
SELECT * FROM Prestamo;

-- ==================================================
-- EJERCICIO 2
-- AUMENTAR EJEMPLARES CUANDO SE DEVUELVE EL LIBRO
-- ==================================================

CREATE TRIGGER trg_DevolverEjemplar
ON Prestamo
AFTER UPDATE
AS
BEGIN

    UPDATE l

    SET l.EjemplaresDisponibles =
        l.EjemplaresDisponibles + x.Cantidad

    FROM Libro l

    INNER JOIN
    (
        SELECT
            d.IdLibro,
            COUNT(*) AS Cantidad

        FROM deleted d

        INNER JOIN inserted i
            ON d.IdPrestamo = i.IdPrestamo

        WHERE
            d.FechaDevolucion IS NULL
            AND i.FechaDevolucion IS NOT NULL

        GROUP BY d.IdLibro

    ) x
        ON l.IdLibro = x.IdLibro;

END;
GO

-- Prueba de los ejercicios 
SELECT * FROM Libro
WHERE IdLibro = 2;

-- Ahora hacemos un préstamo y guardamos su ID:
DECLARE @IdPrestamo INT;

INSERT INTO Prestamo
(IdLibro, IdSocio, FechaPrestamo, FechaDevolucion)
VALUES
(2, 1, GETDATE(), NULL);

SET @IdPrestamo = SCOPE_IDENTITY();

SELECT @IdPrestamo AS PrestamoCreado;
--Después del préstamo revisa el libro:
SELECT * FROM Libro
WHERE IdLibro = 2;

-- Ahora registra la devolución:
UPDATE Prestamo
SET FechaDevolucion = GETDATE()
WHERE IdPrestamo = @IdPrestamo;
--Y vuelve a consultar:
SELECT *
FROM Libro
WHERE IdLibro = 2;
--También puedes ver el préstamo:
SELECT * FROM Prestamo
WHERE IdPrestamo = @IdPrestamo;
-- Ahora FechaDevolucion ya no debe aparecer como NULL.

-- ==================================================
-- EJERCICIO 3
-- LIMITAR PRESTAMOS SIMULTANEOS
-- ==================================================

CREATE TRIGGER trg_LimitePrestamos
ON Prestamo
AFTER INSERT
AS
BEGIN

    IF EXISTS
    (
        SELECT 1

        FROM Socio s

        INNER JOIN
        (
            SELECT DISTINCT IdSocio

            FROM inserted

            WHERE FechaDevolucion IS NULL

        ) i
            ON s.IdSocio = i.IdSocio

        WHERE
        (
            SELECT COUNT(*)

            FROM Prestamo p

            WHERE p.IdSocio = s.IdSocio
            AND p.FechaDevolucion IS NULL

        ) > s.MaxPrestamosSimultaneos
    )
    BEGIN

        ROLLBACK TRANSACTION;

        THROW 50002,
        'ERROR: El socio alcanzo el numero maximo de prestamos simultaneos.',
        1;

    END;

END;
GO
--- Probamos 
-- seleccionamos el socio de id 3
SELECT * FROM Socio
WHERE IdSocio = 3;
-- Ahora revisa sus préstamos activos:
SELECT *
FROM Prestamo
WHERE IdSocio = 3
AND FechaDevolucion IS NULL;

--Primero revisa que el libro 4 tenga disponibilidad:
SELECT * FROM Libro
WHERE IdLibro = 4;
-- Ahora intenta hacer otro préstamo:
INSERT INTO Prestamo
(IdLibro, IdSocio, FechaPrestamo, FechaDevolucion)
VALUES
(4, 3, GETDATE(), NULL);

-- Ahora comprueba que María sigue teniendo solamente un préstamo activo:
SELECT *
FROM Prestamo
WHERE IdSocio = 3
AND FechaDevolucion IS NULL;

-- También verifica que el libro 4 no haya perdido ningún ejemplar:
SELECT * FROM Libro
WHERE IdLibro = 4;

-- Consulta útil para comprobar todo 
SELECT
    p.IdPrestamo,
    s.NomSocio,
    l.Titulo,
    p.FechaPrestamo,
    p.FechaDevolucion
FROM Prestamo p
INNER JOIN Socio s
    ON p.IdSocio = s.IdSocio
INNER JOIN Libro l
    ON p.IdLibro = l.IdLibro;
-- Y para ver solo los préstamos que siguen activos: 
SELECT
    p.IdPrestamo,
    s.NomSocio,
    l.Titulo,
    p.FechaPrestamo
FROM Prestamo p
INNER JOIN Socio s
    ON p.IdSocio = s.IdSocio
INNER JOIN Libro l
    ON p.IdLibro = l.IdLibro
WHERE p.FechaDevolucion IS NULL;
