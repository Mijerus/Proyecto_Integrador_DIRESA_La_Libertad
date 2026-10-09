CREATE DATABASE DIRESA_La_Libertad;
GO

USE DIRESA_La_Libertad;
GO

-- =========================================================
-- TABLA: Prestaciones
-- =========================================================

CREATE TABLE Prestaciones
(
    ID_REGISTRO_REL VARCHAR(50) NOT NULL,
    FECHA_CORTE DATE NULL,
    CODIGO_ANONIMIZADO VARCHAR(100) NULL,
    DEPARTAMENTO VARCHAR(100) NULL,
    PROVINCIA VARCHAR(100) NULL,
    DISTRITO VARCHAR(100) NULL,
    UBIGEO VARCHAR(6) NULL,
    NIVEL_EESS VARCHAR(50) NULL,
    CODIGO_SERV_PRESTACIONAL VARCHAR(50) NULL,
    SERVICIO_PRESTACIONAL VARCHAR(200) NULL,
    DIAS_HOSP INT NULL,
    EDAD_DIAS INT NULL,
    FECHA_ATENCION DATE NULL,
    SEXO VARCHAR(20) NULL,
    PESO DECIMAL(8,2) NULL,
    ATE_CAPITA DECIMAL(12,2) NULL,

    CONSTRAINT PK_Prestaciones
        PRIMARY KEY (ID_REGISTRO_REL)
);
GO


-- =========================================================
-- TABLA: Diagnosticos
-- =========================================================

CREATE TABLE Diagnosticos
(
    ID_REGISTRO_REL VARCHAR(50) NOT NULL,
    CODDIA VARCHAR(20) NULL,
    TIPO_DIAGNOSTICO VARCHAR(50) NULL,

    CONSTRAINT FK_Diagnosticos_Prestaciones
        FOREIGN KEY (ID_REGISTRO_REL)
        REFERENCES Prestaciones(ID_REGISTRO_REL)
);
GO


-- =========================================================
-- TABLA: Medicamentos
-- =========================================================

CREATE TABLE Medicamentos
(
    ID_REGISTRO_REL VARCHAR(50) NOT NULL,
    CODDIA VARCHAR(20) NULL,
    COD_MEDICAMENTO VARCHAR(50) NULL,
    CANTIDAD_ENTREGADA DECIMAL(12,2) NULL,
    VALOR_NETO DECIMAL(12,2) NULL,

    CONSTRAINT FK_Medicamentos_Prestaciones
        FOREIGN KEY (ID_REGISTRO_REL)
        REFERENCES Prestaciones(ID_REGISTRO_REL)
);
GO


-- =========================================================
-- TABLA: Establecimientos
-- =========================================================

CREATE TABLE Establecimientos
(
    CODIGO_UNICO VARCHAR(30) NOT NULL,
    INSTITUCION VARCHAR(100) NULL,
    NOMBRE_ESTABLECIMIENTO VARCHAR(200) NULL,
    CLASIFICACION VARCHAR(100) NULL,
    TIPO VARCHAR(100) NULL,
    DEPARTAMENTO VARCHAR(100) NULL,
    PROVINCIA VARCHAR(100) NULL,
    DISTRITO VARCHAR(100) NULL,
    UBIGEO VARCHAR(6) NULL,
    DIRECCION VARCHAR(250) NULL,
    CODIGO_DISA VARCHAR(30) NULL,
    CODIGO_RED VARCHAR(30) NULL,
    CODIGO_MICRORED VARCHAR(30) NULL,
    DISA VARCHAR(150) NULL,
    RED VARCHAR(150) NULL,
    MICRORED VARCHAR(150) NULL,
    CODIGO_UE VARCHAR(30) NULL,
    UNIDAD_EJECUTORA VARCHAR(200) NULL,
    CATEGORIA VARCHAR(50) NULL,
    TELEFONO VARCHAR(30) NULL,
    TIPO_DOC_CATEGORIZACION VARCHAR(50) NULL,
    NRO_DOC_CATEGORIZACION VARCHAR(50) NULL,
    HORARIO VARCHAR(200) NULL,
    INICIO_ACTIVIDAD DATE NULL,
    DIRECTOR_RESPONSABLE VARCHAR(200) NULL,
    ESTADO VARCHAR(50) NULL,
    SITUACION VARCHAR(50) NULL,
    CONDICION VARCHAR(100) NULL,
    INSPECCION VARCHAR(100) NULL,
    NORTE DECIMAL(12,6) NULL,
    ESTE DECIMAL(12,6) NULL,
    COTA DECIMAL(10,2) NULL,
    CAMAS INT NULL,

    CONSTRAINT PK_Establecimientos
        PRIMARY KEY (CODIGO_UNICO)
);
GO

