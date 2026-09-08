create database Fabricacion

use Fabricacion

-- =======================================================
-- MODELO FÍSICO + DATOS DE PRUEBA
-- Motor: SQL Server
-- =======================================================

-- =====================
-- 1. CREACIÓN DE TABLAS
-- =====================

CREATE TABLE Proveedor (
    CodProv         INT IDENTITY(1,1)   NOT NULL,
    NomProv         NVARCHAR(100)       NOT NULL,
    DirProv         NVARCHAR(200)       NULL,
    TlfProv         VARCHAR(20)         NULL,
    CONSTRAINT PK_Proveedor PRIMARY KEY (CodProv)
);
GO

CREATE TABLE MateriaPrima (
    IdMP            INT IDENTITY(1,1)   NOT NULL,
    NomMP           NVARCHAR(100)       NOT NULL,
    CodProv         INT                 NOT NULL,
    CONSTRAINT PK_MateriaPrima PRIMARY KEY (IdMP),
    CONSTRAINT FK_MateriaPrima_Proveedor FOREIGN KEY (CodProv) 
        REFERENCES Proveedor(CodProv) ON UPDATE CASCADE ON DELETE NO ACTION
);
GO

CREATE TABLE Componente (
    IdComp          INT IDENTITY(1,1)   NOT NULL,
    NomComp         NVARCHAR(100)       NOT NULL,
    StockComp       INT NOT NULL DEFAULT 0,
    StockMinComp    INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Componente PRIMARY KEY (IdComp),
    CONSTRAINT CK_Componente_Stock CHECK (StockComp >= 0),
    CONSTRAINT CK_Componente_StockMin CHECK (StockMinComp >= 0)
);
GO

CREATE TABLE Fabricacion (
    IdMP    INT NOT NULL,
    IdComp  INT NOT NULL,
    CONSTRAINT PK_Fabricacion PRIMARY KEY (IdMP, IdComp),
    CONSTRAINT FK_Fabricacion_MP FOREIGN KEY (IdMP) 
        REFERENCES MateriaPrima(IdMP) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Fabricacion_Comp FOREIGN KEY (IdComp) 
        REFERENCES Componente(IdComp) ON UPDATE CASCADE ON DELETE CASCADE
);
GO

CREATE TABLE Composicion (
    IdComp      INT NOT NULL,   -- Padre
    IdComSub    INT NOT NULL,   -- Hijo
    cant        INT NOT NULL,
    CONSTRAINT PK_Composicion PRIMARY KEY (IdComp, IdComSub),
    CONSTRAINT FK_Composicion_Padre FOREIGN KEY (IdComp) 
        REFERENCES Componente(IdComp) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_Composicion_Hijo FOREIGN KEY (IdComSub) 
        REFERENCES Componente(IdComp) ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT CK_Composicion_Cant CHECK (cant > 0),
    CONSTRAINT CK_Composicion_NoAutoRef CHECK (IdComp <> IdComSub)
);
GO

-- =====================
-- 2. INSERCIÓN DE DATOS
-- =====================

-- ---------- PROVEEDORES ----------
DECLARE @IdProv1 INT, @IdProv2 INT, @IdProv3 INT, @IdProv4 INT, @IdProv5 INT;

INSERT INTO Proveedor (NomProv, DirProv, TlfProv) VALUES 
    ('Aceros del Norte S.A.',    'Av. Industrial 120, Monterrey',    '+52 81 5555 1001'),
    ('Maderas Premium MX',       'Calle Roble 45, Durango',          '+52 618 5555 2002'),
    ('Plásticos Técnicos SA',    'Parque Industrial 8, Querétaro',   '+52 442 5555 3003'),
    ('Tornillería Industrial',   'Blvd. López 890, CDMX',            '+52 55 5555 4004'),
    ('Químicos del Bajío',       'Carretera 57 Km 12, León',         '+52 477 5555 5005');

SELECT @IdProv1 = 1, @IdProv2 = 2, @IdProv3 = 3, @IdProv4 = 4, @IdProv5 = 5;

-- ---------- MATERIAS PRIMAS ----------
-- Cada MP asociada a un proveedor distinto
INSERT INTO MateriaPrima (NomMP, CodProv) VALUES 
    ('Lámina de Acero Inoxidable 304', @IdProv1),
    ('Tablero de MDF 18mm',            @IdProv2),
    ('Resina Poliéster',               @IdProv3),
    ('Tornillo Hexagonal M6x20',       @IdProv4),
    ('Pintura Epóxica Gris',           @IdProv5);

-- ---------- COMPONENTES ----------
INSERT INTO Componente (NomComp, StockComp, StockMinComp) VALUES 
    ('Mesa de Oficina Ejecutiva',  15,  5),   -- IdComp = 1 (Producto Final)
    ('Pata Metálica Ensamblada',   40,  10),  -- IdComp = 2 (Subensamble)
    ('Tablero Superior MDF',       25,  8),   -- IdComp = 3 (Componente simple)
    ('Soporte de Refuerzo',        60,  15),  -- IdComp = 4 (Componente simple)
    ('Tornillo de Montaje M6',    500, 100);  -- IdComp = 5 (Componente simple)

-- ---------- FABRICACIÓN (MP -> Componente) ----------
-- Relaciona materias primas con los componentes que las utilizan
INSERT INTO Fabricacion (IdMP, IdComp) VALUES 
    (1, 2),  -- Lámina de Acero -> Pata Metálica
    (1, 4), -- Lámina de Acero -> Soporte de Refuerzo
    (2, 3), -- MDF -> Tablero Superior
    (4, 2), -- Tornillo -> Pata Metálica
    (5, 2);  -- Pintura -> Pata Metálica

