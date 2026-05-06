CREATE OR REPLACE PROCEDURE convert_currency(
    p_contract_id INT,
    p_amount DECIMAL(15,2),
    p_currency CHAR(3)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rub_balance DECIMAL(15,2);
    v_rate DECIMAL(15,4);
    v_converted DECIMAL(15,2);
    v_curr_code CHAR(3);
    v_curr_balance DECIMAL(15,2);
    v_old_rate DECIMAL(15,4);
	v_old_curr DECIMAL(15,4) := 0;
    v_status TEXT := 'Успешно';
    v_reason TEXT := '-';
BEGIN
    SELECT w.balance, w.currency, w.curr_balance
    INTO v_rub_balance, v_curr_code, v_curr_balance
    FROM Wallet w
    JOIN Broker_Contract bc ON bc.id = w.contract_id
    WHERE w.contract_id = p_contract_id
      AND bc.status = 'Активен'
      AND w.status = 'Активен';
	  
    IF v_rub_balance IS NULL THEN
        v_status := 'Отклонено';
        v_reason := 'Договор или кошелек не активен';
    ELSIF v_rub_balance < p_amount THEN
        v_status := 'Отклонено';
        v_reason := 'Недостаточно средств';
    ELSE
		SELECT rate INTO v_rate
		FROM Exchange_Rate
		WHERE currency = p_currency
		ORDER BY date DESC
		LIMIT 1;
		
		IF v_rate IS NULL OR v_rate = 0 THEN
			v_status := 'Отклонено';
			v_reason := 'Нет курса валюты';
		ELSE
			v_converted := p_amount / v_rate;
			
			IF v_curr_code IS NOT NULL AND v_curr_code <> p_currency THEN
				SELECT rate INTO v_old_rate
				FROM Exchange_Rate
				WHERE currency = v_curr_code
				ORDER BY date DESC
				LIMIT 1;
				IF v_old_rate IS NULL OR v_old_rate = 0 THEN
					v_status := 'Отклонено';
					v_reason := 'Нет курса старой валюты';
					INSERT INTO Logger(entity, log_id, time, type, comment)
    				VALUES (
				        'Транзакция конвертации',
				        p_contract_id,
				        CURRENT_TIMESTAMP,
				        v_status,
				        v_reason
    				);
					RETURN;
				END IF;
				v_old_curr := v_curr_balance * v_old_rate / v_rate;
				v_curr_balance := 0;
			END IF;
			
			v_rub_balance := v_rub_balance - p_amount;
			
			UPDATE Wallet
			SET
				balance = v_rub_balance,
				currency = p_currency,
				curr_balance = COALESCE(v_curr_balance, 0) + v_converted + v_old_curr
			WHERE contract_id = p_contract_id;
		END IF;
	END IF;

    INSERT INTO Logger(entity, log_id, time, type, comment)
    VALUES (
        'Транзакция конвертации',
        p_contract_id,
        CURRENT_TIMESTAMP,
        v_status,
        v_reason
    );
END;
$$;