# Отчет по лабораторной работе №4
Дисциплина: Взаимодействие с базами данных
Студент: Чуев Никита
Группа: П4150
Дата выполнения: 01.04.2025

## Текст задания

·  Описать бизнес-правила вашей предметной области. Какие в вашей системе могут быть действия, требующие выполнения запроса в БД. Эти бизнес-правила будут использованы для реализации триггеров, функций, процедур, транзакций поэтому приниматься будут только достаточно интересные бизнес-правила
·  Добавить в ранее созданную базу данных триггеры для обеспечения комплексных ограничений целостности. Триггеров должно быть не менее трех
·  Реализовать функции и процедуры на основе описания бизнес-процессов, определенных при описании предметной области из пункта 1. Примеров не менее 3
·  Привести 3 примера выполнения транзакции. Это может быть, например, проверка корректности вводимых данных для созданных функций и процедур. Например, функция, которая вносит данные. Данные проверяются и в случае если они не подходят ограничениям целостности, транзакция должна откатываться
·  Необходимо произвести анализ использования созданной базы данных, выявить наиболее часто используемые объекты базы данных, виды запросов к ним. Результаты должны быть представлены в виде текстового описания
·  На основании полученного описания требуется создать подходящие индексы и доказать, что они будут полезны для представленных в описании случаев использования базы данных.

Отчёт по лабораторной работе должен содержать:
·  титульный лист;
·  текст задания;
·  код триггеров, функций, процедур, транзакций;
·  описание наиболее часто используемых сценариев при работе с базой данных;
·  описание индексов и обоснование их использования;

## Бизнес-правила предметной области
В рамках информационной системы библиотеки были определены следующие бизнес-правила:
1. Учет выдачи книг:
   - Каждая книга может быть выдана только при наличии доступных экземпляров. Максимальное количество одновременно выданных книг одному читателю составляет 5. Это допускает равный доступ к коллекции для всех пользователей.
   - Триггер: При обновлении статуса книги на "выдана" система проверяет наличие доступных экземпляров. Если экземпляры доступны, количество уменьшается на 1. Если доступных экземпляров нет, транзакция откатывается, и пользователю выдается уведомление с рекомендацией проверить наличие других книг.
   - Функция: Проверка количества доступных экземпляров книги перед выдачей, включая возможность предоставления альтернативных рекомендаций в случае отсутствия экземпляров.

2. Возврат книг и начисление штрафа:
   - Если книга возвращается позже срока (например, 30 дней с момента выдачи), для читателя автоматически рассчитывается штраф. Начальный штраф составляет 50 рублей за первый день просрочки и увеличивается по экспоненциальной формуле (например, 50 рублей за первый день, 100 рублей за второй, 200 рублей за третий и так далее).
   - Триггер: При обновлении статуса книги на "возвращена" система проверяет дату возврата. Если книга возвращается поздно, штраф автоматически вычисляется и записывается в отдельную таблицу fines (штрафы), связанной с читателем.
   - Функция: Расчет суммы штрафа на основе длительности просрочки с применением экспоненциальной формулы. Функция будет обновлять таблицу штрафов с новыми данными.

3. Регистрация на мероприятия:
   - Читатель может зарегистрироваться на мероприятия только в том случае, если сумма его активных штрафов не превышает 500 рублей. При наличии задолженности регистрация в системах блокируется до ее погашения.
   - Триггер: При попытке регистрации на мероприятие система проверяет, имеются ли активные штрафы у читателя. Если сумма штрафов превышает 500 рублей, транзакция откатывается, и пользователю отображается сообщение о том, что регистрация временно недоступна из-за задолженности.
   - Функция: Проверка наличия активных штрафов перед регистрацией на мероприятия, предоставляя пользователю информацию о текущем состоянии долгов и предлагая способы их погашения, а также возможные акции.
###  Используем ранее разработанные таблицы + добавим новую таблицу со штрафами

