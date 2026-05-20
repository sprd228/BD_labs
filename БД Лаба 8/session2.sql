-- non-repeatable read
UPDATE Wallet
SET balance = balance - 1000;
WHERE contract_id = 1;


-- phantom read
INSERT INTO Broker_Wallet_Transaction( broker_id, stock_id, exchange_id, lot_number, lot_price, status)
VALUES (1, 1, 1, 10, 1500, 'В процессе');


-- write skew (говняшка)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*)
FROM Broker_Contract
WHERE status = 'Активен';

UPDATE Broker_Contract
SET status = 'Заблокирован'
WHERE id = 2;
COMMIT;


-- write skew (норм)
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*)
FROM Broker_Contract
WHERE status = 'Активен';

UPDATE Broker_Contract
SET status = 'Заблокирован'
WHERE id = 2;
COMMIT;
