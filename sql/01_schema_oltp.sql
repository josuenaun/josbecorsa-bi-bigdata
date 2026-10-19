-- =============================================================================
-- PROYECTO: Sistema de Gestión de Datos JOSBECORSA (RUC: 20612766135)
-- ARCHIVO:  sql/01_schema_oltp.sql
-- CURSO:    Base de Datos Avanzadas y Big Data (ISOF1304)
-- PROPÓSITO: Definición DDL del esquema transaccional OLTP en SQL Server
--            incluyendo la inserción de los catálogos maestros base.
-- =============================================================================

USE master
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'JOSBECORSA_OLTP')
BEGIN
    ALTER DATABASE JOSBECORSA_OLTP SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE JOSBECORSA_OLTP
END
GO

CREATE DATABASE JOSBECORSA_OLTP
GO

USE JOSBECORSA_OLTP
GO

-- -----------------------------------------------------------------------------
-- 1. TABLAS CATÁLOGO / MAESTRAS 
-- -----------------------------------------------------------------------------

CREATE TABLE Cat_Calidad (
    id_calidad INT IDENTITY(1,1) PRIMARY KEY,
    nombre_calidad VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(100) NULL
)
GO

CREATE TABLE Cat_VariedadPalta (
    id_variedad INT IDENTITY(1,1) PRIMARY KEY,
    nombre_variedad VARCHAR(30) NOT NULL UNIQUE
)
GO

CREATE TABLE Cat_Ubicacion (
    id_ubicacion INT IDENTITY(1,1) PRIMARY KEY,
    nombre_ubicacion VARCHAR(50) NOT NULL UNIQUE,
    tipo_ubicacion VARCHAR(20) NOT NULL CHECK (tipo_ubicacion IN ('Principal', 'Frio', 'Contingencia'))
)
GO

CREATE TABLE Cat_Cliente (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre_razon_social VARCHAR(150) NOT NULL UNIQUE,
    tipo_cliente VARCHAR(50) NOT NULL
)
GO

-- -----------------------------------------------------------------------------
-- 2. OPERACIONES DE ACOPIO Y LOGÍSTICA
-- -----------------------------------------------------------------------------

CREATE TABLE Lote_Acopio (
    id_lote INT IDENTITY(1,1) PRIMARY KEY,
    codigo_lote VARCHAR(20) NOT NULL UNIQUE,
    fecha_acopio DATETIME NOT NULL DEFAULT GETDATE(),
    origen_provincia VARCHAR(50) NOT NULL,
    total_jabas_recibidas INT NOT NULL CHECK (total_jabas_recibidas > 0)
)
GO

CREATE TABLE Detalle_Jaba (
    id_jaba INT IDENTITY(1,1) PRIMARY KEY,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    id_variedad INT NOT NULL FOREIGN KEY REFERENCES Cat_VariedadPalta(id_variedad),
    id_calidad INT NOT NULL FOREIGN KEY REFERENCES Cat_Calidad(id_calidad),
    codigo_color_jaba VARCHAR(20) NOT NULL,
    peso_bruto_kg DECIMAL(8,2) NOT NULL CHECK (peso_bruto_kg > 0)
)
GO

CREATE TABLE Pago_Transportista (
    id_pago_transporte INT IDENTITY(1,1) PRIMARY KEY,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    nombre_conductor VARCHAR(100) NOT NULL,
    placa_vehiculo VARCHAR(15) NOT NULL,
    monto_flete DECIMAL(10,2) NOT NULL CHECK (monto_flete >= 0),
    fecha_pago DATETIME NOT NULL DEFAULT GETDATE()
)
GO

CREATE TABLE Pago_Estibador (
    id_pago_estiba INT IDENTITY(1,1) PRIMARY KEY,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    cuadrilla_nombre VARCHAR(50) NOT NULL,
    jabas_descargadas INT NOT NULL CHECK (jabas_descargadas > 0),
    tarifa_por_jaba DECIMAL(6,2) NOT NULL CHECK (tarifa_por_jaba > 0),
    monto_total AS (jabas_descargadas * tarifa_por_jaba) PERSISTED
)
GO

-- -----------------------------------------------------------------------------
-- 3. VENTAS (REGLA DE NEGOCIO: ESTRICTAMENTE POR KILOS)
-- -----------------------------------------------------------------------------

CREATE TABLE Venta_Puesto (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_ubicacion INT NOT NULL FOREIGN KEY REFERENCES Cat_Ubicacion(id_ubicacion),
    fecha_venta DATETIME NOT NULL DEFAULT GETDATE(),
    cliente_nombre VARCHAR(100) NULL,
    monto_total_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00
)
GO

CREATE TABLE Detalle_Venta_Kilo (
    id_detalle_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_venta INT NOT NULL FOREIGN KEY REFERENCES Venta_Puesto(id_venta) ON DELETE CASCADE,
    id_variedad INT NOT NULL FOREIGN KEY REFERENCES Cat_VariedadPalta(id_variedad),
    id_calidad INT NOT NULL FOREIGN KEY REFERENCES Cat_Calidad(id_calidad),
    peso_vendido_kg DECIMAL(8,2) NOT NULL CHECK (peso_vendido_kg > 0.00),
    precio_por_kg DECIMAL(6,2) NOT NULL CHECK (precio_por_kg > 0.00),
    subtotal AS (peso_vendido_kg * precio_por_kg) PERSISTED
)
GO

CREATE TABLE Venta_Lote (
    id_venta_lote INT IDENTITY(1,1) PRIMARY KEY,
    id_detalle_venta INT NOT NULL FOREIGN KEY REFERENCES Detalle_Venta_Kilo(id_detalle_venta) ON DELETE CASCADE,
    id_lote INT NOT NULL FOREIGN KEY REFERENCES Lote_Acopio(id_lote),
    kilos_descontados DECIMAL(8,2) NOT NULL CHECK (kilos_descontados > 0.00)
)
GO

-- -----------------------------------------------------------------------------
-- 4. INSERCIÓN DE DATOS
-- -----------------------------------------------------------------------------

-- Inserción de Variedades de Palta
INSERT INTO Cat_VariedadPalta (nombre_variedad) VALUES 
('Fuerte'), 
('Hass'), 
('Nabal'), 
('Villacampa');
GO

-- Inserción de Calidades de Palta
INSERT INTO Cat_Calidad (nombre_calidad, descripcion) VALUES 
('1era', 'Palta de máxima calidad premium'),
('2da', 'Calidad media alta con pequeños defectos'),
('3era', 'Calidad estándar mercado local'),
('4ta', 'Calidad económica'),
('Semimanchada', 'Manchas menores en cáscara'),
('Manchada', 'Manchas visibles sin afectación interna'),
('Limpia', 'Libre de impurezas');
GO

-- Inserción de Ubicaciones
INSERT INTO Cat_Ubicacion (nombre_ubicacion, tipo_ubicacion) VALUES 
('Cámara de frío', 'Frio'),
('Puesto principal', 'Principal'),
('Contingencia Tía/Amiga', 'Contingencia');
GO

-- Inserción de Clientes
INSERT INTO Cat_Cliente (nombre_razon_social, tipo_cliente) VALUES 
('Comercializadora AgroLima S.A.C.', 'Mayorista'),
('Distribuidora San Juan E.I.R.L.', 'Distribuidor'),
('Supermercados El Frutal', 'Cadena'),
('Frutería Doña Maria', 'Minorista'),
('Mercado Central Sur - Puesto 45', 'Mayorista'),
('Agroexportadora Chanchamayo', 'Mayorista');
GO