-- =========================================================
-- PROCEDIMIENTO 1: sp_ImportarPrestacion
--
-- Propósito:
-- Automatizar la inserción de una prestación.
-- Controla duplicados y errores mediante transacciones.
-- =========================================================

DROP PROCEDURE IF EXISTS sp_ImportarPrestacion;
GO

CREATE PROCEDURE sp_ImportarPrestacion
    @p_ID_REGISTRO_REL VARCHAR(50),
    @p_FECHA_CORTE DATE,
    @p_CODIGO_ANONIMIZADO VARCHAR(100),
    @p_DEPARTAMENTO VARCHAR(100),
    @p_PROVINCIA VARCHAR(100),
    @p_DISTRITO VARCHAR(100),
    @p_UBIGEO VARCHAR(6),
    @p_NIVEL_EESS VARCHAR(50),
    @p_CODIGO_SERV_PRESTACIONAL VARCHAR(50),
    @p_SERVICIO_PRESTACIONAL VARCHAR(200),
    @p_DIAS_HOSP INT,
    @p_EDAD_DIAS INT,
    @p_FECHA_ATENCION DATE,
    @p_SEXO VARCHAR(20),
    @p_PESO DECIMAL(8,2),
    @p_ATE_CAPITA DECIMAL(12,2)
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY

        BEGIN TRANSACTION;

        -- Verificar si el ID ya existe
        IF EXISTS
        (
            SELECT 1
            FROM Prestaciones
            WHERE ID_REGISTRO_REL = @p_ID_REGISTRO_REL
        )
        BEGIN
            THROW 50001, 'El ID_REGISTRO_REL ya existe.', 1;
        END;

        -- Crear punto de guardado
        SAVE TRANSACTION PuntoIngesta;

        -- Insertar la prestación
        INSERT INTO Prestaciones
        (
            ID_REGISTRO_REL,
            FECHA_CORTE,
            CODIGO_ANONIMIZADO,
            DEPARTAMENTO,
            PROVINCIA,
            DISTRITO,
            UBIGEO,
            NIVEL_EESS,
            CODIGO_SERV_PRESTACIONAL,
            SERVICIO_PRESTACIONAL,
            DIAS_HOSP,
            EDAD_DIAS,
            FECHA_ATENCION,
            SEXO,
            PESO,
            ATE_CAPITA
        )
        VALUES
        (
            @p_ID_REGISTRO_REL,
            @p_FECHA_CORTE,
            @p_CODIGO_ANONIMIZADO,
            @p_DEPARTAMENTO,
            @p_PROVINCIA,
            @p_DISTRITO,
            @p_UBIGEO,
            @p_NIVEL_EESS,
            @p_CODIGO_SERV_PRESTACIONAL,
            @p_SERVICIO_PRESTACIONAL,
            @p_DIAS_HOSP,
            @p_EDAD_DIAS,
            @p_FECHA_ATENCION,
            @p_SEXO,
            @p_PESO,
            @p_ATE_CAPITA
        );

        COMMIT TRANSACTION;

        SELECT
            'Prestación registrada correctamente' AS Mensaje;

    END TRY

    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;

    END CATCH;

END;
GO
-- ejecucion 

EXEC sp_ImportarPrestacion
    @p_ID_REGISTRO_REL = 'PRUEBA001',
    @p_FECHA_CORTE = '2024-12-31',
    @p_CODIGO_ANONIMIZADO = 'PAC001',
    @p_DEPARTAMENTO = 'LA LIBERTAD',
    @p_PROVINCIA = 'TRUJILLO',
    @p_DISTRITO = 'TRUJILLO',
    @p_UBIGEO = '130101',
    @p_NIVEL_EESS = 'I-3',
    @p_CODIGO_SERV_PRESTACIONAL = 'SERV001',
    @p_SERVICIO_PRESTACIONAL = 'CONSULTA',
    @p_DIAS_HOSP = NULL,
    @p_EDAD_DIAS = 3650,
    @p_FECHA_ATENCION = '2024-10-15',
    @p_SEXO = 'M',
    @p_PESO = 70.50,
    @p_ATE_CAPITA = 1.00;
GO
--verificacion
SELECT *
FROM Prestaciones
WHERE ID_REGISTRO_REL = 'PRUEBA001';
GO

