-- =============================================================================
-- UNIVERSIDAD PRIVADA DEL NORTE
-- CARRERA: Ingeniería de Sistemas Computacionales
-- CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
-- PROYECTO: Sistema de Gestión de Datos - JOSBECORSA (RUC 20612766135)
-- ARCHIVO: sql/03_triggers_transactions.sql
-- DESCRIPCIÓN: Implementación de Triggers DML para auditar/restringir cambio 
-- de precios, Triggers DDL para protección del esquema y
-- Procedimiento Transaccional ACID con SAVEPOINT.
-- =============================================================================

USE JOSBECORSA_OLTP;
GO

-- -----------------------------------------------------------------------------
-- 1. TABLA DE AUDITORÍA DE SEGURIDAD
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Log_Auditoria_Precios')
BEGIN
    CREATE TABLE Log_Auditoria_Precios (
        id_log INT IDENTITY(1,1) PRIMARY KEY,
        id_detalle_venta INT NOT NULL,
        precio_anterior DECIMAL(6,2) NOT NULL,
        precio_nuevo DECIMAL(6,2) NOT NULL,
        usuario_modificacion VARCHAR(50) NOT NULL DEFAULT SUSER_NAME(),
        fecha_modificacion DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

-- -----------------------------------------------------------------------------
-- 2. TRIGGER DML: AUDITORÍA Y CONTROL DE CAMBIO DE PRECIOS POR KILO (SEMANA 04)
-- -----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_AuditarYControlarPrecioKilo
ON Detalle_Venta_Kilo
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @v_precio_anterior DECIMAL(6,2);
    DECLARE @v_precio_nuevo DECIMAL(6,2);
    DECLARE @v_id_detalle INT;

    SELECT @v_precio_anterior = precio_por_kg FROM deleted;
    SELECT @v_precio_nuevo = precio_por_kg, @v_id_detalle = id_detalle_venta FROM inserted;

    IF @v_precio_nuevo > (@v_precio_anterior * 1.30)
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('!! OPERACIÓN CANCELADA: El incremento del precio por kilo no puede superar el 30%% del valor previo.', 16, 1);
        RETURN;
    END

    INSERT INTO Log_Auditoria_Precios (id_detalle_venta, precio_anterior, precio_nuevo)
    VALUES (@v_id_detalle, @v_precio_anterior, @v_precio_nuevo);
END;
GO

-- -----------------------------------------------------------------------------
-- 3. TRIGGER DDL: PROTECCIÓN CONTRA ELIMINACIÓN DE TABLAS (SEMANA 04)
-- -----------------------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_PrevencionDropTable
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    RAISERROR('!! ACCIÓN PROHIBIDA: Se requiere autorización explícita para eliminar estructuras en JOSBECORSA_OLTP.', 16, 1);
    ROLLBACK;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. PROCEDIMIENTO TRANSACCIONAL ACID CON SAVEPOINT (SEMANA 04)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_RegistrarInboundLoteTransaccional
    @p_codigo_lote VARCHAR(20),
    @p_origen VARCHAR(50),
    @p_total_jabas INT,
    @p_conductor VARCHAR(100),
    @p_placa VARCHAR(15),
    @p_monto_flete DECIMAL(10,2),
    @p_cuadrilla VARCHAR(50),
    @p_tarifa_estiba DECIMAL(6,2),
    @p_resultado VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_id_lote INT;

    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO Lote_Acopio (codigo_lote, fecha_acopio, origen_provincia, total_jabas_recibidas)
        VALUES (@p_codigo_lote, GETDATE(), @p_origen, @p_total_jabas);
        
        SET @v_id_lote = SCOPE_IDENTITY();

        SAVE TRANSACTION SavePoint_LoteCreado;

        INSERT INTO Pago_Transportista (id_lote, nombre_conductor, placa_vehiculo, monto_flete, fecha_pago)
        VALUES (@v_id_lote, @p_conductor, @p_placa, @p_monto_flete, GETDATE());

        INSERT INTO Pago_Estibador (id_lote, cuadrilla_nombre, jabas_descargadas, tarifa_por_jaba)
        VALUES (@v_id_lote, @p_cuadrilla, @p_total_jabas, @p_tarifa_estiba);

        COMMIT TRANSACTION;
        SET @p_resultado = 'PROCESO EXITOSO: Lote ID ' + CAST(@v_id_lote AS VARCHAR) + ' y pagos de logística registrados de forma atómica.';
    
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        SET @p_resultado = 'ERROR TRANSACCIONAL: La operación fue revertida. Causa: ' + ERROR_MESSAGE();
    END CATCH
END;
GO