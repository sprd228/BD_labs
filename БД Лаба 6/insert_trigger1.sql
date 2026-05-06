INSERT INTO Client (snils, email, inn, passport, fio, phone_number, registration_date, password)
VALUES 
('12345678901','ivan@mail.com','123456789012','1234567890','Иванов Иван Иванович','79000000000', NOW(),'pass0'),
('10987654321','petrov@mail.com','109876543210','0987654321','Петров Пётр Петрович','79111111111', NOW(),'pass1'),
('22222222222','sidorov@yandex.com','123456789014','2222222222','Сидоров Сидор Сидорович','79222222222', NOW(),'pass2'),
('33333333333','smirnova@mail.ru','109876543215','3333333333','Смирнова Анна Игоревна','79333333333', NOW(),'pass3'),
('44444444444','kozlov@mail.com','444444444444','4444444444','Козлов Олег Сергеевич','79444444444', NOW(),'pass4'),
('55555555555','orlov@mail.com','555555555555','5555555555','Орлов Дмитрий Андреевич','79555555555', NOW(),'pass5'),
('66666666666','abvgd@mail.com','666666666666','6666666666','Артамонов Борис Вениаминович','79666666666', NOW(),'pass6');


INSERT INTO Broker_Contract (user_id, open_date, type, status)
VALUES 
(1, NOW(), 'Обычный', 'Заблокирован'),
(2, NOW(), 'Обычный', 'Активен'),
(3, NOW(), 'Обычный', 'Заблокирован'),
(4, NOW(), 'Обычный', 'Активен'),
(5, NOW(), 'Обычный', 'Активен'),
(6, NOW(), 'Обычный', 'Активен'),
(7, NOW(), 'Обычный', 'Активен');

INSERT INTO Tariff (service_conditions, price, rate)
VALUES 
('Стандартный тариф', 100.00, 0.50),
('Премиум тариф', 500.00, 1.20);

INSERT INTO Service_Contract (user_id, tariff_id, open_date, close_date)
VALUES
(1, 1, NOW(), NULL),
(2, 1, NOW(), NULL),
(3, 2, NOW(), NULL),
(4, 2, NOW(), NULL),
(5, 2, NOW(), NULL),
(6, 2, NOW(), NULL),
(7, 2, NOW(), NULL);

INSERT INTO Card (service_id, card_number, type, cvv, account_number, balance)
VALUES
(1, '1111111111111111', 'Дебетовая', '111', '11111111111111111111', 1000000),
(2, '2222222222222222', 'Дебетовая', '222', '22222222222222222222', 2000000),
(3, '3333333333333333', 'Дебетовая', '333', '33333333333333333333', 3000000),
(4, '4444444444444444', 'Дебетовая', '444', '44444444444444444444', 4000000),
(5, '5555555555555555', 'Кредитная', '555', '55555555555555555555', 10000000),
(6, '6666666666666666', 'Дебетовая', '666', '66666666666666666666', 100),
(7, '7777777777777777', 'Дебетовая', '777', '77777777777777777777', 100);


INSERT INTO Wallet (contract_id, balance, profit, status, currency, curr_balance)
VALUES 
(1, 10000, -560, 'Заблокирован', NULL, 0),
(2, 5000, 4800, 'Заблокирован', NULL, 0),
(3, -50000000, 0, 'Активен', NULL, 0),
(4, 50000000, 110, 'Активен', NULL, 0),
(5, 30, -400.73, 'Активен', NULL, 0),
(6, 441441441, 222222, 'Активен', NULL, 0),
(7, 50000000, 1515515, 'Активен', 'CNY', 400);

INSERT INTO Exchange (ticker, name)
VALUES
('MOEX', 'Московская биржа'),
('NASDAQ', 'NASDAQ');

INSERT INTO Stock (ticker, name, type, currency)
VALUES
('AAPL', 'Apple Inc.', 'Акция', 'USD'),
('GAZP', 'Газпром', 'Акция', 'RUB'),
('USDRUB', 'USD/RUB', 'Валюта', 'RUB'),
('SBER', 'Сбербанк', 'Акция', 'EUR'),
('MEPHI', 'МИФИ Industries', 'Облигация', 'CNY');


INSERT INTO Exchange_Rate (rate, currency, date)
VALUES
(92.10, 'USD', NOW()),
(100.25, 'EUR', NOW()),
(1.00, 'RUB', NOW());

INSERT INTO Trading_Instrument (stock_id, exchange_id, sell_price, buy_price)
VALUES
(1, 2, 190.50, 189.80),
(3, 1, 92.30, 92.10),
(2, 1, 160.00, 159.20),
(4, 2, 280.10, 279.50),
(4, 1, 270.10, 269.50),
(2, 2, 170.00, 169.20),
(5, 1, 1700.00, 1699.20);


CALL trade(1, 1, 2, 10);
CALL trade(2, 3, 1, 5);
CALL trade(3, 2, 1, 15);
CALL trade(4, 4, 2, 8);
CALL trade(4, 4, 2, 0);
CALL trade(4, 2, 1, 1000);
CALL trade(5, 2, 1, 1);
CALL trade(4, 2, 1, -1001);
CALL trade(5, 2, 1, -1);
CALL trade(4, 2, 1, -900);
CALL trade(4, 2, 1, 300);
CALL trade(4, 5, 1, 3);

INSERT INTO Bank_Wallet_Transaction (service_id, broker_id, amount)
VALUES
(1, 1, 1500.00),
(2, 2, 3000.00),
(3, 3, 5000.00),
(4, 4, 10000.00),
(5, 5, 1.00),
(6, 6, 101.00);


CALL convert_currency(1, 100.00, 'USD');
CALL convert_currency(3, 100.00, 'USD');
CALL convert_currency(5, 100.00, 'USD');
CALL convert_currency(6, 100.00, 'CNY');
CALL convert_currency(7, 100.00, 'USD');
CALL convert_currency(6, 10000.00, 'EUR');
CALL convert_currency(6, 10000.00, 'USD');
CALL convert_currency(6, 10000.00, 'USD');

