EXPLAIN (ANALYZE, BUFFERS)
WITH last_month_successful_deposits AS (
    SELECT DISTINCT 
		Bank_Wallet_Transaction.broker_id
    FROM Bank_Wallet_Transaction
    JOIN Card ON Bank_Wallet_Transaction.service_id = Card.service_id
    JOIN Logger ON Bank_Wallet_Transaction.id = Logger.log_id
    WHERE Card.type = 'Дебетовая'
      AND Bank_Wallet_Transaction.amount > 0
      AND Logger.entity = 'Транзакция банк/с'
      AND Logger.time >= NOW() - INTERVAL '1 month'
      AND Logger.type = 'Успешно'
),

last_month_trades AS (
    SELECT 
		DISTINCT bwt.broker_id
    FROM Broker_Wallet_Transaction AS bwt
    JOIN Logger ON bwt.id = Logger.log_id
    WHERE Logger.entity = 'Транзакция брокер/с'
      AND Logger.time >= NOW() - INTERVAL '1 month'
),

last_deposit_date AS (
    SELECT 
		Bank_Wallet_Transaction.broker_id,
        MAX(Logger.time) AS last_deposit_date
    FROM Bank_Wallet_Transaction
    JOIN Card ON Bank_Wallet_Transaction.service_id = Card.service_id
    JOIN Logger ON Bank_Wallet_Transaction.id = Logger.log_id
    WHERE Card.type = 'Дебетовая'
      AND Bank_Wallet_Transaction.amount > 0
      AND Logger.entity = 'Транзакция банк/с'
    GROUP BY Bank_Wallet_Transaction.broker_id
),

last_trade_date AS (
	SELECT 
		bwt.broker_id,
        MAX(Logger.time) AS last_trade_date
    FROM Broker_Wallet_Transaction AS bwt
    JOIN Logger ON bwt.id = Logger.log_id
    WHERE Logger.entity = 'Транзакция брокер/с'
    GROUP BY bwt.broker_id
)

SELECT DISTINCT 
    Client.fio AS ФИО, 
    bc.id AS "Номер брокерского договора", 
    Wallet.balance AS Остаток, 
    Wallet.profit AS Прибыль,
    ldd.last_deposit_date AS "Дата последнего пополнения",
    ltd.last_trade_date AS "Дата последней сделки"
FROM Client
JOIN Broker_Contract AS bc ON Client.id = bc.user_id
JOIN Wallet ON bc.id = Wallet.contract_id
JOIN Bank_Wallet_Transaction ON bc.id = Bank_Wallet_Transaction.broker_id AND Bank_Wallet_Transaction.amount > 0
JOIN Card ON Bank_Wallet_Transaction.service_id = Card.service_id
JOIN last_deposit_date AS ldd ON bc.id = ldd.broker_id
LEFT JOIN last_trade_date AS ltd ON bc.id = ltd.broker_id
WHERE bc.id IN (SELECT broker_id FROM last_month_successful_deposits)
	AND NOT EXISTS (
		SELECT 1 
    	FROM last_month_trades AS lmt
    	WHERE lmt.broker_id = bc.id
)
