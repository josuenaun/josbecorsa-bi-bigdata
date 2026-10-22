# Guía de Pruebas: Triggers y Transacciones JOSBECORSA 🛡️

Esta guía detalla el propósito y los scripts de prueba para los mecanismos de seguridad, auditoría y control transaccional implementados en la base de datos de JOSBECORSA.

## 1. Trigger DML: `trg_AuditarYControlarPrecioKilo`

**🎯 ¿Para qué sirve?**
Es un "guardián" de los precios. Se activa automáticamente cuando alguien intenta hacer un `UPDATE` en la tabla `Detalle_Venta_Kilo`. Hace dos cosas:
1. **Control:** Bloquea la actualización si el nuevo precio es más de un 30% mayor al precio anterior (protección contra errores de tipeo o fraudes).
2. **Auditoría:** Si el cambio es válido, registra quién, cuándo, el precio anterior y el precio nuevo en la tabla `Log_Auditoria_Precios`.

**⚙️ ¿Cómo probarlo?**
Necesitas tener un registro existente en `Detalle_Venta_Kilo`. Haremos un `UPDATE` válido y otro inválido.

### ✅ Escenario A: Cambio Válido (Queda Auditado)

```sql
-- 1. Consultar el ID de un detalle existente y su precio actual (asumamos id_detalle_venta = 1 con precio 5.00)
-- Actualizamos subiendo el precio a 6.00 (dentro del margen del 30%)
UPDATE Detalle_Venta_Kilo 
SET precio_por_kg = 6.00 
WHERE id_detalle_venta = 1

-- 2. Verificamos que se guardó en la tabla de auditoría
SELECT * FROM Log_Auditoria_Precios ORDER BY fecha_modificacion DESC
```

### ❌ Escenario B: Prueba de Error (Aumento abusivo)

```sql
-- Intentamos subir el precio a un valor absurdo (ej. de 6.00 a 20.00, mucho más del 30%)
-- El trigger detendrá la transacción y mostrará un error
UPDATE Detalle_Venta_Kilo 
SET precio_por_kg = 20.00 
WHERE id_detalle_venta = 1
```

---

## 2. Trigger DDL: `trg_PrevencionDropTable`

**🎯 ¿Para qué sirve?**
Protege la estructura global de JOSBECORSA. Bloquea cualquier comando `DROP TABLE`, impidiendo que usuarios o desarrolladores eliminen por accidente tablas maestras críticas como `Cat_Cliente` o `Lote_Acopio`.

**⚙️ ¿Cómo probarlo?**
Creamos una tabla temporal de prueba y luego intentamos eliminarla.

```sql
-- 1. Creamos una tabla "basura"
CREATE TABLE Tabla_Para_Borrar (Id INT)

-- 2. Intentamos borrarla. El trigger debería saltar y mostrar: "!! ACCIÓN PROHIBIDA..."
DROP TABLE Tabla_Para_Borrar

-- (Opcional) Para poder borrarla realmente, el DBA debe deshabilitar el trigger temporalmente:
 DISABLE TRIGGER trg_PrevencionDropTable ON DATABASE
 DROP TABLE Tabla_Para_Borrar;
 ENABLE TRIGGER trg_PrevencionDropTable ON DATABASE
```

---

## 3. SP Transaccional: `usp_RegistrarInboundLoteTransaccional`

**🎯 ¿Para qué sirve?**
Garantiza el principio de Atomicidad (Todo o Nada). Cuando llega mercadería, JOSBECORSA debe registrar 3 cosas: el `Lote_Acopio`, el `Pago_Transportista` y el `Pago_Estibador`. Este SP envuelve todo en un `BEGIN TRANSACTION`. Si el pago al estibador falla, hace un `ROLLBACK` y cancela también la creación del lote, evitando descuadres logísticos (lotes ingresados sin costos asociados).

**⚙️ ¿Cómo probarlo?**
Usamos un bloque de código para capturar el resultado (`OUTPUT`).

### ✅ Escenario A: Registro de Lote Exitoso (Atómico)

```sql
DECLARE @MensajeResultado VARCHAR(300)

EXEC usp_RegistrarInboundLoteTransaccional 
    @p_codigo_lote = 'LOTE-TEST-001',
    @p_origen = 'Huaral',
    @p_total_jabas = 200,
    @p_conductor = 'Juan Perez',
    @p_placa = 'ABC-123',
    @p_monto_flete = 450.00,
    @p_cuadrilla = 'Los Rápidos',
    @p_tarifa_estiba = 1.50,
    @p_resultado = @MensajeResultado OUTPUT

SELECT @MensajeResultado AS ResultadoTransaccional

-- Verifica que se insertaron los 3 registros (Lote_Acopio, Pago_Transportista, Pago_Estibador)
```

### ❌ Escenario B: Falla Transaccional (Rollback Automático)

```sql
DECLARE @MensajeError VARCHAR(300)

-- Simulamos un error enviando datos inválidos (ej. asumiendo que la tarifa no permite NULLs o forzando un fallo de tipo de dato si modificas el script para pruebas, o enviando un texto demasiado largo que desborde un varchar)
-- NOTA: Como ejemplo, enviamos un origen demasiado largo para forzar truncamiento/error de inserción
EXEC usp_RegistrarInboundLoteTransaccional 
    @p_codigo_lote = 'LOTE-ERR-002',
    @p_origen = 'Este texto es exageradamente largo y debería fallar porque el origen solo soporta 50 caracteres y este texto tiene muchos más caracteres que los permitidos',
    @p_total_jabas = 150,
    @p_conductor = 'Carlos Ruiz',
    @p_placa = 'XYZ-987',
    @p_monto_flete = 300.00,
    @p_cuadrilla = 'Cuadrilla Norte',
    @p_tarifa_estiba = 1.50,
    @p_resultado = @MensajeError OUTPUT

SELECT @MensajeError AS ResultadoRollback

-- Verificas que NO se insertó el LOTE-ERR-002 en Lote_Acopio porque todo se revirtió.
```