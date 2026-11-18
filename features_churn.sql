-- =====================================================================
-- Preentrega 7 - Ingeniería de features para predecir Churn
-- Motor: DuckDB  |  Fecha de referencia: 2024-12-31 (fin del período)
-- =====================================================================

WITH pedidos AS (
    -- Paso 1: leo el CSV y dejo los tipos correctos
    SELECT
        user_id,
        order_id,
        CAST(order_date AS DATE)  AS order_date,
        CAST(amount AS DOUBLE)    AS amount
    FROM read_csv_auto('data/orders.csv')
    WHERE order_date <= DATE '2024-12-31'          -- filtro: sin fechas futuras
),

metricas_rfm AS (
    -- Paso 2: Recency, Frequency y Monetary por usuario
    SELECT
        user_id,
        DATE_DIFF('day', MAX(order_date), DATE '2024-12-31') AS recency_dias,
        COUNT(DISTINCT order_id)                             AS frequency_pedidos,
        ROUND(SUM(amount), 2)                                AS monetary_total
    FROM pedidos
    GROUP BY user_id
),

gasto_mensual AS (
    -- Paso 3: gasto por usuario y por mes
    SELECT
        user_id,
        DATE_TRUNC('month', order_date) AS mes,
        SUM(amount)                     AS gasto_mes
    FROM pedidos
    GROUP BY user_id, DATE_TRUNC('month', order_date)
),

gasto_con_ventanas AS (
    -- Paso 4: funciones de VENTANA sobre el gasto mensual
    SELECT
        user_id,
        mes,
        gasto_mes,
        -- ventana 1: promedio histórico mensual del usuario (AVG OVER PARTITION BY)
        AVG(gasto_mes) OVER (PARTITION BY user_id)                 AS gasto_promedio_historico,
        -- ventana 2: gasto del mes anterior (LAG)
        LAG(gasto_mes) OVER (PARTITION BY user_id ORDER BY mes)    AS gasto_mes_anterior
    FROM gasto_mensual
),

tendencia AS (
    -- Paso 5: Trend = gasto del último mes (diciembre 2024) menos el promedio histórico
    SELECT
        user_id,
        MAX(gasto_promedio_historico)                                       AS gasto_promedio_historico,
        COALESCE(SUM(CASE WHEN mes = DATE '2024-12-01' THEN gasto_mes END), 0) AS gasto_ultimo_mes
    FROM gasto_con_ventanas
    GROUP BY user_id
)

-- Paso 6: tabla final de features (una fila por usuario)
SELECT
    r.user_id,
    r.recency_dias,
    r.frequency_pedidos,
    r.monetary_total,
    ROUND(t.gasto_promedio_historico, 2)                                AS gasto_promedio_mensual,
    ROUND(t.gasto_ultimo_mes - t.gasto_promedio_historico, 2)           AS trend_gasto,
    -- ventana 3: ranking de usuarios según gasto total
    RANK() OVER (ORDER BY r.monetary_total DESC)                        AS ranking_gasto,
    -- bandera simple de posible abandono (sin compras en los últimos 90 días)
    CASE WHEN r.recency_dias > 90 THEN 1 ELSE 0 END                     AS posible_churn
FROM metricas_rfm AS r
LEFT JOIN tendencia AS t
       ON t.user_id = r.user_id
ORDER BY r.user_id;
