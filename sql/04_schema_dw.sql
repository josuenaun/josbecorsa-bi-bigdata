-- =============================================================================
-- UNIVERSIDAD PRIVADA DEL NORTE
-- CARRERA: Ingeniería de Sistemas Computacionales
-- CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
-- PROYECTO: Sistema de Gestión de Datos - JOSBECORSA (RUC 20612766135)
-- ARCHIVO: sql/04_schema_dw.sql
-- DESCRIPCIÓN: Definición DDL del esquema dimensional Data Warehouse (JOSBECORSA_DW)
--              siguiendo el Modelo Estrella de Ralph Kimball.
-- =============================================================================

USE master
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'JOSBECORSA_DW')
BEGIN
    ALTER DATABASE JOSBECORSA_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE JOSBECORSA_DW
END
GO

CREATE DATABASE JOSBECORSA_DW
GO

USE JOSBECORSA_DW
GO

-- -----------------------------------------------------------------------------
-- 1. TABLAS DIMENSIONALES (DIMENSIONES)
-- -----------------------------------------------------------------------------

-- Dimensión Cliente
CREATE TABLE DIM_CLIENTE (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre_razon_social VARCHAR(100) NOT NULL,
    tipo_cliente VARCHAR(30) NOT NULL DEFAULT 'Mayorista'
)
GO

-- Dimensión Lote 
CREATE TABLE DIM_LOTE (
    id_lote INT IDENTITY(1,1) PRIMARY KEY,
    codigo_lote VARCHAR(20) NOT NULL,
    origen_provincia VARCHAR(50) NOT NULL,
    costo_logistico_estimado DECIMAL(10,2) NOT NULL DEFAULT 0.00
)
GO

-- Dimensión Producto 
CREATE TABLE DIM_PALTA (
    id_palta INT IDENTITY(1,1) PRIMARY KEY,
    variedad_palta VARCHAR(30) NOT NULL,
    calidad_palta VARCHAR(30) NOT NULL,
    codigo_color_jaba VARCHAR(20) NULL
)
GO

-- Dimensión Tiempo 
CREATE TABLE DIM_TIEMPO (
    id_tiempo INT PRIMARY KEY, -- Formato YYYYMMDD (Ej. 20260810)
    fecha DATE NOT NULL,
    anio INT NOT NULL,
    trimestre INT NOT NULL CHECK (trimestre BETWEEN 1 AND 4),
    mes INT NOT NULL CHECK (mes BETWEEN 1 AND 12),
    nombre_mes VARCHAR(20) NOT NULL,
    dia_semana VARCHAR(20) NOT NULL
)
GO

-- Dimensión Ubicación (Puestos de Venta y Almacenes)
CREATE TABLE DIM_UBICACION (
    id_ubicacion INT IDENTITY(1,1) PRIMARY KEY,
    nombre_ubicacion VARCHAR(50) NOT NULL,
    tipo_ubicacion VARCHAR(20) NOT NULL CHECK (tipo_ubicacion IN ('Principal', 'Frio', 'Contingencia'))
)
GO

-- -----------------------------------------------------------------------------
-- 2. TABLA DE HECHOS 
-- -----------------------------------------------------------------------------

CREATE TABLE FACT_VENTAS (
    id_hecho_venta INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves Foráneas (Relaciones con el Modelo Estrella)
    id_tiempo INT NOT NULL FOREIGN KEY REFERENCES DIM_TIEMPO(id_tiempo),
    id_ubicacion INT NOT NULL FOREIGN KEY REFERENCES DIM_UBICACION(id_ubicacion),
    id_palta INT NOT NULL FOREIGN KEY REFERENCES DIM_PALTA(id_palta),
    id_lote INT NULL FOREIGN KEY REFERENCES DIM_LOTE(id_lote),
    id_cliente INT NULL FOREIGN KEY REFERENCES DIM_CLIENTE(id_cliente),
    
    -- Métricas y Hechos Cuantitativos
    kilos_vendidos DECIMAL(8,2) NOT NULL CHECK (kilos_vendidos > 0.00),
    monto_subtotal DECIMAL(18,2) NULL CHECK (monto_subtotal >= 0.00),
    monto_descuento DECIMAL(18,2) NULL DEFAULT 0.00,
    monto_total DECIMAL(10,2) NOT NULL CHECK (monto_total >= 0.00)
)
GO