EXPLAIN (ANALYZE, BUFFERS)
WITH deals AS (
    SELECT 
        DATE_TRUNC('month', Logger.time) AS month,
        Stock.name AS stock_name,
        Stock.type AS stock_type,
        er.currency,
        bwt.lot_number,
        bwt.lot_price,
        er.rate
    FROM Broker_Wallet_Transaction bwt
    JOIN Logger ON bwt.id = Logger.log_id
    JOIN Stock ON bwt.stock_id = Stock.id
    JOIN Exchange_Rate er ON er.id = bwt.rate_id
    WHERE Logger.entity = 'Транзакция брокер/с'
      AND Logger.type = 'Успешно'
      AND Logger.time >= '2024-01-01' 
	  AND Logger.time < '2025-01-01'
),

months AS (
    SELECT generate_series(
        '2024-01-01'::date,
        '2024-12-01'::date,
        interval '1 month'
    ) AS month
),

top_stock AS (
    SELECT 
        month,
        stock_name,
        SUM(ABS(lot_number)) AS total
    FROM deals
    WHERE lot_number < 0 AND stock_type = 'Акция'
    GROUP BY month, stock_name
),

stock_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY total DESC) AS rn
    FROM top_stock
),

top_bond AS (
    SELECT 
        month,
        stock_name,
        SUM(ABS(lot_number)) AS total
    FROM deals
    WHERE lot_number < 0 AND stock_type = 'Облигация'
    GROUP BY month, stock_name
),

bond_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY total DESC) AS rn
    FROM top_bond
),

top_currency AS (
    SELECT
        month,
        currency,
        COUNT(*) AS total
    FROM deals
    GROUP BY month, currency
),

currency_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY total DESC) AS rn
    FROM top_currency
),

buys_sells AS (
    SELECT 
        month,
        ROUND(
            SUM(CASE WHEN lot_number > 0 THEN lot_number * lot_price * rate ELSE 0 END)
            /
            NULLIF(SUM(CASE WHEN lot_number < 0 THEN ABS(lot_number) * lot_price * rate ELSE 0 END), 0),
        3) AS ratio
    FROM deals
    GROUP BY month
)

SELECT 
    TO_CHAR(months.month, 'Month') AS "Месяц",
    sr.stock_name AS "Самая популярная акция",
    br.stock_name AS "Самая популярная облигация",
    cr.currency   AS "Самая популярная валюта",
    bs.ratio     AS "Отношение покупок к продажам"
FROM months
LEFT JOIN stock_ranked sr ON sr.month = months.month AND sr.rn = 1
LEFT JOIN bond_ranked br ON br.month = months.month AND br.rn = 1
LEFT JOIN currency_ranked cr ON cr.month = months.month AND cr.rn = 1
LEFT JOIN buys_sells bs ON bs.month = months.month
ORDER BY months.month;