-- =========================================================
-- PROCEDIMIENTO 2: sp_ValidarPrestaciones
--
-- Propósito:
-- Validar automáticamente los registros de Prestaciones.
-- Detecta diferentes tipos de errores.
-- =========================================================

DROP PROCEDURE IF EXISTS sp_ValidarPrestaciones;
GO

CREATE PROCEDURE sp_ValidarPrestaciones
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @errores INT = 0;

    BEGIN TRY

        BEGIN TRANSACTION;

        SAVE TRANSACTION PuntoValidacion;

        -- Contar todos los problemas encontrados
        SELECT @errores = COUNT(*)
        FROM
        (
            SELECT ID_REGISTRO_REL
            FROM Prestaciones
            WHERE ID_REGISTRO_REL IS NULL
               OR ID_REGISTRO_REL = ''

            UNION ALL

            SELECT ID_REGISTRO_REL
            FROM Prestaciones
            WHERE DIAS_HOSP < 0

            UNION ALL

            SELECT ID_REGISTRO_REL
            FROM Prestaciones
            WHERE EDAD_DIAS < 0

            UNION ALL

            SELECT ID_REGISTRO_REL
            FROM Prestaciones
            WHERE PESO < 0
        ) AS Errores;


        -- Si no existen errores
        IF @errores = 0
        BEGIN

            SELECT
                'No se encontraron errores' AS Resultado;

        END

        ELSE
        BEGIN

            -- Mostrar todos los errores encontrados

            SELECT
                ID_REGISTRO_REL,
                'ID_REGISTRO_REL vacío' AS Problema
            FROM Prestaciones
            WHERE ID_REGISTRO_REL IS NULL
               OR ID_REGISTRO_REL = ''

            UNION ALL

            SELECT
                ID_REGISTRO_REL,
                'DIAS_HOSP negativo' AS Problema
            FROM Prestaciones
            WHERE DIAS_HOSP < 0

            UNION ALL

            SELECT
                ID_REGISTRO_REL,
                'EDAD_DIAS negativa' AS Problema
            FROM Prestaciones
            WHERE EDAD_DIAS < 0

            UNION ALL

            SELECT
                ID_REGISTRO_REL,
                'PESO negativo' AS Problema
            FROM Prestaciones
            WHERE PESO < 0;

        END;

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH

        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;

    END CATCH;

END;
GO
--ejecucion
EXEC sp_ValidarPrestaciones;
GO

-- error de prueb para verificar el procedimiento 2 ---
EXEC sp_ImportarPrestacion
    @p_ID_REGISTRO_REL = 'ERROR001',
    @p_FECHA_CORTE = '2024-12-31',
    @p_CODIGO_ANONIMIZADO = 'PAC_ERROR',
    @p_DEPARTAMENTO = 'LA LIBERTAD',
    @p_PROVINCIA = 'TRUJILLO',
    @p_DISTRITO = 'TRUJILLO',
    @p_UBIGEO = '130101',
    @p_NIVEL_EESS = 'I-3',
    @p_CODIGO_SERV_PRESTACIONAL = 'SERV001',
    @p_SERVICIO_PRESTACIONAL = 'CONSULTA',
    @p_DIAS_HOSP = 2,
    @p_EDAD_DIAS = 3650,
    @p_FECHA_ATENCION = '2024-10-15',
    @p_SEXO = 'M',
    @p_PESO = -70,
    @p_ATE_CAPITA = 1;

--triggers y log auditoria 

-- =========================================================
-- TABLA: LogAuditoria
--
-- Propósito:
-- Almacenar las operaciones realizadas sobre las tablas
-- mediante los triggers de auditoría.
-- =========================================================

DROP TABLE IF EXISTS LogAuditoria;
GO

CREATE TABLE LogAuditoria
(
    IdLog INT IDENTITY(1,1) PRIMARY KEY,

    FechaHora DATETIME2 NOT NULL
        DEFAULT GETDATE(),

    Usuario VARCHAR(100) NOT NULL
        DEFAULT SUSER_SNAME(),

    TablaAfectada VARCHAR(100) NOT NULL,

    Operacion VARCHAR(30) NOT NULL,

    IDRegistro VARCHAR(50) NULL,

    Detalle VARCHAR(500) NULL
);
GO


-- TRIGGER 1: AUDITORÍA 

DROP TRIGGER IF EXISTS trg_AuditoriaPrestaciones;
GO

