DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE пользователь (
	id SERIAL PRIMARY KEY,
	снилс CHAR(11) UNIQUE NOT NULL,
	почта VARCHAR(254) UNIQUE NOT NULL,
	инн CHAR(12) UNIQUE NOT NULL,
	паспорт CHAR(10) UNIQUE NOT NULL,
	фио TEXT NOT NULL,
	телефон CHAR(11) NOT NULL,
	дата_регистрации TIMESTAMP NOT NULL,
	пароль VARCHAR(64) NOT NULL,
	CONSTRAINT snils_format CHECK (снилс ~ '^[0-9]{11}$'),
	CONSTRAINT email_format CHECK (почта ~ '^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
	CONSTRAINT taxpayer_format CHECK (инн ~ '^[0-9]{12}$'),
	CONSTRAINT passport_format CHECK (паспорт ~ '^[0-9]{10}$'),
	CONSTRAINT name_format CHECK (фио ~ '^[А-ЯЁ][а-яёА-ЯЁ-]*\s[А-ЯЁ][а-яёА-ЯЁ-]*\s[А-ЯЁ][а-яёА-ЯЁ-]*$'),
	CONSTRAINT phone_number_format CHECK (телефон ~ '^[0-9]{11}$'),
	CONSTRAINT date_rule CHECK (дата_регистрации <= CURRENT_TIMESTAMP)
);

CREATE TABLE брокерский_договор (
	id SERIAL PRIMARY KEY,
	id_пользователя INT NOT NULL REFERENCES пользователь(id),
	дата_открытия TIMESTAMP NOT NULL,
	дата_закрытия TIMESTAMP,
	тип VARCHAR(7) NOT NULL,
	статус VARCHAR(12) NOT NULL,
	CONSTRAINT open_rule CHECK (дата_открытия <= CURRENT_TIMESTAMP),
	CONSTRAINT close_rule CHECK (дата_закрытия >= дата_открытия),
	CONSTRAINT type_enum CHECK (тип IN ('ИИС', 'Обычный')),
	CONSTRAINT status_enum CHECK (статус IN ('Заблокирован', 'Активен'))
);

CREATE TABLE кошелек (
	id_договора INT PRIMARY KEY REFERENCES брокерский_договор(id),
	остаток DECIMAL(15,2) NOT NULL,
	прибыль DECIMAL(15,2) NOT NULL,
	статус VARCHAR(12) NOT NULL,
	CONSTRAINT status_enum CHECK (статус IN ('Заблокирован', 'Активен'))
);

CREATE TABLE тариф (
	id SERIAL PRIMARY KEY,
	условия_обслуживания TEXT NOT NULL,
	цена DECIMAL(10,2) NOT NULL,
	ставка DECIMAL(5,2) NOT NULL,
	CONSTRAINT value_rule CHECK (цена >= 0.00)
);

CREATE TABLE договор_об_обслуживании (
	id SERIAL PRIMARY KEY,
	id_пользователя INT NOT NULL REFERENCES пользователь(id),
	id_тарифа INT NOT NULL REFERENCES тариф(id),
	дата_открытия TIMESTAMP NOT NULL,
	дата_закрытия TIMESTAMP,
	CONSTRAINT open_rule CHECK (дата_открытия <= CURRENT_TIMESTAMP),
	CONSTRAINT close_rule CHECK (дата_закрытия >= дата_открытия)
);

CREATE TABLE карта (
	id_договора INT PRIMARY KEY REFERENCES договор_об_обслуживании(id),
	номер_карты CHAR(16) UNIQUE NOT NULL,
	тип CHAR(9) NOT NULL,
	cvv CHAR(3) NOT NULL,
	номер_счета CHAR(20) NOT NULL,
	CONSTRAINT card_number_format CHECK (номер_карты ~ '^[0-9]{16}$'),
	CONSTRAINT type_rule CHECK (тип IN ('Кредитная', 'Дебетовая')),
	CONSTRAINT cvv_format CHECK (cvv ~ '^[0-9]{3}$'),
	CONSTRAINT bank_number_format CHECK (номер_счета ~ '^[0-9]{20}$')
);

CREATE TABLE транзакция_банк_кошелек (
	id SERIAL PRIMARY KEY,
	id_договора_об_обслуживании INT NOT NULL REFERENCES договор_об_обслуживании(id),
	id_брокерского_договора INT NOT NULL REFERENCES брокерский_договор(id),
	сумма DECIMAL(15,2) NOT NULL,
	статус VARCHAR(10) NOT NULL,
	CONSTRAINT status_rule CHECK (статус IN ('Удачная', 'Неудачная', 'В процессе'))
);

CREATE TABLE ценная_бумага (
	id SERIAL PRIMARY KEY,
	тикер TEXT UNIQUE NOT NULL,
	название TEXT UNIQUE NOT NULL,
	тип VARCHAR(9) NOT NULL,
	CONSTRAINT type_rule CHECK (тип IN ('Акция', 'Облигация', 'Валюта'))
);

CREATE TABLE курс_валют (
	id SERIAL PRIMARY KEY,
	курс DECIMAL(15,4) NOT NULL,
	валюта CHAR(3) NOT NULL,
	дата TIMESTAMP NOT NULL,
	CONSTRAINT code_format CHECK (валюта ~ '^[A-Z]{3}$'),
	CONSTRAINT date_rule CHECK (дата <= CURRENT_TIMESTAMP),
	CONSTRAINT currency_date UNIQUE (валюта, дата)
);

CREATE TABLE биржа (
	id SERIAL PRIMARY KEY,
	тикер TEXT UNIQUE NOT NULL,
	название TEXT UNIQUE NOT NULL
);

CREATE TABLE торговый_инструмент (
	id_бумаги INT REFERENCES ценная_бумага(id),
	id_биржи INT REFERENCES биржа(id),
	PRIMARY KEY(id_бумаги, id_биржи),
	цена_продажи DECIMAL(15,4) NOT NULL,
	цена_покупки DECIMAL(15,4) NOT NULL,
	CONSTRAINT sell_rule CHECK (цена_продажи > 0.00),
	CONSTRAINT buy_rule CHECK (цена_покупки > 0.00)
);

CREATE TABLE транзакция_брокер_кошелек (
	id SERIAL PRIMARY KEY,
	id_брокерского_договора INT NOT NULL REFERENCES брокерский_договор(id),
	id_бумаги INT,
    id_биржи INT,
    FOREIGN KEY (id_бумаги, id_биржи) REFERENCES торговый_инструмент(id_бумаги, id_биржи),
	id_курса INT NOT NULL REFERENCES курс_валют(id),
	количество_лотов INT NOT NULL,
	цена_за_лот DECIMAL(15,4) NOT NULL,
	статус VARCHAR(10) NOT NULL,
	CONSTRAINT status_rule CHECK (статус IN ('Удачная', 'Неудачная', 'В процессе'))
);

CREATE TABLE портфель (
	id_договора INT PRIMARY KEY REFERENCES брокерский_договор(id)
);

CREATE TABLE логгер (
	id SERIAL PRIMARY KEY,
	сущность VARCHAR(23) NOT NULL,
	id_записи INT NOT NULL,
	время TIMESTAMP NOT NULL,
	тип VARCHAR(13) NOT NULL,
	CONSTRAINT entity_rule CHECK (сущность IN ('Брокерский договор', 'Договор об обслуживании', 'Транзакция банк/с', 'Транзакция брокер/с')),
	CONSTRAINT time_rule CHECK (время <= CURRENT_TIMESTAMP),
	CONSTRAINT type_rule CHECK (тип IN ('Открыто', 'Закрыто', 'Заблокировано', 'Успешно', 'Отклонено', 'В процессе'))
);

CREATE TABLE остаток (
	id_бумаги INT REFERENCES ценная_бумага(id),
	id_договора INT REFERENCES брокерский_договор(id),
	PRIMARY KEY(id_бумаги, id_договора),
	количество_лотов INT NOT NULL
)
