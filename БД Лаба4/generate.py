import psycopg2
import random
from faker import Faker
from datetime import datetime, timedelta

# --- НАСТРОЙКИ ПОДКЛЮЧЕНИЯ К БД ---
DB_NAME = "stock_exchange"
DB_USER = "artyomkulikov"
DB_PASSWORD = ""
DB_HOST = "localhost"
DB_PORT = "5432"

# --- ПОДКЛЮЧЕНИЕ ---
conn = psycopg2.connect(
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT
)
cur = conn.cursor()
fake = Faker('ru_RU')

# --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---
def random_phone():
    return ''.join([str(random.randint(0,9)) for _ in range(11)])

def random_snils():
    return ''.join([str(random.randint(0,9)) for _ in range(11)])

def random_inn():
    return ''.join([str(random.randint(0,9)) for _ in range(12)])

def random_passport():
    return ''.join([str(random.randint(0,9)) for _ in range(10)])

def random_card_number():
    return ''.join([str(random.randint(0,9)) for _ in range(16)])

def random_account():
    return ''.join([str(random.randint(0,9)) for _ in range(20)])

def random_cvv():
    return ''.join([str(random.randint(0,9)) for _ in range(3)])

# --- КОЛИЧЕСТВО ЗАПИСЕЙ ---
NUM_USERS = 100
NUM_TARIFFS = 5
NUM_EXCHANGES = 3
NUM_SECURITIES = 20
NUM_RATES = 10
NUM_CONTRACTS = 200
NUM_SERVICE_CONTRACTS = 200
NUM_BANK_TRANS = 500
NUM_BROKER_TRANS = 500
NUM_POSITIONS = 300
NUM_LOGS = 1000

# --- 1. ПОЛЬЗОВАТЕЛИ ---
print("Генерация пользователей...")
user_ids = []
used_snils = set()
used_email = set()
used_inn = set()
used_passport = set()
for _ in range(NUM_USERS):
    snils = random_snils()
    while snils in used_snils:
        snils = random_snils()
    used_snils.add(snils)
    email = fake.unique.email()
    inn = random_inn()
    while inn in used_inn:
        inn = random_inn()
    used_inn.add(inn)
    passport = random_passport()
    while passport in used_passport:
        passport = random_passport()
    used_passport.add(passport)
    last = fake.last_name_male()
    first = fake.first_name_male()
    middle = fake.middle_name_male()
    fio = f"{last} {first} {middle}"
    phone = random_phone()
    date_reg = fake.date_time_between(start_date='-2y', end_date='now')
    password = fake.md5()
    cur.execute("""
        INSERT INTO пользователь (снилс, почта, инн, паспорт, фио, телефон, дата_регистрации, пароль)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id
    """, (snils, email, inn, passport, fio, phone, date_reg, password))
    user_ids.append(cur.fetchone()[0])
conn.commit()

# --- 2. ТАРИФЫ ---
print("Генерация тарифов...")
tariff_ids = []
tarifs = ['Золотой', 'Чемпионский', 'Бриллиантовый', 'Бедный', 'Нищий']
for _ in range(NUM_TARIFFS):
    name = random.choice(tarifs)
    tarifs.remove(name)
    price = round(random.uniform(0, 500000), 2)
    rate = round(random.uniform(-5, 30), 2)
    cur.execute("""
        INSERT INTO тариф (условия_обслуживания, цена, ставка)
        VALUES (%s, %s, %s) RETURNING id
    """, (name, price, rate))
    tariff_ids.append(cur.fetchone()[0])
conn.commit()

# --- 3. БИРЖИ ---
print("Генерация бирж...")
exchange_ids = []
for _ in range(NUM_EXCHANGES):
    ticker = fake.unique.lexify(text='????').upper()
    name = fake.unique.company()
    cur.execute("""
        INSERT INTO биржа (тикер, название)
        VALUES (%s, %s) RETURNING id
    """, (ticker, name))
    exchange_ids.append(cur.fetchone()[0])
conn.commit()

# --- 4. ЦЕННЫЕ БУМАГИ ---
print("Генерация ценных бумаг...")
security_ids = []
types = ['Акция', 'Облигация', 'Валюта']
for _ in range(NUM_SECURITIES):
    ticker = fake.unique.lexify(text='????').upper()
    name = fake.unique.company()
    typ = random.choice(types)
    cur.execute("""
        INSERT INTO ценная_бумага (тикер, название, тип)
        VALUES (%s, %s, %s) RETURNING id
    """, (ticker, name, typ))
    security_ids.append(cur.fetchone()[0])
conn.commit()