-- ---------- COMPOSICIÓN (Árbol de materiales BOM) ----------
-- Estructura jerárquica sin ciclos:
--   1 (Mesa)  -> 2 (Pata) x4, 3 (Tablero) x1
--   2 (Pata)  -> 4 (Soporte) x2, 5 (Tornillo) x8
INSERT INTO Composicion (IdComp, IdComSub, cant) VALUES 
    (1, 2, 4),   -- La Mesa lleva 4 Patas
    (1, 3, 1),   -- La Mesa lleva 1 Tablero Superior
    (2, 4, 2),   -- Cada Pata lleva 2 Soportes
    (2, 5, 8),   -- Cada Pata lleva 8 Tornillos
    (3, 5, 4);   -- El Tablero lleva 4 Tornillos de montaje


USE Fabricacion;
GO

SELECT DB_NAME() AS BaseDeDatosActual;

 --// Ejercicios propuestos - Modelo de Gestión de Fabricación //

 -- (Ejercicio 1: Vista de Alertas de Stock )
USE Fabricacion;
GO

CREATE OR ALTER VIEW dbo.vw_AlertasStock
AS
SELECT
    c.IdComp,
    c.NomComp,
    c.StockComp AS StockActual,
    c.StockMinComp AS StockMinimo,
    (c.StockMinComp - c.StockComp) AS Diferencia,
    CASE
        WHEN c.StockComp = 0 THEN N'CRÍTICA'
        WHEN c.StockComp < (c.StockMinComp / 2.0) THEN N'ALTA'
        WHEN c.StockComp < c.StockMinComp THEN N'MEDIA'
        ELSE N'SIN ALERTA'
    END AS NivelUrgencia
FROM dbo.Componente AS c
WHERE c.StockComp < c.StockMinComp;
GO
UPDATE dbo.Componente
SET StockComp = 0
WHERE IdComp = 1;

UPDATE dbo.Componente
SET StockComp = 4
WHERE IdComp = 2;

UPDATE dbo.Componente
SET StockComp = 7
WHERE IdComp = 3;
GO
SELECT * FROM dbo.vw_AlertasStock;
GO

-- (Ejercicio 2: Vista de Costos de Producción)
USE Fabricacion;
GO

IF OBJECT_ID('dbo.vw_CostosProduccion', 'V') IS NOT NULL
    DROP VIEW dbo.vw_CostosProduccion;
GO

CREATE VIEW dbo.vw_CostosProduccion
AS
SELECT
    c.IdComp,
    c.NomComp,

    mp.IdMP,
    mp.NomMP,

    p.NomProv,

    COUNT(*) AS CantidadMP

FROM dbo.Componente AS c

INNER JOIN dbo.Fabricacion AS f
    ON c.IdComp = f.IdComp

INNER JOIN dbo.MateriaPrima AS mp
    ON f.IdMP = mp.IdMP

INNER JOIN dbo.Proveedor AS p
    ON mp.CodProv = p.CodProv

GROUP BY
    c.IdComp,
    c.NomComp,
    mp.IdMP,
    mp.NomMP,
    p.NomProv;
GO
-- Para poder hacer la consulta 
SELECT * FROM dbo.vw_CostosProduccion

-- (Ejercicio 3: Vista Jerárquica de Composición)

USE Fabricacion;
GO

IF OBJECT_ID('dbo.vw_JerarquiaComponentes', 'V') IS NOT NULL
    DROP VIEW dbo.vw_JerarquiaComponentes;
GO

CREATE VIEW dbo.vw_JerarquiaComponentes
AS
SELECT
    CASE
        WHEN COUNT(DISTINCT ComoHijo.IdComp) = 0 THEN 0
        ELSE 1
    END AS Nivel,

    c.IdComp,
    c.NomComp,
    CAST(
        CASE
            WHEN COUNT(DISTINCT ComoPadre.IdComSub) > 0
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS EsPadre,
    CAST(
        CASE
            WHEN COUNT(DISTINCT ComoHijo.IdComp) > 0
                THEN 1
            ELSE 0
        END
        AS BIT
    ) AS EsHijo,
    COUNT(DISTINCT ComoPadre.IdComSub)
        AS TotalComoPadre,

    COUNT(DISTINCT ComoHijo.IdComp)
        AS TotalComoHijo

FROM dbo.Componente AS c

LEFT JOIN dbo.Composicion AS ComoPadre
    ON c.IdComp = ComoPadre.IdComp


LEFT JOIN dbo.Composicion AS ComoHijo
    ON c.IdComp = ComoHijo.IdComSub

GROUP BY
    c.IdComp,
    c.NomComp;
GO

SELECT * FROM dbo.vw_JerarquiaComponentes
ORDER BY IdComp;


 -- (Ejercicio 4: Vista Indexada de Reporte Ejecutivo)
 USE Fabricacion;
GO

IF OBJECT_ID('dbo.vw_ReporteEjecutivo', 'V') IS NOT NULL
    DROP VIEW dbo.vw_ReporteEjecutivo;
GO

CREATE VIEW dbo.vw_ReporteEjecutivo
AS
SELECT
    p.CodProv,
    p.NomProv,

    COUNT(DISTINCT mp.IdMP)
        AS TotalMateriasPrimas,

    COUNT(DISTINCT f.IdComp)
        AS TotalComponentesSuministrados,

    GETDATE()
        AS UltimaActualizacion

FROM dbo.Proveedor AS p

LEFT JOIN dbo.MateriaPrima AS mp
    ON p.CodProv = mp.CodProv

LEFT JOIN dbo.Fabricacion AS f
    ON mp.IdMP = f.IdMP

GROUP BY
    p.CodProv,
    p.NomProv;
GO
-- Para realizar la consulta

SELECT * FROM dbo.vw_ReporteEjecutivo
ORDER BY CodProv;
