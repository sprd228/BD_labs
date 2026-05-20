-- non-repeatable read (говняшка)
BEGIN;
SELECT balance
FROM Wallet
WHERE contract_id = 1;

SELECT balance
FROM Wallet
WHERE contract_id = 1;
COMMIT;


-- non-repeatable read (норм)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT balance
FROM Wallet
WHERE contract_id = 1;

SELECT balance
FROM Wallet
WHERE contract_id = 1;
COMMIT;




-- phantom read (говняшка)
BEGIN;
SELECT COUNT(*)
FROM Broker_Wallet_Transaction
WHERE status = 'В процессе';

SELECT COUNT(*)
FROM Broker_Wallet_Transaction
WHERE status = 'В процессе';
COMMIT;


-- phantom read (норм)
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*)
FROM Broker_Wallet_Transaction
WHERE status = 'В процессе';

SELECT COUNT(*)
FROM Broker_Wallet_Transaction
WHERE status = 'В процессе';
COMMIT;




-- write skew (говняшка)
SELECT id, status
FROM Broker_Contract;

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*)
FROM Broker_Contract
WHERE status = 'Активен';

UPDATE Broker_Contract
SET status = 'Заблокирован'
WHERE id = 1;
COMMIT;

SELECT id, status
FROM Broker_Contract;


-- write skew (норм)
UPDATE Broker_Contract
SET status = 'Активен'

SELECT id, status
FROM Broker_Contract;

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT COUNT(*)
FROM Broker_Contract
WHERE status = 'Активен';

UPDATE Broker_Contract
SET status = 'Заблокирован'
WHERE id = 1;
COMMIT;

SELECT id, status
FROM Broker_Contract;




-- savepoint и rollback to
BEGIN;
SELECT balance
FROM Wallet
WHERE contract_id = 1;

UPDATE Wallet
SET balance = balance - 1000
WHERE contract_id = 1;

SAVEPOINT before_logger;

INSERT INTO Logger(entity, log_id, time, type, comment)
VALUES ('Транзакция банк/с', 1, NOW(), 'Успешно', 'Перевод средств');

SELECT *
FROM Logger;

ROLLBACK TO SAVEPOINT before_logger;

SELECT *
FROM Logger;

SELECT balance
FROM Wallet
WHERE contract_id = 1;
COMMIT;





