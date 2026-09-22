-- =============================================================================
-- UNIVERSIDAD PRIVADA DEL NORTE
-- CARRERA: Ingeniería de Sistemas Computacionales
-- CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
-- PROYECTO: Sistema de Gestión de Datos - JOSBECORSA (RUC 20612766135)
-- ARCHIVO: sql/02_automation_objects.sql
-- DESCRIPCIÓN: Implementación de Objetos de Automatización: Vistas, Funciones
-- Escalares y Stored Procedures con manejo de excepciones.
-- =============================================================================

USE JOSBECORSA_OLTP;
GO

-- -----------------------------------------------------------------------------
-- 1. VISTAS DE NEGOCIO (SEMANA 02)
-- -----------------------------------------------------------------------------

-- Vista para consolidar el inventario de jabas por variedad y calidad
CREATE OR ALTER VIEW vw_Resumen_Acopio_Jabas
AS
SELECT 
    l.codigo_lote,
    l.origen_provincia,
    v.nombre_variedad,
    c.nombre_calidad,
    COUNT(j.id_jaba) AS total_jabas,
    SUM(j.peso_bruto_kg) AS peso_total_kg
FROM Lote_Acopio l
INNER JOIN Detalle_Jaba j ON l.id_lote = j.id_lote
INNER JOIN Cat_VariedadPalta v ON j.id_variedad = v.id_variedad
INNER JOIN Cat_Calidad c ON j.id_calidad = c.id_calidad
GROUP BY l.codigo_lote, l.origen_provincia, v.nombre_variedad, c.nombre_calidad;
GO

-- -----------------------------------------------------------------------------
-- 2. FUNCIONES ALMACENADAS ESCALARES (SEMANA 03)
-- -----------------------------------------------------------------------------

-- Función para calcular el costo total de descarga por cuadrilla de estibadores
CREATE OR ALTER FUNCTION fu_CalcularCostoEstiba
(
    @p_jabas INT,
    @p_tarifa DECIMAL(6,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @v_monto_total DECIMAL(10,2);
    IF @p_jabas IS NULL OR @p_jabas <= 0
        SET @v_monto_total = 0.00;
    ELSE
        SET @v_monto_total = @p_jabas * @p_tarifa;
        
    RETURN @v_monto_total;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. PROCEDIMIENTOS ALMACENADOS CON CONTROL DE EXCEPCIONES (SEMANA 02)
-- -----------------------------------------------------------------------------

-- SP para registrar transacciones de Venta en Puesto 
CREATE OR ALTER PROCEDURE usp_RegistrarVentaKilo
    @p_id_ubicacion INT,
    @p_cliente_nombre VARCHAR(100),
    @p_id_variedad INT,
    @p_id_calidad INT,
    @p_peso_kg DECIMAL(8,2),
    @p_precio_por_kg DECIMAL(6,2),
    @p_mensaje_salida VARCHAR(300) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_id_venta INT;
    DECLARE @v_subtotal DECIMAL(10,2);

    BEGIN TRY
        IF @p_peso_kg <= 0 OR @p_precio_por_kg <= 0
        BEGIN
            RAISERROR('El peso vendido y el precio por kilo deben ser mayores a cero.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Cat_Ubicacion WHERE id_ubicacion = @p_id_ubicacion)
        BEGIN
            RAISERROR('La ubicación especificada no existe en la base de datos.', 16, 1);
            RETURN;
        END

        INSERT INTO Venta_Puesto (id_ubicacion, fecha_venta, cliente_nombre, monto_total_venta)
        VALUES (@p_id_ubicacion, GETDATE(), @p_cliente_nombre, 0.00);

        SET @v_id_venta = SCOPE_IDENTITY();
        SET @v_subtotal = @p_peso_kg * @p_precio_por_kg;

        INSERT INTO Detalle_Venta_Kilo (id_venta, id_variedad, id_calidad, peso_vendido_kg, precio_por_kg)
        VALUES (@v_id_venta, @p_id_variedad, @p_id_calidad, @p_peso_kg, @p_precio_por_kg);

        UPDATE Venta_Puesto
        SET monto_total_venta = @v_subtotal
        WHERE id_venta = @v_id_venta;

        SET @p_mensaje_salida = 'Venta ID ' + CAST(@v_id_venta AS VARCHAR) + ' registrada con éxito. Subtotal: S/ ' + CAST(@v_subtotal AS VARCHAR);
    END TRY
    BEGIN CATCH
        SET @p_mensaje_salida = 'ERROR en usp_RegistrarVentaKilo: ' + ERROR_MESSAGE() + ' (Línea: ' + CAST(ERROR_LINE() AS VARCHAR) + ')';
    END CATCH
END;
GO