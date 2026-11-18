# Preentrega 7 - Ingeniería de features con SQL analítico

Consulta SQL (`features_churn.sql`) que transforma pedidos de e-commerce en una tabla de **features por usuario** para entrenar un modelo de **abandono (Churn)**. Motor: DuckDB. Fecha de referencia: 31/12/2024.

## Cómo ejecutarlo
1. `pip install -r requirements.txt`
2. `python generar_pedidos.py`  (crea `data/orders.csv`)
3. `python ejecutar_features.py`  (corre el .sql y guarda `data/features.csv`)

## Features generadas y por qué sirven para predecir Churn
| Feature | Qué es | Por qué ayuda |
|---|---|---|
| `recency_dias` | Días desde la última compra | Si pasó mucho tiempo sin comprar, es la señal más fuerte de abandono |
| `frequency_pedidos` | Cantidad de pedidos únicos | Un cliente que compra seguido es más fiel |
| `monetary_total` | Gasto total acumulado | Mide el valor del cliente |
| `gasto_promedio_mensual` | Promedio mensual histórico | Línea base de comportamiento normal |
| `trend_gasto` | Gasto del último mes − promedio histórico | Si es negativo, el cliente está gastando menos que antes (señal de alerta) |
| `ranking_gasto` | Posición del usuario por gasto total | Permite priorizar clientes valiosos |
| `posible_churn` | 1 si no compra hace más de 90 días | Etiqueta de ejemplo para el modelo |

## Funciones de ventana usadas
`AVG() OVER (PARTITION BY user_id)`, `LAG() OVER (PARTITION BY ... ORDER BY mes)` y `RANK() OVER (ORDER BY ...)`.

## Manejo de nulos
Usuarios sin compras en el último mes tienen `gasto_ultimo_mes = 0` mediante `COALESCE(..., 0)` en lugar de NULL. Se filtran pedidos posteriores a la fecha de referencia para no sesgar la tendencia.
