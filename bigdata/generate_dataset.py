# =============================================================================
# CURSO: Base de Datos Avanzadas y Big Data (ISOF1304)
# PROYECTO: JOSBECORSA (RUC 20612766135)
# ARCHIVO: bigdata/generate_dataset.py
# DESCRIPCIÓN: Generador sintético de 500,000 registros de ventas en Parquet.
# =============================================================================

import os
import pandas as pd
import numpy as np

def generar_dataset_masivo(num_registros=500000):
    print(f"Generando {num_registros} registros sintético-operativos de ventas...")
    
    variedades = ["Hass", "Fuerte", "Nabal"]
    calidades = ["1era", "2da", "3era", "4ta", "Semimanchada", "Manchada"]
    ubicaciones = ["Puesto Principal", "Camara de Frio", "Contingencia Tia", "Contingencia Amiga"]

    data = {
        "id_venta": np.random.randint(1000, 999999, size=num_registros),
        "fecha_venta": pd.date_range(start="2025-01-01", periods=num_registros, freq="s"),
        "variedad_palta": np.random.choice(variedades, size=num_registros, p=[0.5, 0.35, 0.15]),
        "calidad_palta": np.random.choice(calidades, size=num_registros),
        "ubicacion": np.random.choice(ubicaciones, size=num_registros),
        "peso_vendido_kg": np.round(np.random.uniform(10.0, 500.0, size=num_registros), 2),
        "precio_por_kg": np.round(np.random.uniform(4.50, 12.00, size=num_registros), 2)
    }

    df = pd.DataFrame(data)
    df["monto_subtotal"] = np.round(df["peso_vendido_kg"] * df["precio_por_kg"], 2)

    # Crear directorio si no existe
    os.makedirs("data/parquet", exist_ok=True)
    ruta_salida = "data/parquet/ventas_500k.parquet"
    
    # Guardar en formato columnar Parquet
    df.to_parquet(ruta_salida, engine="pyarrow", index=False)
    print(f"Dataset masivo guardado con éxito en: {ruta_salida}")

if __name__ == "__main__":
    generar_dataset_masivo()