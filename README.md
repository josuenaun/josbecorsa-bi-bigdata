# Sistema de Inteligencia de Negocios y Gestión de Datos - JOSBECORSA

**Curso:** Base de Datos Avanzadas y Big Data (ISOF1304)  
**Institución:** Universidad Privada del Norte (UPN)  
**Periodo Lectivo:** 2026-2  
**Empresa:** Comercializadora y Acopiadora de Palta JOSBECORSA (RUC: 20612766135)

---

## 📌 Descripción del Proyecto
Solución integral de arquitectura de datos orientada a resolver la pérdida de trazabilidad en la comercialización de palta por kilogramos, automatizar la liquidación de fletes/estiba y centralizar indicadores estratégicos. El sistema integra una capa transaccional en SQL Server, gestión NoSQL de incidencias logísticas en MongoDB, orquestación ETL automatizada en Integration Services (SSIS), un Data Warehouse bajo el modelo estrella de Ralph Kimball y dashboards ejecutivos en Power BI.

---

## 🛠️ Requisitos Previos y Dependencias
Para desplegar y reproducir la solución se requiere contar con las siguientes herramientas instaladas:

- **Motor de Base de Datos:** Microsoft SQL Server 2022 o superior + SQL Server Management Studio (SSMS).
- **Entorno ETL:** Visual Studio 2022 con la extensión *SQL Server Integration Services Projects*.
- **Explotación Analítica:** Power BI Desktop (Versión 2025/2026).
- **Base de Datos NoSQL:** MongoDB 6.0+ o MongoDB Compass + Node.js (opcional para ejecución de scripts `.js`).
- **Planilla Base:** Microsoft Excel (para la fuente cruda en `data/raw/`).

---

## 📁 Estructura del Repositorio

```text
josbecorsa-bi-bigdata/
├── bi_powerbi/
│   └── JOSBECORSA_Dashboard.pbix      # Dashboard ejecutable e interactivo de Power BI
├── data/
│   └── raw/
│       └── JOSBECORSA_Dataset_SSIS_Datos_Crudos.xlsx  # Dataset transaccional fuente (11 pestañas)
├── nosql/
│   ├── 01_mongodb_init.js             # Script BSON de inicialización de colecciones en MongoDB
│   └── incidencias_sensores.json      # Logs no estructurados de eventos y lecturas de frío
├── sql/
│   ├── 01_schema_oltp.sql             # DDL: Creación de la base de datos transaccional JOSBECORSA_OLTP
│   ├── 02_automation_objects.sql      # DDL: Vistas, Funciones escalares y Stored Procedures
│   ├── 03_triggers_transactions.sql   # DDL: Triggers de auditoría DML/DDL y Transacciones ACID
│   ├── 04_schema_dw.sql               # DDL: Creación del Data Warehouse JOSBECORSA_DW (Modelo Estrella)
│   └── 05_etl_staging_dw.sql          # T-SQL: Script de carga incremental y llenado de DIM_TIEMPO
├── ssis/
│   └── Package.dtsx                   # Paquete de flujo de control y datos en Integration Services
└── README.md                          # Guía de reproducción y documentación técnica