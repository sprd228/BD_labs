CREATE INDEX idx_bwt_id_stock_rate_lot 
ON Broker_Wallet_Transaction (id)
INCLUDE (stock_id, rate_id, lot_number, lot_price);

CREATE INDEX idx_logger_broker_success_2024_cover 
ON Logger (time)
INCLUDE (log_id)
WHERE entity = 'Транзакция брокер/с' 
  AND type = 'Успешно' 
  AND time >= '2024-01-01' 
  AND time < '2025-01-01';

ANALYZE Logger, Broker_Wallet_Transaction;