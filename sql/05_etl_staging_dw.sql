-- =============================================================================
-- UNIVERSIDAD PRIVADA DEL NORTE
-- CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
-- PROYECTO: Sistema de Gestión de Datos - JOSBECORSA (RUC 20612766135)
-- ARCHIVO: sql/05_etl_staging_dw.sql (ACTUALIZADO)
-- DESCRIPCIÓN: Script ETL Completo con carga de Lotes, Clientes y Colores reales.
-- =============================================================================

USE JOSBECORSA_DW
GO

-- -----------------------------------------------------------------------------
-- PASO 1: CREACIÓN DEL PROCEDIMIENTO ALMACENADO PARA POBLAR DIM_TIEMPO
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE usp_Poblar_Dim_Tiempo
    @p_anio_inicio INT = 2025,
    @p_anio_fin INT = 2027
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @v_fecha_actual DATE = DATEFROMPARTS(@p_anio_inicio, 1, 1)
    DECLARE @v_fecha_limite DATE = DATEFROMPARTS(@p_anio_fin, 12, 31)

    WHILE @v_fecha_actual <= @v_fecha_limite
    BEGIN
        DECLARE @v_id_tiempo INT = CAST(CONVERT(VARCHAR(8), @v_fecha_actual, 112) AS INT)

        IF NOT EXISTS (SELECT 1 FROM DIM_TIEMPO WHERE id_tiempo = @v_id_tiempo)
        BEGIN
            INSERT INTO DIM_TIEMPO (id_tiempo, fecha, anio, trimestre, mes, nombre_mes, dia_semana)
            VALUES (
                @v_id_tiempo, @v_fecha_actual, YEAR(@v_fecha_actual), DATEPART(QUARTER, @v_fecha_actual),
                MONTH(@v_fecha_actual), DATENAME(MONTH, @v_fecha_actual), DATENAME(WEEKDAY, @v_fecha_actual)
            )
        END
        SET @v_fecha_actual = DATEADD(DAY, 1, @v_fecha_actual)
    END
END
GO

-- -----------------------------------------------------------------------------
-- PASO 2: EJECUCIÓN DEL CALENDARIO ANALÍTICO
-- -----------------------------------------------------------------------------
EXEC usp_Poblar_Dim_Tiempo @p_anio_inicio = 2025, @p_anio_fin = 2027
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
GO

-- 3.2 Carga Dimensión Cliente (NUEVO: Faltaba en el script original)
INSERT INTO DIM_CLIENTE (nombre_razon_social, tipo_cliente)
SELECT DISTINCT cliente_nombre, 'Mayorista'
FROM JOSBECORSA_OLTP.dbo.Venta_Puesto
WHERE cliente_nombre IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM DIM_CLIENTE dc WHERE dc.nombre_razon_social = JOSBECORSA_OLTP.dbo.Venta_Puesto.cliente_nombre
  )
GO

-- 3.3 Carga Dimensión Lote (NUEVO: Faltaba en el script original)
INSERT INTO DIM_LOTE (codigo_lote, origen_provincia, costo_logistico_estimado)
SELECT 
    l.codigo_lote, 
    l.origen_provincia,
    ISNULL((SELECT SUM(monto_flete) FROM JOSBECORSA_OLTP.dbo.Pago_Transportista t WHERE t.id_lote = l.id_lote), 0.00)
FROM JOSBECORSA_OLTP.dbo.Lote_Acopio l
WHERE NOT EXISTS (
    SELECT 1 FROM DIM_LOTE dl WHERE dl.codigo_lote = l.codigo_lote
)
GO

-- 3.4 Carga Dimensión Palta (CORREGIDO: Obtiene el color real de las jabas en lugar de 'N/A')
INSERT INTO DIM_PALTA (variedad_palta, calidad_palta, codigo_color_jaba)
SELECT DISTINCT 
    v.nombre_variedad, 
    c.nombre_calidad, 
    ISNULL(j.codigo_color_jaba, 'Sin Color')
FROM JOSBECORSA_OLTP.dbo.Detalle_Jaba j
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_VariedadPalta v ON j.id_variedad = v.id_variedad
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_Calidad c ON j.id_calidad = c.id_calidad
WHERE NOT EXISTS (
    SELECT 1 FROM DIM_PALTA dp 
    WHERE dp.variedad_palta = v.nombre_variedad 
      AND dp.calidad_palta = c.nombre_calidad
      AND dp.codigo_color_jaba = ISNULL(j.codigo_color_jaba, 'Sin Color')
)
GO

-- -----------------------------------------------------------------------------
-- PASO 4: CARGA INCREMENTAL A LA TABLA DE HECHOS (FACT_VENTAS)
-- -----------------------------------------------------------------------------
-- CORREGIDO: Se agregaron los cruces para Cliente y Lote y se insertan sus IDs para evitar NULLs
INSERT INTO FACT_VENTAS (
    id_tiempo, id_ubicacion, id_palta, id_lote, id_cliente, 
    kilos_vendidos, monto_subtotal, monto_descuento, monto_total
)
SELECT 
    CAST(CONVERT(VARCHAR(8), vp.fecha_venta, 112) AS INT) AS id_tiempo,
    du.id_ubicacion,
    dp.id_palta,
    dl.id_lote,
    dc.id_cliente,
    dvk.peso_vendido_kg,
    dvk.subtotal AS monto_subtotal,
    0.00 AS monto_descuento,
    dvk.subtotal AS monto_total
FROM JOSBECORSA_OLTP.dbo.Venta_Puesto vp
INNER JOIN JOSBECORSA_OLTP.dbo.Detalle_Venta_Kilo dvk ON vp.id_venta = dvk.id_venta
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_VariedadPalta v ON dvk.id_variedad = v.id_variedad
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_Calidad c ON dvk.id_calidad = c.id_calidad
INNER JOIN JOSBECORSA_OLTP.dbo.Cat_Ubicacion u ON vp.id_ubicacion = u.id_ubicacion
-- Cruces con Dimensiones
INNER JOIN DIM_UBICACION du ON du.nombre_ubicacion = u.nombre_ubicacion
INNER JOIN DIM_PALTA dp ON dp.variedad_palta = v.nombre_variedad AND dp.calidad_palta = c.nombre_calidad
INNER JOIN DIM_CLIENTE dc ON dc.nombre_razon_social = vp.cliente_nombre
LEFT JOIN JOSBECORSA_OLTP.dbo.Venta_Lote vl ON vl.id_detalle_venta = dvk.id_detalle_venta
LEFT JOIN JOSBECORSA_OLTP.dbo.Lote_Acopio la ON la.id_lote = vl.id_lote
LEFT JOIN DIM_LOTE dl ON dl.codigo_lote = la.codigo_lote
WHERE NOT EXISTS (
    SELECT 1 FROM FACT_VENTAS f
    WHERE f.id_tiempo = CAST(CONVERT(VARCHAR(8), vp.fecha_venta, 112) AS INT)
      AND f.id_ubicacion = du.id_ubicacion
      AND f.id_palta = dp.id_palta
      AND ISNULL(f.id_lote, 0) = ISNULL(dl.id_lote, 0)
      AND f.id_cliente = dc.id_cliente
      AND f.kilos_vendidos = dvk.peso_vendido_kg
)
GO