CREATE TRIGGER trg_AuditoriaPrestaciones
ON Prestaciones
AFTER INSERT, UPDATE, DELETE
AS
BEGIN

    SET NOCOUNT ON;
    -- REGISTRAR INSERT
    INSERT INTO LogAuditoria
    (
        TablaAfectada,
        Operacion,
        IDRegistro,
        Detalle
    )
    SELECT
        'Prestaciones',
        'INSERT',
        ID_REGISTRO_REL,
        'Se insertó una nueva prestación.'
    FROM inserted
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM deleted
        WHERE deleted.ID_REGISTRO_REL = inserted.ID_REGISTRO_REL
    );
    -- REGISTRAR UPDATE
    INSERT INTO LogAuditoria
    (
        TablaAfectada,
        Operacion,
        IDRegistro,
        Detalle
    )
    SELECT
        IDI.TablaAfectada,
        IDI.Operacion,
        IDI.IDRegistro,
        IDI.Detalle
    FROM
    (
        SELECT
            'Prestaciones' AS TablaAfectada,
            'UPDATE' AS Operacion,
            i.ID_REGISTRO_REL AS IDRegistro,
            'Se actualizó una prestación.' AS Detalle
        FROM inserted i
        INNER JOIN deleted d
            ON d.ID_REGISTRO_REL = i.ID_REGISTRO_REL
    ) AS IDI;

    -- REGISTRAR DELETE
    INSERT INTO LogAuditoria
    (
        TablaAfectada,
        Operacion,
        IDRegistro,
        Detalle
    )
    SELECT
        'Prestaciones',
        'DELETE',
        ID_REGISTRO_REL,
        'Se eliminó una prestación.'
    FROM deleted
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE inserted.ID_REGISTRO_REL = deleted.ID_REGISTRO_REL
    );

END;
GO

-- =========================================================
-- TRIGGER 2: INTEGRIDAD DE DATOS


DROP TRIGGER IF EXISTS trg_IntegridadPrestaciones;
GO

CREATE TRIGGER trg_IntegridadPrestaciones
ON Prestaciones
AFTER INSERT, UPDATE
AS
BEGIN

    SET NOCOUNT ON;

    -- =====================================================
    -- VALIDAR DIAS_HOSP
    -- =====================================================

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE DIAS_HOSP < 0
    )
    BEGIN

        THROW 50002, 'Error de integridad: DIAS_HOSP no puede ser negativo.', 1;

    END;


    -- =====================================================
    -- VALIDAR EDAD_DIAS
    -- =====================================================

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE EDAD_DIAS < 0
    )
    BEGIN

        THROW 50003, 'Error de integridad: EDAD_DIAS no puede ser negativa.', 1;

    END;


    -- =====================================================
    -- VALIDAR PESO
    -- =====================================================

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE PESO < 0
    )
    BEGIN

        THROW 50004, 'Error de integridad: PESO no puede ser negativo.', 1;

    END;

END;
GO

EXEC sp_ValidarPrestaciones;


SELECT name, is_disabled
FROM sys.triggers
WHERE parent_id = OBJECT_ID('Prestaciones');

INSERT INTO Prestaciones
(
    ID_REGISTRO_REL,
    FECHA_CORTE,
    CODIGO_ANONIMIZADO,
    DEPARTAMENTO,
    PROVINCIA,
    DISTRITO,
    UBIGEO,
    NIVEL_EESS,
    CODIGO_SERV_PRESTACIONAL,
    SERVICIO_PRESTACIONAL,
    DIAS_HOSP,
    EDAD_DIAS,
    FECHA_ATENCION,
    SEXO,
    PESO,
    ATE_CAPITA
)
VALUES
(
    'TRIGGER001',
    '2024-12-31',
    'PAC001',
    'LA LIBERTAD',
    'TRUJILLO',
    'TRUJILLO',
    '130101',
    'I-3',
    'SERV001',
    'CONSULTA',
    2,
    3650,
    '2024-10-15',
    'M',
    70.5,
    1
);

UPDATE Prestaciones
SET PESO = 75
WHERE ID_REGISTRO_REL = 'TRIGGER001';

DELETE FROM Prestaciones
WHERE ID_REGISTRO_REL = 'ERROR001';

SELECT *
FROM Prestaciones

SELECT *
FROM LogAuditoria
ORDER BY IdLog DESC;

SELECT *
FROM Prestaciones
WHERE ID_REGISTRO_REL = 'ERROR001';

-- Funcion escalar 

