-- =============================================================================
-- PROYECTO: Sistema de Gestión de Datos JOSBECORSA (RUC: 20612766135)
-- ARCHIVO:  sql/01_schema_oltp.sql
-- CURSO:    Base de Datos Avanzadas y Big Data (ISOF1304) - Semana 01-05
-- PROPÓSITO: Definición DDL del esquema transaccional OLTP en SQL Server.
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'JOSBECORSA_OLTP')
BEGIN
    ALTER DATABASE JOSBECORSA_OLTP SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE JOSBECORSA_OLTP;
END
GO

CREATE DATABASE JOSBECORSA_OLTP;
GO

USE JOSBECORSA_OLTP;
GO

-- -----------------------------------------------------------------------------
-- 1. TABLAS CATÁLOGO / MAESTRAS
-- -----------------------------------------------------------------------------

-- Categorías de calidad: 1era, 2da, 3era, 4ta, Semimanchada, Manchada
CREATE TABLE Cat_Calidad (
    id_calidad INT IDENTITY(1,1) PRIMARY KEY,
    nombre_calidad VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(100) NULL
);

-- Tipos de palta: Fuerte, Hass, Nabal
CREATE TABLE Cat_VariedadPalta (
    id_variedad INT IDENTITY(1,1) PRIMARY KEY,
    nombre_variedad VARCHAR(30) NOT NULL UNIQUE
);

-- Ubicaciones / Puestos: Cámara de frío, Puesto principal, Contingencia Tía/Amiga
CREATE TABLE Cat_Ubicacion (
    id_ubicacion INT IDENTITY(1,1) PRIMARY KEY,
    nombre_ubicacion VARCHAR(50) NOT NULL UNIQUE,
    tipo_ubicacion VARCHAR(20) NOT NULL CHECK (tipo_ubicacion IN ('Principal', 'Frio', 'Contingencia'))
);

-- -----------------------------------------------------------------------------
-- 2. OPERACIONES DE ACOPIO Y LOGÍSTICA
-- -----------------------------------------------------------------------------

-- Lotes provenientes de provincia
CREATE TABLE Lote_Acopio (
    id_lote INT IDENTITY(1,1) PRIMARY KEY,
    codigo_lote VARCHAR(20) NOT NULL UNIQUE,
    fecha_acopio DATETIME NOT NULL DEFAULT GETDATE(),
    origen_provincia VARCHAR(50) NOT NULL,
    total_jabas_recibidas INT NOT NULL CHECK (total_jabas_recibidas > 0)
);

-- Detalle del empaque en jabas codificadas por color
CREATE TABLE Detalle_Jaba (
    id_jaba INT IDENTITY(1,1) PRIMARY KEY,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    id_variedad INT NOT NULL FOREIGN KEY REFERENCES Cat_VariedadPalta(id_variedad),
    id_calidad INT NOT NULL FOREIGN KEY REFERENCES Cat_Calidad(id_calidad),
    codigo_color_jaba VARCHAR(20) NOT NULL,
    peso_bruto_kg DECIMAL(8,2) NOT NULL CHECK (peso_bruto_kg > 0)
);

-- Pagos a Transportistas 
CREATE TABLE Pago_Transportista (
    id_pago_transporte INT IDENTITY(1,1) PRIMARY KEY,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    nombre_conductor VARCHAR(100) NOT NULL,
    placa_vehiculo VARCHAR(15) NOT NULL,
    monto_flete DECIMAL(10,2) NOT NULL CHECK (monto_flete >= 0),
    fecha_pago DATETIME NOT NULL DEFAULT GETDATE()
);

-- Pagos a Estibadores 
CREATE TABLE Pago_Estibador (
    id_pago_estiba INT IDENTITY(1,1) PRIMARY KEY,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    cuadrilla_nombre VARCHAR(50) NOT NULL,
    jabas_descargadas INT NOT NULL CHECK (jabas_descargadas > 0),
    tarifa_por_jaba DECIMAL(6,2) NOT NULL CHECK (tarifa_por_jaba > 0),
    monto_total AS (jabas_descargadas * tarifa_por_jaba) PERSISTED
);

-- -----------------------------------------------------------------------------
-- 3. VENTAS (REGLA DE NEGOCIO: ESTRICTAMENTE POR KILOS)
-- -----------------------------------------------------------------------------

CREATE TABLE Venta_Puesto (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_ubicacion INT NOT NULL FOREIGN KEY REFERENCES Cat_Ubicacion(id_ubicacion),
    fecha_venta DATETIME NOT NULL DEFAULT GETDATE(),
    cliente_nombre VARCHAR(100) NULL,
    monto_total_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

CREATE TABLE Detalle_Venta_Kilo (
    id_detalle_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_venta INT NOT NULL FOREIGN KEY REFERENCES Venta_Puesto(id_venta) ON DELETE CASCADE,
    id_variedad INT NOT NULL FOREIGN KEY REFERENCES Cat_VariedadPalta(id_variedad),
    id_calidad INT NOT NULL FOREIGN KEY REFERENCES Cat_Calidad(id_calidad),
    peso_vendido_kg DECIMAL(8,2) NOT NULL CHECK (peso_vendido_kg > 0.00), -- Venta estricta en kilos
    precio_por_kg DECIMAL(6,2) NOT NULL CHECK (precio_por_kg > 0.00),
    subtotal AS (peso_vendido_kg * precio_por_kg) PERSISTED
);
GO