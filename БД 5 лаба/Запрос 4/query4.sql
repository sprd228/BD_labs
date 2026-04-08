WITH debet AS (
    SELECT
        Client.id,
        Client.fio,
        Client.inn,
        Card.card_number,
        MAX(Logger.time) AS last_time
    FROM Client
    JOIN Broker_Contract bc ON bc.user_id = Client.id AND bc.type = 'ИИС' AND bc.status = 'Активен'
    JOIN Service_Contract sc ON sc.user_id = Client.id
	JOIN Card ON Card.service_id = sc.id AND Card.type = 'Дебетовая'
	JOIN Tariff ON Tariff.id = sc.tariff_id AND Tariff.price > 0
    LEFT JOIN Bank_Wallet_Transaction bwt ON bwt.service_id = sc.id AND bwt.broker_id = bc.id AND bwt.amount > 0
	LEFT JOIN Logger ON Logger.log_id = bwt.id AND Logger.entity = 'Транзакция банк/с' AND Logger.type = 'Успешно'
	GROUP BY Client.id, Client.fio, Client.inn, Card.card_number
),

credit AS (
    SELECT DISTINCT Client.id
    FROM Client
    JOIN Service_Contract sc ON sc.user_id = Client.id
    JOIN Card ON Card.service_id = sc.id
    WHERE Card.type = 'Кредитная'
)

SELECT 
    debet.fio AS "ФИО",
    debet.inn AS "ИНН",
    debet.card_number AS "Номер карты",
    debet.last_time AS "Дата последней транзакции"
FROM debet
JOIN credit ON credit.id = debet.id;