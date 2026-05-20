INSERT INTO Client(snils, email, inn, passport, fio, phone_number, registration_date, password) 
VALUES
('12345678901', 'user1@test.com', '123456789012', '1234567890', 'Иванов Иван Иванович', '79999999999', NOW(), 'pass'),
('12345678902', 'user2@test.com', '123456789013', '1234567891', 'Петров Петр Петрович', '78888888888', NOW(), 'pass');

INSERT INTO Broker_Contract(user_id, open_date, type, status)
VALUES
(1, now(), 'Обычный', 'Активен'),
(2, now(), 'Обычный', 'Активен');

INSERT INTO Wallet(contract_id, balance, profit, status, currency, curr_balance)
VALUES
(1, 10000, 0, 'Активен', 'RUB', 0),
(2, 15000, 0, 'Активен', 'RUB', 0);

INSERT INTO Exchange(id, ticker, name)
VALUES
(1, 'MOEX', 'Московская биржа');

INSERT INTO Stock(id, ticker, name, type, currency)
VALUES
(1, 'GAZP', 'Газпром', 'Акция', 'RUB');

INSERT INTO Trading_Instrument(stock_id, exchange_id, sell_price, buy_price)
VALUES
(1, 1, 150.00, 151.00);

