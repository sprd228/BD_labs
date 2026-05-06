CREATE OR REPLACE FUNCTION trg_transaction_before()
RETURNS TRIGGER AS $$
DECLARE
    contract_status VARCHAR(12);
    wallet_status VARCHAR(12);
    card_type CHAR(9);
    card_balance DECIMAL(15,2);
    v_reason TEXT := '-';
    v_type TEXT;
    v_price DECIMAL(15,4);
    v_total DECIMAL(15,2);
    v_stock_currency CHAR(3);
    v_rate DECIMAL(15,4) := 1;
	v_rate_id INT := 0;
    v_balance DECIMAL(15,2);
    v_owned INT := 0;
    v_is_buy BOOLEAN;
    v_qty INT;
BEGIN
    NEW.status := 'Удачная';
	
    IF TG_TABLE_NAME = 'bank_wallet_transaction' THEN
        v_type := 'Транзакция банк/с';
    ELSE
        v_type := 'Транзакция брокер/с';
    END IF;

    SELECT status INTO contract_status
    FROM Broker_Contract
    WHERE id = NEW.broker_id;

    SELECT status INTO wallet_status
    FROM Wallet
    WHERE contract_id = NEW.broker_id;

    IF COALESCE(contract_status,'') != 'Активен'
       OR COALESCE(wallet_status,'') != 'Активен' THEN
        NEW.status := 'Неудачная';
        v_reason := 'Договор или кошелек не активен';
    ELSE
        IF TG_TABLE_NAME = 'bank_wallet_transaction' THEN
            SELECT type, balance INTO card_type, card_balance
            FROM Card
            WHERE service_id = NEW.service_id;

            IF card_type = 'Кредитная' THEN
                NEW.status := 'Неудачная';
                v_reason := 'Кредитная карта';
            ELSIF card_balance < NEW.amount THEN
                NEW.status := 'Неудачная';
                v_reason := 'Недостаточно средств';
            ELSIF card_type IS NULL THEN
                NEW.status := 'Неудачная';
                v_reason := 'Карта отсутствует';
            END IF;
		ELSE
			SELECT balance INTO v_balance
			FROM Wallet
			WHERE contract_id = NEW.broker_id;
			
            IF NEW.lot_number = 0 THEN
                NEW.status := 'Неудачная';
                v_reason := 'Количество лотов = 0';
            END IF;
			
            v_is_buy := NEW.lot_number > 0;
            v_qty := ABS(NEW.lot_number);

            IF NEW.status = 'Удачная' THEN
                IF v_is_buy THEN
                    SELECT ti.sell_price, s.currency
                    INTO v_price, v_stock_currency
                    FROM Trading_Instrument ti
                    JOIN Stock s ON s.id = ti.stock_id
                    WHERE ti.stock_id = NEW.stock_id AND ti.exchange_id = NEW.exchange_id;
                ELSE
                    SELECT ti.buy_price, s.currency
                    INTO v_price, v_stock_currency
                    FROM Trading_Instrument ti
                    JOIN Stock s ON s.id = ti.stock_id
                    WHERE ti.stock_id = NEW.stock_id AND ti.exchange_id = NEW.exchange_id;
                END IF;

				NEW.lot_price := v_price;
            END IF;

            IF NEW.status = 'Удачная' AND v_stock_currency <> 'RUB' THEN
                SELECT rate, id INTO v_rate, v_rate_id
                FROM Exchange_Rate
                WHERE currency = v_stock_currency
                ORDER BY date DESC
                LIMIT 1;
				NEW.rate_id := v_rate_id;
                IF v_rate IS NULL OR v_rate = 0 THEN
                    NEW.status := 'Неудачная';
                    v_reason := 'Нет курса валюты';
                END IF;
            END IF;
			
            IF NEW.status = 'Удачная' THEN
                v_total := v_price * v_qty * v_rate;
            END IF;

            IF NEW.status = 'Удачная' AND v_is_buy THEN
                IF v_balance < v_total THEN
                    NEW.status := 'Неудачная';
                    v_reason := 'Недостаточно средств';
                END IF;
            END IF;

            IF NEW.status = 'Удачная' AND NOT v_is_buy THEN
                SELECT lot_number INTO v_owned
                FROM Balance
                WHERE contract_id = NEW.broker_id AND stock_id = NEW.stock_id;
                IF COALESCE(v_owned, 0) < v_qty THEN
                    NEW.status := 'Неудачная';
                    v_reason := 'Недостаточно активов';
                END IF;
            END IF;
        END IF;
    END IF;

    INSERT INTO Logger(entity, log_id, time, type, comment)
    VALUES (
        v_type,
        NEW.id,
        CURRENT_TIMESTAMP,
        CASE WHEN NEW.status = 'Удачная' THEN 'Успешно' ELSE 'Отклонено' END,
        v_reason
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER bank_transaction_check
BEFORE INSERT ON Bank_Wallet_Transaction
FOR EACH ROW
EXECUTE FUNCTION trg_transaction_before();

CREATE OR REPLACE TRIGGER broker_transaction_check
BEFORE INSERT ON Broker_Wallet_Transaction
FOR EACH ROW
EXECUTE FUNCTION trg_transaction_before();