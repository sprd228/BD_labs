CREATE OR REPLACE PROCEDURE trade(
    p_contract_id INT,
    p_stock_id INT,
    p_exchange_id INT,
    p_lots INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status TEXT;
    v_price DECIMAL(15,4);
    v_qty INT;
	v_rate DECIMAL(15,4) := 1;
    v_total DECIMAL(15,2);
	v_stock_currency CHAR(3);
BEGIN
    INSERT INTO Broker_Wallet_Transaction (broker_id, stock_id, exchange_id, rate_id, lot_number, lot_price)
    VALUES (p_contract_id, p_stock_id, p_exchange_id, NULL, p_lots, 0)
    RETURNING status, lot_price
    INTO v_status, v_price;

    IF v_status <> 'Удачная' THEN
        RETURN;
    END IF;

	SELECT currency
	INTO v_stock_currency
	FROM Trading_Instrument ti
	JOIN Stock s ON s.id = ti.stock_id
	WHERE ti.stock_id = p_stock_id AND ti.exchange_id = p_exchange_id;


	SELECT rate INTO v_rate 
	FROM Exchange_Rate
	WHERE currency = v_stock_currency
	ORDER BY date DESC
	LIMIT 1;

    v_qty := ABS(p_lots);
    v_total := v_price * v_qty * v_rate;

    IF p_lots > 0 THEN
        UPDATE Wallet
        SET balance = balance - v_total
        WHERE contract_id = p_contract_id;

        INSERT INTO Balance (stock_id, contract_id, lot_number)
        VALUES (p_stock_id, p_contract_id, v_qty)
        ON CONFLICT (stock_id, contract_id)
        DO UPDATE SET lot_number = Balance.lot_number + EXCLUDED.lot_number;
    ELSE
        UPDATE Wallet
        SET balance = balance + v_total
        WHERE contract_id = p_contract_id;

        UPDATE Balance
        SET lot_number = lot_number - v_qty
        WHERE contract_id = p_contract_id AND stock_id = p_stock_id;
    END IF;
END;
$$;