-- Запрос для создания всех таблиц библиотеки
CREATE TABLE books (book_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL UNIQUE, author VARCHAR(255) NOT NULL, genre VARCHAR(100) NOT NULL, publication_date DATE NOT NULL, copies_count INTEGER NOT NULL CHECK (copies_count >= 0) DEFAULT 1);
CREATE TABLE readers (reader_id SERIAL PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL, birth_date DATE NOT NULL CHECK (birth_date < CURRENT_DATE), contact_info VARCHAR(255) UNIQUE NOT NULL, registration_date DATE NOT NULL DEFAULT CURRENT_DATE);
CREATE TABLE book_loans (loan_id SERIAL PRIMARY KEY, reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE, book_id INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE, loan_date DATE NOT NULL DEFAULT CURRENT_DATE, return_date DATE, status VARCHAR(50) CHECK (status IN ('выдана', 'возвращена')) NOT NULL);
CREATE TABLE events (event_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL, event_datetime TIMESTAMP NOT NULL, description TEXT, max_participants INTEGER CHECK (max_participants >= 0) NOT NULL, status VARCHAR(50) CHECK (status IN ('грядущее', 'действующее', 'прошедшее')) NOT NULL);
CREATE TABLE event_registrations (registration_id SERIAL PRIMARY KEY, event_id INTEGER NOT NULL REFERENCES events(event_id) ON DELETE CASCADE, reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE, registration_date DATE NOT NULL DEFAULT CURRENT_DATE, registration_status VARCHAR(50) CHECK (registration_status IN ('зарегистрирован', 'отменён')) NOT NULL);
CREATE TABLE fines (fine_id SERIAL PRIMARY KEY, reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE, book_id INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE, fine_amount DECIMAL(10,2) NOT NULL, date_issued DATE NOT NULL DEFAULT CURRENT_DATE);

### создадим три функции и тригера
### 1. Функция для проверки доступных экземпляров книги перед выдачей

-- Функция для проверки наличия доступных экземпляров книги
CREATE OR REPLACE FUNCTION check_book_availability(book_id INT) 
RETURNS BOOLEAN AS $$
DECLARE
    available_copies INT;
BEGIN
    -- Получаем количество доступных экземпляров книги
    SELECT copies_count INTO available_copies FROM books WHERE book_id = book_id;

    -- Если количество доступных экземпляров больше 0, возвращаем TRUE, иначе FALSE
    RETURN available_copies > 0;
END;
$$ LANGUAGE plpgsql;

### 2. Триггер для автоматического уменьшения количества экземпляров книги при выдаче

-- Триггер для уменьшения количества экземпляров книги при её выдаче
CREATE OR REPLACE FUNCTION trigger_reduce_book_copies() 
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем наличие доступных экземпляров книги
    IF check_book_availability(NEW.book_id) THEN
        -- Если экземпляры доступны, уменьшаем их количество
        UPDATE books SET copies_count = copies_count - 1 WHERE book_id = NEW.book_id;
        RETURN NEW; -- Возвращаем новые данные записи о выдаче
    ELSE
        RAISE EXCEPTION 'Нет доступных экземпляров для книги с ID %', NEW.book_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER reduce_book_copies
AFTER INSERT ON book_loans -- Триггер срабатывает после добавления записи о выдаче книги
FOR EACH ROW EXECUTE FUNCTION trigger_reduce_book_copies();

### 3. Функция для расчета суммы штрафа при возврате книги

-- Функция для расчета суммы штрафа на основе длительности просрочки
CREATE OR REPLACE FUNCTION calculate_fine(loan_id INT) 
RETURNS INT AS $$
DECLARE
    days_late INT;
    fine_amount INT;
BEGIN
    -- Получаем количество дней просрочки
    SELECT CURRENT_DATE - loan_date INTO days_late FROM book_loans WHERE loan_id = loan_id;

    -- Проверяем, если книга возвращается позже срока
    IF days_late > 0 THEN
        -- Рассчитываем штраф по экспоненциальной формуле
        fine_amount := 50 * (2 ^ (days_late - 1));
        RETURN fine_amount; -- Возвращаем сумму штрафа
    ELSE
        RETURN 0; -- Если нет просрочки, штраф 0
    END IF;
END;
$$ LANGUAGE plpgsql;

### 4. Триггер для начисления штрафа при возврате книги

-- Триггер для начисления штрафа при возврате книги
CREATE OR REPLACE FUNCTION trigger_calculate_fine() 
RETURNS TRIGGER AS $$
DECLARE
    fine_amount INT;
BEGIN
    -- Рассчитываем штраф на основе записи о выдаче
    fine_amount := calculate_fine(NEW.loan_id);
    
    -- Если штраф больше 0, добавляем запись о штрафе в таблицу fines
    IF fine_amount > 0 THEN
        INSERT INTO fines (reader_id, fine_amount, date_issued) 
        VALUES (NEW.reader_id, fine_amount, CURRENT_DATE);
    END IF;
    
    RETURN NEW; -- Возвращаем изменения
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_fine_trigger
AFTER UPDATE ON book_loans -- Триггер срабатывает после обновления статуса книги
FOR EACH ROW EXECUTE FUNCTION trigger_calculate_fine();