CREATE FUNCTION fn_CalcularEdadAnios( @EdadDias INT)
RETURNS INT
AS
BEGIN
    DECLARE @EdadAnios INT;

    IF @EdadDias IS NULL OR @EdadDias < 0
        RETURN NULL;

    SET @EdadAnios = FLOOR(@EdadDias / 365.25);

    RETURN @EdadAnios;
END;
GO

SELECT dbo.fn_CalcularEdadAnios(3650) AS EdadAnios;

-- creacion de roles 

CREATE ROLE RolAdministrador;
GO

CREATE ROLE RolAnalista;
GO

CREATE ROLE RolAuditor;
GO

-- asignar permisos a los roles 


GRANT CONTROL ON DATABASE::DIRESA_La_Libertad
TO RolAdministrador;
GO

GRANT SELECT ON SCHEMA::dbo
TO RolAnalista;
GO

GRANT SELECT ON OBJECT::dbo.LogAuditoria
TO RolAuditor;
GO

--- politicas de respaldo 
-- backup full
BACKUP DATABASE DIRESA_La_Libertad
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\DIRESA_La_Libertad_FULL.bak'
WITH INIT,
     NAME = 'FULL - DIRESA La Libertad',
     STATS = 10;
GO
-- backup diferencial 

BACKUP DATABASE DIRESA_La_Libertad
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\DIRESA_La_Libertad_DIFF.bak'
WITH DIFFERENTIAL,
     INIT,
     NAME = 'DIFFERENTIAL - DIRESA La Libertad',
     STATS = 10;
GO
-- comprobacion de backups 

RESTORE VERIFYONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\DIRESA_La_Libertad_FULL.bak';
GO

RESTORE VERIFYONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\DIRESA_La_Libertad_DIFF.bak';
GO
-- RESTAURACION 
RESTORE FILELISTONLY
FROM DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\DIRESA_La_Libertad_FULL.bak';
GO

-- Reporte comparativo de rendimiento

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    ID_REGISTRO_REL,
    FECHA_ATENCION,
    DEPARTAMENTO,
    PROVINCIA,
    DISTRITO,
    SERVICIO_PRESTACIONAL,
    SEXO,
    PESO
FROM Prestaciones
WHERE DEPARTAMENTO = 'La Libertad'
  AND FECHA_ATENCION >= '2024-01-01'
  AND FECHA_ATENCION < '2025-01-01';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

CREATE INDEX IX_Prestaciones_Departamento_Fecha
ON Prestaciones (DEPARTAMENTO, FECHA_ATENCION);
GO

SELECT

PROVINCIA,

COUNT(*) AS TOTAL_PRESTACIONES FROM Prestaciones GROUP BY PROVINCIA ORDER BY TOTAL_PRESTACIONES DESC;


USE DW_DIRESA_La_Libertad;
GO

SELECT
    'DIM_FECHA' AS Tabla,
    COUNT(*) AS Registros
FROM DIM_FECHA

UNION ALL

SELECT 'DIM_MEDICAMENTO', COUNT(*)
FROM DIM_MEDICAMENTO

UNION ALL

SELECT 'DIM_DIAGNOSTICO', COUNT(*)
FROM DIM_DIAGNOSTICO

UNION ALL

SELECT 'DIM_ESTABLECIMIENTO', COUNT(*)
FROM DIM_ESTABLECIMIENTO

UNION ALL

SELECT 'DIM_ATENCION', COUNT(*)
FROM DIM_ATENCION

UNION ALL

SELECT 'FACT_CONSUMO_MEDICAMENTOS', COUNT(*)
FROM FACT_CONSUMO_MEDICAMENTOS;

SELECT @@SERVERNAME AS NombreServidor;

SELECT
    COUNT(*) AS TotalFilas,
    SUM(cantidad_entregada) AS TotalMedicamentos,
    SUM(valor_neto) AS ValorTotal
FROM FACT_CONSUMO_MEDICAMENTOS;

SELECT *
FROM FACT_CONSUMO_MEDICAMENTOS;

IF NOT EXISTS (
    SELECT 1 FROM DIM_FECHA WHERE fecha_key = 20241015
)
BEGIN
    INSERT INTO DIM_FECHA
    (fecha_key, fecha, dia, mes, nombre_mes, trimestre, anio)
    VALUES
    (20241015, '2024-10-15', 15, 10, 'Octubre', 4, 2024);
END;
GO

