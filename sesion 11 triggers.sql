CREATE DATABASE RecursosHumanos;
GO

USE RecursosHumanos;
GO


-- =========================================
-- TABLA PUESTO
-- =========================================

CREATE TABLE Puesto
(
    IdPuesto INT IDENTITY(1,1) PRIMARY KEY,
    NomPuesto VARCHAR(100) NOT NULL,
    SueldoMaximo DECIMAL(10,2) NOT NULL
);
GO


-- =========================================
-- TABLA EMPLEADO
-- =========================================

CREATE TABLE Empleado
(
    IdEmpleado INT IDENTITY(1,1) PRIMARY KEY,
    NomEmpleado VARCHAR(100) NOT NULL,
    IdPuesto INT NOT NULL,
    SueldoActual DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Empleado_Puesto
    FOREIGN KEY (IdPuesto)
    REFERENCES Puesto(IdPuesto)
);
GO


-- =========================================
-- TABLA HISTORIAL SUELDO
-- =========================================

CREATE TABLE HistorialSueldo
(
    IdHistorial INT IDENTITY(1,1) PRIMARY KEY,
    IdEmpleado INT NOT NULL,
    SueldoAnterior DECIMAL(10,2) NOT NULL,
    SueldoNuevo DECIMAL(10,2) NOT NULL,
    FechaCambio DATETIME NOT NULL,
    Usuario VARCHAR(100) NOT NULL,

    CONSTRAINT FK_HistorialSueldo_Empleado
    FOREIGN KEY (IdEmpleado)
    REFERENCES Empleado(IdEmpleado)
);
GO


-- =========================================
-- DATOS DE PUESTOS
-- =========================================

INSERT INTO Puesto (NomPuesto, SueldoMaximo)
VALUES
('Programador Junior', 3000.00),
('Programador Senior', 6000.00),
('Analista de Sistemas', 5000.00),
('Jefe de Sistemas', 9000.00),
('Administrador de Base de Datos', 7000.00);
GO


-- =========================================
-- DATOS DE EMPLEADOS
-- =========================================

INSERT INTO Empleado (NomEmpleado, IdPuesto, SueldoActual)
VALUES
('Carlos Quispe', 1, 2000.00),
('Ana Flores', 2, 4500.00),
('Luis Mendoza', 3, 3500.00),
('Maria Huaman', 4, 7000.00),
('Pedro Vargas', 5, 5000.00);
GO

-- =========================================
-- DATOS DE HISTORIAL SUELDO 
-- =========================================
INSERT INTO HistorialSueldo
(IdEmpleado, SueldoAnterior, SueldoNuevo, FechaCambio, Usuario)
VALUES
(1, 1800.00, 2000.00, GETDATE(), SYSTEM_USER),
(2, 4000.00, 4500.00, GETDATE(), SYSTEM_USER),
(3, 3200.00, 3500.00, GETDATE(), SYSTEM_USER),
(4, 6500.00, 7000.00, GETDATE(), SYSTEM_USER),
(5, 4500.00, 5000.00, GETDATE(), SYSTEM_USER);
GO

-- =========================================
-- MOSTRAR DATOS
-- =========================================

SELECT * FROM Puesto;

SELECT * FROM Empleado;

SELECT * FROM HistorialSueldo;
GO
-- =========================================
-- Ejercicios de los triggers 
--3.
CREATE TRIGGER trg_SueldoMaximoPuesto
ON Empleado
AFTER UPDATE
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN Puesto p
            ON i.IdPuesto = p.IdPuesto
        WHERE i.SueldoActual > p.SueldoMaximo
    )
    BEGIN

        ROLLBACK TRANSACTION;

        THROW 50002,
        'ERROR: El sueldo del empleado no puede superar el sueldo maximo de su puesto.',
        1;

    END;

END;
GO
-- Tenemos al empleado 4:
SELECT *
FROM Empleado
WHERE IdEmpleado = 4;

-- Consultamos su puesto:
SELECT *
FROM Puesto
WHERE IdPuesto = 4;

-- Ahora intentamos colocarle:
UPDATE Empleado
SET SueldoActual = 9100
WHERE IdEmpleado = 4;

-- Ejercicios de AFTER UPDATE 
--1.
CREATE TRIGGER trg_HistorialSueldo
ON Empleado
AFTER UPDATE
AS
BEGIN

    INSERT INTO HistorialSueldo
    (
        IdEmpleado,
        SueldoAnterior,
        SueldoNuevo,
        FechaCambio,
        Usuario
    )
    SELECT
        i.IdEmpleado,
        d.SueldoActual,
        i.SueldoActual,
        GETDATE(),
        SYSTEM_USER
    FROM inserted i
    INNER JOIN deleted d
        ON i.IdEmpleado = d.IdEmpleado
    WHERE i.SueldoActual <> d.SueldoActual;

END;
GO

-- Primero cnsultamos al empleado 
SELECT * FROM Empleado
WHERE IdEmpleado = 1;

-- cambiamos el sueldo 
UPDATE Empleado SET SueldoActual = 2400
WHERE IdEmpleado = 1;

-- Ahora verificamos los cambios realizados
SELECT * FROM HistorialSueldo;
--2.
CREATE TRIGGER trg_LimiteAumentoSueldo
ON Empleado
AFTER UPDATE
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d
            ON i.IdEmpleado = d.IdEmpleado
        WHERE i.SueldoActual > d.SueldoActual * 1.30
    )
    BEGIN

        ROLLBACK TRANSACTION;

        THROW 50001,
        'ERROR: El sueldo no puede aumentar mas del 30% en una sola actualizacion.',
        1;

    END;

END;
GO
-- Pondremos 5900 para realizar la prueba
UPDATE Empleado 
SET SueldoActual = 5900
WHERE IdEmpleado = 2;

-- Verificamos los resultados 
SELECT * FROM Empleado
WHERE IdEmpleado = 2;