### 5. Функция для проверки активных штрафов перед регистрацией на мероприятие

-- Функция для проверки суммы активных штрафов читателя
CREATE OR REPLACE FUNCTION check_active_fines(reader_id INT) 
RETURNS BOOLEAN AS $$
DECLARE
    total_fine INT;
BEGIN
    -- Суммируем все активные штрафы для данного читателя
    SELECT COALESCE(SUM(fine_amount), 0) INTO total_fine FROM fines WHERE reader_id = reader_id;

    -- Если сумма штрафов больше 500 рублей, возвращаем FALSE

    RETURN total_fine <= 500; -- Возвращаем TRUE, если активных штрафов меньше или равно 500
END;
$$ LANGUAGE plpgsql;

### 6. Триггер для блока регистрации на мероприятия при наличии задолженности

-- Триггер для блокировки регистрации на мероприятие при наличии задолженности
CREATE OR REPLACE FUNCTION trigger_event_registration_check() 
RETURNS TRIGGER AS $$
BEGIN
    -- Проверяем наличие активных штрафов у читателя перед регистрацией на мероприятие
    IF NOT check_active_fines(NEW.reader_id) THEN
        RAISE EXCEPTION 'Регистрация на мероприятие временно недоступна из-за активных штрафов';
    END IF;

    RETURN NEW; -- Возвращаем изменения
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_registration_check
BEFORE INSERT ON event_registrations -- Триггер срабатывает перед добавлением записи о регистрации на мероприятие
FOR EACH ROW EXECUTE FUNCTION trigger_event_registration_check();

### Транзакция 1: Выдача книги читателю

Эта транзакция проверяет наличие доступных экземпляров книги и ограничение на максимальное количество одновременно выданных книг для читателя. Если все условия выполнены, книга выдается.

BEGIN;

-- Проверка, может ли читатель взять больше 5 книг
DO $$
DECLARE
    current_loans INT;
BEGIN
    SELECT COUNT(*) INTO current_loans
    FROM book_loans
    WHERE reader_id = $1 AND status = 'выдана'; -- $1 - ID читателя

    IF current_loans >= 5 THEN
        RAISE EXCEPTION 'Читатель уже выдал максимальное количество книг.';
    END IF;
END;
$$;

-- Если все проверки пройдены, добавляем запись в таблицу book_loans
INSERT INTO book_loans (reader_id, book_id, loan_date, status)
VALUES ($1, $2, CURRENT_DATE, 'выдана'); -- $1 - ID читателя, $2 - ID книги

COMMIT;

### Транзакция 2: Возврат книги и начисление штрафа

Эта транзакция обновляет статус книги на "возвращена", проверяет срок возврата и, если необходимо, начисляет штраф.

BEGIN;

-- Обновляем статус книги на "возвращена"
UPDATE book_loans 
SET status = 'возвращена', return_date = CURRENT_DATE 
WHERE loan_id = $1; -- $1 - ID займа

-- Рассчитываем штраф
DO $$
DECLARE
    fine_amount INT;
BEGIN
    fine_amount := calculate_fine($1); -- Вызов функции для расчета штрафа

    -- Если штраф больше 0, добавляем запись в таблицу штрафов
    IF fine_amount > 0 THEN
        INSERT INTO fines (reader_id, fine_amount, date_issued) 
        VALUES ((SELECT reader_id FROM book_loans WHERE loan_id = $1), fine_amount, CURRENT_DATE);
    END IF;
END;
$$;

COMMIT;

### Транзакция 3: Регистрация читателя на мероприятие

Эта транзакция проверяет активные штрафы читателя перед регистрацией на мероприятие и добавляет запись, если все условия выполнены.

BEGIN;

-- Проверяем активные штрафы
IF NOT check_active_fines($1) THEN -- $1 - ID читателя
    RAISE EXCEPTION 'Регистрация на мероприятие временно недоступна из-за активных штрафов';
END IF;

-- Добавляем запись о регистрации на мероприятие
INSERT INTO event_registrations (reader_id, event_id) 
VALUES ($1, $2); -- $1 - ID читателя, $2 - ID мероприятия

COMMIT;


#### Создание тестовых читателей