# --- 5. КУРС ВАЛЮТ ---
print("Генерация курсов валют...")
rate_ids = []
rate_info = []
currencies = ['USD', 'EUR', 'GBP', 'CHF', 'CNY']
for _ in range(NUM_RATES):
    currency = random.choice(currencies)
    rate = round(random.uniform(0, 150), 4)
    date = fake.date_time_between(start_date='-2y', end_date='now')
    cur.execute("""
        INSERT INTO курс_валют (курс, валюта, дата)
        VALUES (%s, %s, %s) RETURNING id
    """, (rate, currency, date))
    rate_id = cur.fetchone()[0]
    rate_ids.append(rate_id)
    rate_info.append({
        'id': rate_id,
        'дата': date
    })
conn.commit()

# --- 6. БРОКЕРСКИЕ ДОГОВОРЫ ---
print("Генерация брокерских договоров и кошельков...")
contract_ids = []
wallet_ids = []
contract_user_map = []
for _ in range(NUM_CONTRACTS):
    user_id = random.choice(user_ids)
    date_open = fake.date_time_between(start_date='-2y', end_date='now')
    date_close = fake.date_time_between(start_date=date_open, end_date='now') if random.random() > 0.7 else None
    typ = random.choice(['Обычный', 'ИИС'])
    if date_close: status = 'Заблокирован'
    else: status = 'Активен'
    cur.execute("""
        INSERT INTO брокерский_договор (id_пользователя, дата_открытия, дата_закрытия, тип, статус)
        VALUES (%s, %s, %s, %s, %s) RETURNING id
    """, (user_id, date_open, date_close, typ, status))

    cid = cur.fetchone()[0]
    contract_ids.append(cid)
    contract_user_map.append((cid, user_id))

    entity = 'Брокерский договор'
    id_rec = cid
    log_time = date_open
    log_type = 'Открыто'
    cur.execute("""
            INSERT INTO логгер (сущность, id_записи, время, тип)
            VALUES (%s, %s, %s, %s)
        """, (entity, id_rec, log_time, log_type))

    if(status == 'Закрыт'):
        entity = 'Брокерский договор'
        id_rec = cid
        log_time = date_close
        log_type = 'Закрыто'
        cur.execute("""
            INSERT INTO логгер (сущность, id_записи, время, тип)
            VALUES (%s, %s, %s, %s)
         """, (entity, id_rec, log_time, log_type))

    balance = round(random.uniform(0, 100000), 2)
    profit = round(random.uniform(-10000, 10000), 2)
    if(status == 'Закрыт'): status = 'Заблокирован'
    cur.execute("""
        INSERT INTO кошелек (id_договора, остаток, прибыль, статус)
        VALUES (%s, %s, %s, %s) RETURNING id_договора
    """, (cid, balance, profit, status))
    wallet_ids.append(cid)
conn.commit()

# --- 7. ДОГОВОРЫ ОБ ОБСЛУЖИВАНИИ ---
print("Генерация договоров обслуживания и карт...")
service_ids = []
card_ids = []
service_user_map = []
for _ in range(NUM_SERVICE_CONTRACTS):
    user_id = random.choice(user_ids)
    tariff_id = random.choice(tariff_ids)
    date_open = fake.date_time_between(start_date='-2y', end_date='now')
    date_close = fake.date_time_between(start_date=date_open, end_date='now') if random.random() > 0.7 else None
    cur.execute("""
        INSERT INTO договор_об_обслуживании (id_пользователя, id_тарифа, дата_открытия, дата_закрытия)
        VALUES (%s, %s, %s, %s) RETURNING id
    """, (user_id, tariff_id, date_open, date_close))
    service_id = cur.fetchone()[0]
    service_ids.append(service_id)
    service_user_map.append((service_id, user_id))
    card_num = random_card_number()
    typ = random.choice(['Дебетовая', 'Кредитная'])
    cvv = random_cvv()
    account = random_account()
    cur.execute("""
            INSERT INTO карта (id_договора, номер_карты, тип, cvv, номер_счета)
            VALUES (%s, %s, %s, %s, %s) RETURNING id_договора
        """, (service_id, card_num, typ, cvv, account))
    card_ids.append(service_id)

    entity = 'Договор об обслуживании'
    id_rec = service_id
    log_time = date_open
    log_type = 'Открыто'
    cur.execute("""
                INSERT INTO логгер (сущность, id_записи, время, тип)
                VALUES (%s, %s, %s, %s)
            """, (entity, id_rec, log_time, log_type))

    if date_close:
        entity = 'Договор об обслуживании'
        id_rec = service_id
        log_time = date_close
        log_type = 'Закрыто'
        cur.execute("""
                        INSERT INTO логгер (сущность, id_записи, время, тип)
                        VALUES (%s, %s, %s, %s)
                    """, (entity, id_rec, log_time, log_type))
conn.commit()


