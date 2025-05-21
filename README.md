# Настройка репликации в PostgreSQL

## Данные для подключения

- Хост: localhost
- Порты: 5432/5433
- База данных: app_db
- Пользователь: pgadmin
- Пароль: adminpassword

---

## Проверка репликации

**На Мастере (порт 5432):**
``` SQL
-- Проверим существующие данные
SELECT * FROM users; SELECT * FROM products; 
-- Вставим новые данные 
INSERT INTO users (email, password, first_name, last_name, role) VALUES ('newcustomer@example.com', 'newpass123', 'New', 'Customer', 'customer'); 
-- Проверим, что данные вставились 
SELECT * FROM users WHERE email = 'newcustomer@example.com';
```

**На Реплике (порт 5433):**
``` SQL
-- Попробуем прочитать данные, которые только что вставили на мастере 
SELECT * FROM users WHERE email = 'newcustomer@example.com'; 
-- Попробуем вставить данные
INSERT INTO users (email, password, first_name, last_name, role) VALUES ('anothercustomer@example.com', 'anotherpass', 'Another', 'Person', 'customer');
-- SQL Error [25006]: ERROR: cannot execute INSERT in a read-only transaction.
```
