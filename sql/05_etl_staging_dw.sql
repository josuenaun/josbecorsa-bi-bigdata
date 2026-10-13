-- =============================================================================
-- UNIVERSIDAD PRIVADA DEL NORTE
-- CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
-- PROYECTO: Sistema de Gestión de Datos - JOSBECORSA (RUC 20612766135)
-- ARCHIVO: sql/05_etl_staging_dw.sql
-- DESCRIPCIÓN: Script ETL Completo (Creación de SP de Tiempo + Carga OLTP -> DW)
-- =============================================================================

USE JOSBECORSA_DW;
GO

-- -----------------------------------------------------------------------------
-- PASO 1: CREACIÓN DEL PROCEDIMIENTO ALMACENADO PARA POBLAR DIM_TIEMPO
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_Poblar_Dim_Tiempo
    @p_anio_inicio INT = 2025,
    @p_anio_fin INT = 2027
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @v_fecha_actual DATE = DATEFROMPARTS(@p_anio_inicio, 1, 1);
    DECLARE @v_fecha_limite DATE = DATEFROMPARTS(@p_anio_fin, 12, 31);

    WHILE @v_fecha_actual <= @v_fecha_limite
    BEGIN
        DECLARE @v_id_tiempo INT = CAST(CONVERT(VARCHAR(8), @v_fecha_actual, 112) AS INT);

        IF NOT EXISTS (SELECT 1 FROM DIM_TIEMPO WHERE id_tiempo = @v_id_tiempo)
        BEGIN
            INSERT INTO DIM_TIEMPO (id_tiempo, fecha, anio, trimestre, mes, nombre_mes, dia_semana)
            VALUES (
                @v_id_tiempo,
                @v_fecha_actual,
                YEAR(@v_fecha_actual),
                DATEPART(QUARTER, @v_fecha_actual),
                MONTH(@v_fecha_actual),
                DATENAME(MONTH, @v_fecha_actual),
                DATENAME(WEEKDAY, @v_fecha_actual)
            )
        END

        SET @v_fecha_actual = DATEADD(DAY, 1, @v_fecha_actual);
    END
END;
GO

-- -----------------------------------------------------------------------------
-- PASO 2: EJECUCIÓN DEL PROCEDIMIENTO PARA GENERAR EL CALENDARIO ANALÍTICO
-- -----------------------------------------------------------------------------
EXEC usp_Poblar_Dim_Tiempo @p_anio_inicio = 2025, @p_anio_fin = 2027;
GO

-- -----------------------------------------------------------------------------
-- PASO 3: CARGA INCREMENTAL DE DIMENSIONES (SIN DUPLICADOS)
-- -----------------------------------------------------------------------------

-- 3.1 Carga Dimensión Ubicación
INSERT INTO DIM_UBICACION (nombre_ubicacion, tipo_ubicacion)
SELECT u.nombre_ubicacion, u.tipo_ubicacion 
FROM JOSBECORSA_OLTP.dbo.Cat_Ubicacion u
WHERE NOT EXISTS (
    SELECT 1 FROM DIM_UBICACION du WHERE du.nombre_ubicacion = u.nombre_ubicacion
)

-- 3.2 Carga Dimensión Palta
INSERT INTO DIM_PALTA (variedad_palta, calidad_palta, codigo_color_jaba)
SELECT DISTINCT v.nombre_variedad, c.nombre_calidad, 'N/A'
FROM JOSBECORSA_OLTP.dbo.Cat_VariedadPalta v
CROSS JOIN JOSBECORSA_OLTP.dbo.Cat_Calidad c
WHERE NOT EXISTS (
    SELECT 1 FROM DIM_PALTA dp 
    WHERE dp.variedad_palta = v.nombre_variedad AND dp.calidad_palta = c.nombre_calidad
)
GO

-- -----------------------------------------------------------------------------
-- PASO 4: CARGA INCREMENTAL A LA TABLA DE HECHOS (FACT_VENTAS)
-- -----------------------------------------------------------------------------
INSERT INTO FACT_VENTAS (id_tiempo, id_ubicacion, id_palta, kilos_vendidos, monto_total)
SELECT 
    CAST(CONVERT(VARCHAR(8), vp.fecha_venta, 112) AS INT) AS id_tiempo,
    du.id_ubicacion,
    dp.id_palta,
    dvk.peso_vendido_kg,
    dvk.subtotal
FROM JOSBECORSA_OLTP.dbo.Venta_Puesto vp
INNER JOIN JOSBECORSA_OLTP.dbo.Detalle_Venta_Kilo dvk ON vp.id_venta = dvk.id_venta
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_VariedadPalta v ON dvk.id_variedad = v.id_variedad
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_Calidad c ON dvk.id_calidad = c.id_calidad
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_Ubicacion u ON vp.id_ubicacion = u.id_ubicacion
INNER JOIN DIM_UBICACION du ON du.nombre_ubicacion = u.nombre_ubicacion
INNER JOIN DIM_PALTA dp ON dp.variedad_palta = v.nombre_variedad AND dp.calidad_palta = c.nombre_calidad
WHERE NOT EXISTS (
    SELECT 1 FROM FACT_VENTAS f
    WHERE f.id_tiempo = CAST(CONVERT(VARCHAR(8), vp.fecha_venta, 112) AS INT)
      AND f.id_ubicacion = du.id_ubicacion
      AND f.id_palta = dp.id_palta
      AND f.kilos_vendidos = dvk.peso_vendido_kg
      AND f.monto_total = dvk.subtotal
)
GO