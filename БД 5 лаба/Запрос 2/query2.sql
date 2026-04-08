WITH month_count_by_stock AS(
	SELECT 
		Stock.id, 
		COUNT(bwt.id) AS trade_num,
		SUM(bwt.lot_number) AS lot_num
	FROM Stock 
	JOIN Broker_Wallet_Transaction AS bwt ON Stock.id = bwt.stock_id
	JOIN Logger ON bwt.id = Logger.log_id
	WHERE Logger.entity = 'Транзакция брокер/с'
		AND Logger.time >= NOW() - INTERVAL '1 month'
		AND Logger.type = 'Успешно'
		AND bwt.lot_number > 0
	GROUP BY Stock.id
),

prev_month_count_by_stock AS(
	SELECT 
		Stock.id, 
		COUNT(bwt.id) AS trade_num
	FROM Stock 
	JOIN Broker_Wallet_Transaction AS bwt ON Stock.id = bwt.stock_id
	JOIN Logger ON bwt.id = Logger.log_id
	WHERE Logger.entity = 'Транзакция брокер/с'
		AND Logger.time BETWEEN NOW() - INTERVAL '2 month' AND NOW() - INTERVAL '1 month'
		AND Logger.type = 'Успешно'
		AND bwt.lot_number > 0
	GROUP BY Stock.id
)

SELECT 
	Stock.name AS "Бумага",
	Stock.type AS "Тип",
	mcbs.trade_num AS "Кол-во сделок",
	mcbs.lot_num AS "Кол-во проданных бумаг",
	ROUND(mcbs.trade_num::NUMERIC / NULLIF(pmcbs.trade_num, 0) * 100, 2) AS "% популярности отн. пред. месяца"
FROM Stock
JOIN month_count_by_stock AS mcbs ON Stock.id = mcbs.id
LEFT JOIN prev_month_count_by_stock AS pmcbs ON Stock.id = pmcbs.id
ORDER BY mcbs.trade_num DESC, Stock.name ASC LIMIT 5