-- Вставка тестовых читателей
INSERT INTO readers (first_name, last_name, birth_date, contact_info)
VALUES 
('Никита', 'Чуев', '2002-01-15', 'petrov@example.com'),
('Илья', 'Выдумкин', '1985-06-10', 'sidorov@example.com'),
('Никита', 'Ковалев', '1992-05-22', 'ivanova@example.com');

ID читателей:
- Никита Чуев- 1
- Илья Выдумкин- 2
- Никита Ковалев- 3

#### 1.2 Создание тестовых книг

-- Вставка тестовых книг
INSERT INTO books (title, author, genre, publication_date, copies_count)
VALUES 
('Война и мир', 'Лев Толстой', 'Роман', '1869-01-01', 3),
('1984', 'Джордж Оруэлл', 'Фантастика', '1949-06-08', 2),
('Код да Винчи', 'Дэн Браун', 'Триллер', '2003-03-18', 4);

ID книг:
- Война и мир - 1
- 1984 - 2
- Код да Винчи - 3

#### 1.3 Создание тестовых мероприятий

-- Вставка тестовых мероприятий
INSERT INTO events (title, event_datetime, description, max_participants, status)
VALUES 
('Книжная ярмарка', '2025-05-10 10:00:00', 'Описание книжной ярмарки', 50, 'грядущее'),
('Летняя встреча читателей', '2025-07-15 18:00:00', 'Встреча читателей', 30, 'грядущее');

ID мероприятий:
- Книжная ярмарка - 1
- Летняя встреча читателей - 2

### : Использование тестовых данных для проверки транзакций

#### Проверка выдачи книги

например, на примере Никиты Чуева(ID 1) и книги "1984" (ID 2).

BEGIN;

DO $$
DECLARE
    current_loans INT;
BEGIN
    SELECT COUNT(*) INTO current_loans
    FROM book_loans
    WHERE reader_id = 1 AND status = 'выдана';

    IF current_loans >= 5 THEN
        RAISE EXCEPTION 'Читатель уже выдал максимальное количество книг.';
    END IF;
END;
$$;

INSERT INTO book_loans (reader_id, book_id, loan_date, status)
VALUES (1, 2, CURRENT_DATE, 'выдана'); -- Алексея Петрова получает книгу '1984'

COMMIT;

#### Проверка возврата книги и начисления штрафа

Теперь можно протестировать возврат книги "1984" прочитанной Никитой задержкой, чтобы увидеть начисление штрафа:

-- Изменим дату выдачи книги на более раннюю, чтобы имитировать просрочку
UPDATE book_loans 
SET loan_date = CURRENT_DATE - INTERVAL '40 days'
WHERE loan_id = 1; -- Здесь 1 - ID займа

-- Теперь выполняем возврат книги
BEGIN;

UPDATE book_loans 
SET status = 'возвращена', return_date = CURRENT_DATE 
WHERE loan_id = 1; -- ID займа

DO $$
DECLARE
    fine_amount INT;
BEGIN
    fine_amount := calculate_fine(1); -- Вызов функции для расчета штрафа на основе ID займа

    IF fine_amount > 0 THEN
        INSERT INTO fines (reader_id, fine_amount, date_issued) 
        VALUES (1, fine_amount, CURRENT_DATE); -- Добавляем штраф для Никиты
    END IF;
END;
$$;

COMMIT;

#### Проверка регистрации на мероприятие

Теперь протестируем регистрацию Никиты на мероприятие, например, на "Книжная ярмарка" (ID 1):

BEGIN;

IF NOT check_active_fines(1) THEN -- Проверка активных штрафов у Никиты
    RAISE EXCEPTION 'Регистрация на мероприятие временно недоступна из-за активных штрафов';
END IF;

INSERT INTO event_registrations (reader_id, event_id)
VALUES (1, 1); -- Регистрация Никиты на мероприятие

COMMIT;

### : Проверка результатов

SELECT-запросы для проверки данных:

-- Проверка выданных книг

SELECT * FROM book_loans;

-- Проверка начисленных штрафов
SELECT * FROM fines;

-- Проверка регистраций на мероприятия
SELECT * FROM event_registrations;

## Создание индекса для таблицы читателей

### Цель
Оптимизация поиска читателей по имени и фамилии.

### Обоснование
- Частый поиск по полям first_name и last_name
- Необходимость быстрого доступа к данным читателей

### Решение
Создание составного индекса для полей имени и фамилии.

### Запрос

CREATE INDEX idx_readers_full_name ON readers (first_name, last_name);

