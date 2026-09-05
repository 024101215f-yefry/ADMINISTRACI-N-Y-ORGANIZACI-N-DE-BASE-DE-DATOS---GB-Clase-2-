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


-- Ejercicios (1) de Funciones SQL - Modelo de Gestión de Fabricación

create function dbo.fn_disponibilidadstock (@idcomp INT)
returns varchar(30)
as
begin
    declare @estado varchar(30);
    declare @stock int;
    declare @stockmin int;

    select 
        @stock = stockcomp,
        @stockmin = stockmincomp
    from componente
    where idcomp = @idcomp;

    if @stock = 0
        set @estado = 'agotado';
    else if @stock < @stockmin
        set @estado = 'crítico';
    else
        set @estado = 'suficiente';

    return @estado;
end;
go
-- Uso
select dbo.fn_disponibilidadstock(1) as disponibilidad;
 
-- Para cada una de las atributos de la tabla
select 
    idcomp,
    nomcomp,
    stockcomp,
    stockmincomp,
    dbo.fn_disponibilidadstock(idcomp) as disponibilidad
from componente;

-- Ejercicio 2: Función Escalar - Formato de Proveedor
create function dbo.fn_materiasprimasdecomponente(@idcomp int)
returns table
as
return
(
    select
        mp.idmp,
        mp.nommp,
        p.nomprov
    from fabricacion f
    inner join materiaprima mp
        on f.idmp = mp.idmp
    inner join proveedor p
        on mp.codprov = p.codprov
    where f.idcomp = @idcomp
);
go
select 

-- Ejercicio 3: Función de Tabla Inline - Materias Primas por Componente 

create function dbo.fn_materiasprimasdecomponente(@idcomp int)
returns table
as
return
(
    select
        mp.idmp,
        mp.nommp,
        p.nomprov
    from fabricacion f
    inner join materiaprima mp
        on f.idmp = mp.idmp
    inner join proveedor p
        on mp.codprov = p.codprov
    where f.idcomp = @idcomp
);
go



-- Ejercicio 4: Función de Tabla - Proveedores con Bajo Suministro
create function dbo.fn_proveedoresbajosuministro()
returns table
as
return
(
    select
        p.codprov,
        p.nomprov,
        count(mp.idmp) as totalmateriasprimas
    from proveedor p
    left join materiaprima mp
        on p.codprov = mp.codprov
    group by
        p.codprov,
        p.nomprov
    having count(mp.idmp) < 2
);
go




-- Ejercicio 5: Consulta con Funciones Integradas - Reporte Ejecutivo     
    
    
 
    
