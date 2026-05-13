CREATE INDEX idx_logger_entity_type_time 
ON Logger (entity, type, time DESC);

CREATE INDEX idx_bank_tx_amount_broker_service 
ON Bank_Wallet_Transaction (amount, broker_id, service_id) 
WHERE amount > 0;

CREATE INDEX idx_broker_tx_broker_id_id
ON Broker_Wallet_Transaction (broker_id, id);

ANALYZE Logger, Bank_Wallet_Transaction, Broker_Wallet_Transaction;