# --- 10. ПОРТФЕЛИ ---
print("Генерация портфелей...")
for contract_id in contract_ids:
    cur.execute("""
        INSERT INTO портфель (id_договора)
        VALUES (%s) ON CONFLICT DO NOTHING
    """, (contract_id,))
conn.commit()

# --- 11. ТОРГОВЫЕ ИНСТРУМЕНТЫ ---
trading_instruments = []
print("Генерация торговых инструментов...")
for sec_id in security_ids:
    for exch_id in exchange_ids:
        if random.random() > 0.3:
            sell = round(random.uniform(50, 500), 4)
            buy = round(sell * random.uniform(0.95, 0.99), 4)
            cur.execute("""
                INSERT INTO торговый_инструмент (id_бумаги, id_биржи, цена_продажи, цена_покупки)
                VALUES (%s, %s, %s, %s) ON CONFLICT DO NOTHING
            """, (sec_id, exch_id, sell, buy))
            trading_instruments.append((sec_id, exch_id))
conn.commit()

# --- 12. БАНКОВСКИЕ ТРАНЗАКЦИИ (с проверкой на одного пользователя) ---
print("Генерация банковских транзакций...")
bank_trans_ids = []
for _ in range(NUM_BANK_TRANS):
    uid = random.choice(user_ids)
    user_contracts = [cid for cid, cuid in contract_user_map if cuid == uid]
    if not user_contracts:
        continue
    user_services = [sid for sid, suid in service_user_map if suid == uid]
    if not user_services:
        continue
    service_id = random.choice(user_services)
    contract_id = random.choice(user_contracts)
    amount = round(random.uniform(-5000000, 5000000), 2)
    status = random.choice(['Удачная', 'Неудачная', 'В процессе'])
    cur.execute("""
        INSERT INTO транзакция_банк_кошелек (id_договора_об_обслуживании, id_брокерского_договора, сумма, статус)
        VALUES (%s, %s, %s, %s) RETURNING id
    """, (service_id, contract_id, amount, status))
    bank_trans_id = cur.fetchone()[0]
    bank_trans_ids.append(bank_trans_id)

    entity = 'Транзакция банк/с'
    id_rec = bank_trans_id
    log_time = fake.date_time_between(start_date='-2y', end_date='now')
    if status == 'Удачная': log_type = 'Успешно'
    elif status == 'Неудачная': log_type = 'Отклонено'
    else: log_type = 'В процессе'
    cur.execute("""
                    INSERT INTO логгер (сущность, id_записи, время, тип)
                    VALUES (%s, %s, %s, %s)
                """, (entity, id_rec, log_time, log_type))
conn.commit()

# --- 13. БРОКЕРСКИЕ ТРАНЗАКЦИИ ---
print("Генерация брокерских транзакций...")
broker_trans_ids = []
for _ in range(NUM_BROKER_TRANS):
    sec_id, exch_id = random.choice(trading_instruments)
    rate = random.choice(rate_info)
    rate_id = rate['id']
    contract_id = random.choice(contract_ids)
    lots = random.randint(1, 1000000)
    price = round(random.uniform(50, 500), 4)
    status = random.choice(['Удачная', 'Неудачная', 'В процессе'])
    cur.execute("""
        INSERT INTO транзакция_брокер_кошелек 
        (id_брокерского_договора, id_бумаги, id_биржи, id_курса, количество_лотов, цена_за_лот, статус)
        VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id
    """, (contract_id, sec_id, exch_id, rate_id, lots, price, status))
    broker_trans_id = cur.fetchone()[0]
    broker_trans_ids.append(broker_trans_id)

    entity = 'Транзакция брокер/с'
    id_rec = broker_trans_id
    log_time = rate['дата']
    if status == 'Удачная':
        log_type = 'Успешно'
    elif status == 'Неудачная':
        log_type = 'Отклонено'
    else:
        log_type = 'В процессе'
    cur.execute("""
                        INSERT INTO логгер (сущность, id_записи, время, тип)
                        VALUES (%s, %s, %s, %s)
                    """, (entity, id_rec, log_time, log_type))
conn.commit()

# --- 14. ОСТАТКИ ---
print("Генерация остатков...")
seen = set()
for _ in range(NUM_POSITIONS):
    contract_id = random.choice(contract_ids)
    sec_id = random.choice(security_ids)
    while (contract_id, sec_id) in seen:
        contract_id = random.choice(contract_ids)
        sec_id = random.choice(security_ids)
    seen.add((contract_id, sec_id))
    lots = random.randint(1, 1000000)
    cur.execute("""
        INSERT INTO остаток (id_бумаги, id_договора, количество_лотов)
        VALUES (%s, %s, %s) ON CONFLICT DO NOTHING
    """, (sec_id, contract_id, lots))
conn.commit()

print("✅ Генерация завершена!")
cur.close()
conn.close()