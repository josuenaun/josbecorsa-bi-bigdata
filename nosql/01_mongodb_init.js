// =============================================================================
// UNIVERSIDAD PRIVADA DEL NORTE
// CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
// PROYECTO: Sistema de Gestión de Datos - JOSBECORSA (RUC 20612766135)
// ARCHIVO: nosql/01_mongodb_init.js
// DESCRIPCIÓN: Script de inicialización de base de datos NoSQL en MongoDB.
// =============================================================================

// 1. Selección / Creación de la Base de Datos
db = db.getSiblingDB('josbecorsa_nosql')

// 2. Creación de la Colección de Telemetría e Incidencias
db.createCollection('incidencias_sensores')

// 3. Creación de Índices para optimizar consultas por ubicación y fecha
db.incidencias_sensores.createIndex({ "ubicacion": 1, "timestamp": -1 })

// 4. Inserción de documentos de prueba (Lecturas de frío e incidentes)
db.incidencias_sensores.insertMany([
  {
    "id_evento": "EVT-20261012-01",
    "ubicacion": "Camara_Frio_Principal",
    "timestamp": ISODate("2026-10-12T08:30:00Z"),
    "sensor_id": "SNS-TEMP-01",
    "temperatura_celsius": 4.2,
    "humedad_relativa": 85.5,
    "alerta_activa": false,
    "incidencia": null
  },
  {
    "id_evento": "EVT-20261012-02",
    "ubicacion": "Puesto_Contingencia_Tia",
    "timestamp": ISODate("2026-10-12T09:15:00Z"),
    "sensor_id": "SNS-TEMP-03",
    "temperatura_celsius": 9.8,
    "humedad_relativa": 91.0,
    "alerta_activa": true,
    "incidencia": {
      "tipo": "Interrupción de Cadena de Frío",
      "descripcion": "Elevación de temperatura durante la descarga de 120 jabas de palta Hass.",
      "responsable_cuadrilla": "Estibadores Lima Central"
    }
  }
]);

print("Base de datos josbecorsa_nosql e índices creados con éxito.");