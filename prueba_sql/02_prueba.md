# Guía de Pruebas: Objetos de Automatización BD JOSBECORSA 🗄️

Esta guía detalla el propósito y los scripts de prueba para los objetos programables implementados en la base de datos transaccional de JOSBECORSA.

---

## 1. Vista: `vw_Resumen_Acopio_Jabas`

**🎯 ¿Para qué sirve?**
Realiza un cruce (`INNER JOIN`) automático entre las tablas `Lote_Acopio`, `Detalle_Jaba` y los catálogos de Variedad y Calidad. En el diseño original, `Lote_Acopio` solo tiene el total de jabas. Esta vista le permite al jefe de almacén saber exactamente cuántas jabas de una variedad y calidad específica (ej. "Palta Hass de 1era") llegaron, sin tener que escribir consultas complejas.

**⚙️ ¿Cómo probarlo?**
Solo necesitas hacer un `SELECT` directo.

```sql
-- Prueba: Mostrar el resumen actual de jabas acopiadas
SELECT * 
FROM vw_Resumen_Acopio_Jabas
ORDER BY total_jabas DESC
```

---

## 2. Función Escalar: `fu_CalcularCostoEstiba`

**🎯 ¿Para qué sirve?**
Centraliza el cálculo matemático para los pagos logísticos. Multiplica la cantidad de jabas descargadas por la tarifa acordada. Se utiliza para estandarizar la columna calculada monto_total en la tabla `Pago_Estibador`. Si la fórmula contable de la empresa cambia, solo se modifica esta función sin alterar las aplicaciones web.

**⚙️ ¿Cómo probarlo?**
Se prueba pasándole parámetros directamente en un `SELECT`. Puedes hacerlo con valores estáticos o aplicándolo a una tabla.

```sql
-- Prueba 1: Calcular estiba para 150 jabas a S/ 1.50 cada una
SELECT dbo.fu_CalcularCostoEstiba(150, 1.50) AS CostoPagoCuadrilla
```

---

## 3. Stored Procedure: `usp_RegistrarVentaKilo`

**🎯 ¿Para qué sirve?**
Es el motor transaccional para las ventas en puesto. Realiza múltiples acciones de una sola vez: 
* Valida que los datos sean lógicos.
* Inserta la cabecera de la venta (`Venta_Puesto`).
* Calcula el subtotal.
* Inserta el detalle (`Detalle_Venta_Kilo`).
* Actualiza el monto final. 

Su bloque `TRY...CATCH` asegura que si algo falla, no se guarden datos a medias.

**⚙️ ¿Cómo probarlo?**
Debes declarar la variable de salida (`OUTPUT`), ejecutar el procedimiento con `EXEC` y luego imprimir el resultado. Es ideal probar un escenario de éxito y uno de error para demostrar las validaciones.

### ✅ Escenario A: Venta Exitosa

```sql
DECLARE @MensajeResultado VARCHAR(300)

-- Ejecutamos simulando la venta de 50.5 kg de palta a S/ 6.50 el kilo
EXEC usp_RegistrarVentaKilo 
    @p_id_ubicacion = 1,          -- Asegúrate que el ID 1 exista en Cat_Ubicacion
    @p_cliente_nombre = 'Comercializadora El Buen Sabor',
    @p_id_variedad = 1,           -- ID variedad (ej. Hass)
    @p_id_calidad = 1,            -- ID calidad (ej. Primera)
    @p_peso_kg = 50.50,
    @p_precio_por_kg = 6.50,
    @p_mensaje_salida = @MensajeResultado OUTPUT

-- Ver el mensaje que devuelve el SP
SELECT @MensajeResultado AS ResultadoTransaccion
```

### ❌ Escenario B: Prueba de Error (Validación)

```sql
DECLARE @MensajeError VARCHAR(300)

-- Forzamos un error enviando un precio negativo (-5.00)
EXEC usp_RegistrarVentaKilo 
    @p_id_ubicacion = 1,
    @p_cliente_nombre = 'Cliente Prueba Error',
    @p_id_variedad = 1,
    @p_id_calidad = 1,
    @p_peso_kg = 20.00,
    @p_precio_por_kg = -5.00,     -- ¡Dato inválido!
    @p_mensaje_salida = @MensajeError OUTPUT

-- El SP debería capturar el RAISERROR y mostrar el mensaje correspondiente
SELECT @MensajeError AS ResultadoValidacion
```