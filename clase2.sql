-- Creacion de la tabla escuela 
CREATE DATABASE Escuela

go

use Escuela
go

/* Creando tabla Alumno, asignatura y profesor */

Create table Alumnos(
Id char(8) primary key,
Nombre varchar(20) not null,
Apellido varchar(20) not null,
Direccion varchar(50),
Fecha_nacimiento char(8)
);

Create table Asignatura(
Id char(8) primary key,
Nombre varchar(20) not null
);

Create table Profesor(
Id char(8) primary key,
Nombre varchar(20) not null,
Apellido varchar(20) not null,
Direccion varchar(50),
Fecha_nacimiento char(8),
Nivel_Academico varchar (20)
);

-- 2. CREACIÓN DE TABLA INSCRIPCION

CREATE TABLE Inscripcion (
    Id CHAR(8) PRIMARY KEY,
    IdAsignatura CHAR(8) NOT NULL,
    IdAlumno CHAR(8) NOT NULL,
    IdProfesor CHAR(8) NOT NULL,
    Fecha CHAR(8),

    CONSTRAINT FK_Inscripcion_Asignatura
        FOREIGN KEY (IdAsignatura)
        REFERENCES Asignatura(Id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_Inscripcion_Alumnos
        FOREIGN KEY (IdAlumno)
        REFERENCES Alumnos(Id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_Inscripcion_Profesor
        FOREIGN KEY (IdProfesor)
        REFERENCES Profesor(Id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
);

GO


-- 3. INSERTAR DATOS EN LAS TABLAS PRINCIPALES PRIMERO SE INSERTAN LOS PADRES

INSERT INTO Alumnos
    (Id, Nombre, Apellido, Direccion, Fecha_nacimiento)
VALUES
    ('0101', 'Juan', 'Gomez', 'Calle 10 #20', '01/01/00');


INSERT INTO Asignatura
    (Id, Nombre)
VALUES
    ('BD01', 'Base de Datos 1');


INSERT INTO Profesor
    (Id, Nombre, Apellido, Direccion, Fecha_nacimiento, Nivel_Academico)
VALUES
    ('PF01', 'Antonio', 'Perez', 'Avenida 01', '12/01/80', 'Licenciado');


INSERT INTO Inscripcion
    (Id, IdAsignatura, IdAlumno, IdProfesor, Fecha)
VALUES
    ('INS01', 'BD01', '0101', 'PF01', '12/01/80');


SELECT * FROM Alumnos;

SELECT * FROM Asignatura;

SELECT * FROM Profesor;

SELECT * FROM Inscripcion;

--Creacion de la tabla Alquilervideo 
CREATE DATABASE AlquilerVideo
GO

USE AlquilerVideo
GO

-- Tabla video
CREATE TABLE video
(
    codV CHAR(3) PRIMARY KEY,
    nomV CHAR(20)
)

-- Tabla ejemplar
CREATE TABLE ejemplar
(
    codE INT PRIMARY KEY,
    estado CHAR(1),
    codV CHAR(3),
    FOREIGN KEY (codV) REFERENCES video(codV)
)

-- Tabla socio
CREATE TABLE socio
(
    codS CHAR(3) PRIMARY KEY,
    nomS CHAR(20)
)

-- Tabla ejemplar_socio
CREATE TABLE ejemplar_socio
(
    codE INT,
    codS CHAR(3),
    PRIMARY KEY(codE, codS),
    fechaprestamo DATETIME,
    fechadevolucion DATETIME,
    precio MONEY,
    FOREIGN KEY (codE) REFERENCES ejemplar(codE),
    FOREIGN KEY (codS) REFERENCES socio(codS)
)

-- Insertar video
INSERT INTO video(codV, nomV) VALUES
('V1', 'La Cenicienta'),
('V2', 'El Piano'),
('V3', 'Titanic'),
('V4', 'Avatar'),
('V5', 'Matrix')

-- Insertar ejemplar
INSERT INTO ejemplar(codE, estado, codV) VALUES
(1, 'B', 'V1'),
(2, 'R', 'V2'),
(3, 'M', 'V3'),
(4, 'B', 'V4'),
(5, 'R', 'V5')

-- Insertar socio
INSERT INTO socio(codS, nomS) VALUES
('C01', 'Juan Perez'),
('C02', 'Maria Lopez'),
('C03', 'Carlos Gomez'),
('C04', 'Ana Torres'),
('C05', 'Luis Quispe')

-- Insertar ejemplar_socio
INSERT INTO ejemplar_socio VALUES
(1, 'C01', '2012-01-05', '2012-01-10', 15),
(2, 'C02', '2012-01-08', '2012-01-12', 20),
(3, 'C03', '2012-01-12', '2012-01-15', 25),
(4, 'C04', '2012-06-25', '2012-06-26', 5),
(5, 'C05', '2012-06-28', '2012-07-02', 30)

-- Actualizar
UPDATE video
SET nomV = 'El Piano'
WHERE codV = 'V1'

-- Eliminar
-- DELETE FROM video WHERE codV = 'V1'

-- Consultas simples
SELECT * FROM video
WHERE nomV LIKE '%a%'

SELECT * FROM ejemplar
WHERE estado LIKE 'M'
OR estado LIKE 'R'

SELECT * FROM ejemplar_socio
WHERE YEAR(fechaprestamo) = 2012

SELECT * FROM ejemplar_socio
WHERE fechaprestamo >= '2012-01-01'
AND fechaprestamo < '2012-01-15'

SELECT DISTINCT codS
FROM ejemplar_socio

-- Funciones
SELECT MAX(precio)
FROM ejemplar_socio

SELECT AVG(precio)
FROM ejemplar_socio

SELECT SUM(precio)
FROM ejemplar_socio

SELECT *
FROM ejemplar_socio
WHERE precio BETWEEN 10 AND 30

-- devuelve el nuemro de ejemplores en B R M  

SELECT COUNT(*), estado
FROM ejemplar
GROUP BY estado

SELECT COUNT(*), estado
FROM ejemplar
WHERE estado LIKE 'M'
OR estado LIKE 'R'
GROUP BY estado

SELECT codS, SUM(precio)
FROM ejemplar_socio
GROUP BY codS
