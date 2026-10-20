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

## 💡 Decisiones de Negocio, Conclusiones y Recomendaciones

### 🎯 Decisiones Estratégicas de Negocio
1. **Optimización de Rutas de Acopio Provincial-Lima:** A partir de los indicadores de flete por kilogramo analizados en Power BI, se renegociaron las tarifas logísticas en las rutas de acopio de provincia, reduciendo el costo unitario de transporte en un 12%.
2. **Control Estricto de Mermas en Cadena de Frío:** La integración de logs no estructurados en MongoDB para el monitoreo de temperatura durante el traslado permitió establecer un protocolo de alerta temprana, disminuyendo la pérdida de fruta por descalibración térmica.
3. **Protección Comercial por Variación de Precios:** La implementación del trigger de seguridad comercial (T-01) bloquea variaciones de precio mayores al 30%, asegurando consistencia en la facturación a clientes mayoristas.

### 📌 Conclusiones Técnicas y Operativas
- **Trazabilidad Integral de Palta por Kilogramo:** Se logró consolidar y limpiar la información dispersa de 11 hojas de Excel en una base de datos relacional estandarizada (`JOSBECORSA_OLTP`), eliminando duplicados mediante el paquete ETL en SSIS.
- **Modelado Dimensional Orientado al Negocio:** El Data Warehouse diseñado bajo el esquema estrella de Kimball (`JOSBECORSA_DW`) redujo los tiempos de consulta analítica en comparación con las ejecuciones sobre el sistema transaccional.
- **Visibilidad Ejecutiva Unificada:** El dashboard desarrollado en Power BI facilita el seguimiento interactivo de volúmenes de acopio, márgenes de ganancia y rendimiento logístico por región y proveedor.

### 💡 Recomendaciones para la Continuidad
- **Automatización de Ejecuciones ETL:** Programar la ejecución automática del paquete `Package.dtsx` mediante SQL Server Agent para asegurar cargas nocturnas incrementales sin intervención manual.
- **Expansión de Cobertura NoSQL:** Extender el uso de MongoDB para almacenar encuestas de satisfacción, observaciones de calidad en destino y retroalimentación directa de los compradores en el mercado mayorista.

## 📁 Estructura del Repositorio

```text
josbecorsa-bi-bigdata/
├── bi_powerbi/
│   └── JOSBECORSA_Dashboard.pbix      # Dashboard ejecutable e interactivo de Power BI
├── data/
│   └── raw/
│       └── JOSBECORSA_Dataset_SSIS_Datos_Crudos.xlsx  # Dataset transaccional fuente (11 pestañas)
├── evidencias/                        # Repositorio de capturas, documentos y pruebas técnicas
│   ├── E02/                           # Captura de eliminación de duplicados en SSIS
│   ├── E03/                           # Captura de pruebas de triggers en SSMS
│   ├── E04/                           # Captura de Control Flow del paquete ETL (.dtsx)
│   ├── E05/                           # Diagrama de arquitectura de flujo de datos
│   ├── E07/                           # Resultados de dashboards en Power BI
│   └── ...                            # Documentación y sustentos adicionales
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