-- 2. DIMENSION MEDICAMENTO
IF NOT EXISTS (
    SELECT 1 FROM DIM_MEDICAMENTO WHERE medicamento_key = 990001
)
BEGIN
    INSERT INTO DIM_MEDICAMENTO
    (medicamento_key, cod_medicamento)
    VALUES
    (990001, 'MED001');
END;

IF NOT EXISTS (
    SELECT 1 FROM DIM_MEDICAMENTO WHERE medicamento_key = 990002
)
BEGIN
    INSERT INTO DIM_MEDICAMENTO
    (medicamento_key, cod_medicamento)
    VALUES
    (990002, 'MED002');
END;
GO

-- 3. DIMENSION DIAGNOSTICO
IF NOT EXISTS (
    SELECT 1 FROM DIM_DIAGNOSTICO WHERE diagnostico_key = 990001
)
BEGIN
    INSERT INTO DIM_DIAGNOSTICO
    (diagnostico_key, coddia, tipo_diagnostico)
    VALUES
    (990001, 'J06.9', 'PRINCIPAL');
END;
GO

-- 4. DIMENSION ESTABLECIMIENTO
IF NOT EXISTS (
    SELECT 1 FROM DIM_ESTABLECIMIENTO
    WHERE establecimiento_key = 990001
)
BEGIN
    INSERT INTO DIM_ESTABLECIMIENTO
    (
        establecimiento_key, codigo_unico,
        institucion, nombre_establecimiento,
        departamento, provincia, distrito, ubigeo,
        categoria, estado, camas
    )
    VALUES
    (
        990001, 'EESS001',
        'MINSA', 'Centro de Salud Trujillo',
        'LA LIBERTAD', 'TRUJILLO', 'TRUJILLO',
        '130101', 'I-3', 'ACTIVO', 10
    );
END;
GO

-- 5. DIMENSION ATENCION
IF NOT EXISTS (
    SELECT 1 FROM DIM_ATENCION WHERE atencion_key = 990001
)
BEGIN
    INSERT INTO DIM_ATENCION
    (
        atencion_key, id_registro_rel,
        codigo_anonimizado, nivel_eess,
        codigo_serv_prestacional,
        servicio_prestacional, sexo
    )
    VALUES
    (
        990001, 'PRUEBA001', 'PAC001', 'I-3',
        'SERV001', 'CONSULTA', 'M'
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM DIM_ATENCION WHERE atencion_key = 990002
)
BEGIN
    INSERT INTO DIM_ATENCION
    (
        atencion_key, id_registro_rel,
        codigo_anonimizado, nivel_eess,
        codigo_serv_prestacional,
        servicio_prestacional, sexo
    )
    VALUES
    (
        990002, 'TRIGGER001', 'PAC001', 'I-3',
        'SERV001', 'CONSULTA', 'M'
    );
END;
GO

-- 6. TABLA DE HECHOS
IF NOT EXISTS (
    SELECT 1 FROM FACT_CONSUMO_MEDICAMENTOS
    WHERE id_registro_rel = 'PRUEBA001'
)
BEGIN
    INSERT INTO FACT_CONSUMO_MEDICAMENTOS
    (
        id_registro_rel, fecha_key, medicamento_key,
        diagnostico_key, establecimiento_key, atencion_key,
        cantidad_entregada, valor_neto,
        dias_hosp, edad_dias, peso, ate_capita
    )
    VALUES
    (
        'PRUEBA001', 20241015, 990001,
        990001, 990001, 990001,
        2, 15.50, NULL, 3650, 70.50, 1.00
    );
END;

IF NOT EXISTS (
    SELECT 1 FROM FACT_CONSUMO_MEDICAMENTOS
    WHERE id_registro_rel = 'TRIGGER001'
)
BEGIN
    INSERT INTO FACT_CONSUMO_MEDICAMENTOS
    (
        id_registro_rel, fecha_key, medicamento_key,
        diagnostico_key, establecimiento_key, atencion_key,
        cantidad_entregada, valor_neto,
        dias_hosp, edad_dias, peso, ate_capita
    )
    VALUES
    (
        'TRIGGER001', 20241015, 990002,
        990001, 990001, 990002,
        1, 8.75, 2, 3650, 70.50, 1.00
    );
END;
GO

-- 7. COMPROBAR LOS DATOS
SELECT
    COUNT(*) AS TotalFilas,
    SUM(cantidad_entregada) AS TotalMedicamentos,
    SUM(valor_neto) AS ValorTotal
FROM FACT_CONSUMO_MEDICAMENTOS;
GO