CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT *
FROM crosstab(
	$$
	SELECT
	    Exchange.name,
	    Logger.type,
	    COUNT(*)
	FROM Broker_Wallet_Transaction bwt
	JOIN Logger ON bwt.id = Logger.log_id
	JOIN Exchange ON bwt.exchange_id = Exchange.id
	WHERE Logger.type IN ('Успешно','Отклонено')
	GROUP BY Exchange.name, Logger.type
	ORDER BY Exchange.name, Logger.type
	$$,
	$$
	SELECT 'Успешно'
	UNION
	SELECT 'Отклонено';
	$$
) AS crtab(
	"Биржа" TEXT,
	"Успешно" INT,
	"Неудачно" INT
)

