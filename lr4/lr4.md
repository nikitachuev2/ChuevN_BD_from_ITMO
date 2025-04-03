# Отчет по лабораторной работе №4
Дисциплина: Взаимодействие с базами данных
Студент: Чуев Никита
Группа: П4150
Дата выполнения: 01.04.2025

## Цель работы
Разработка дополнительных объектов базы данных для обеспечения бизнес-логики информационной системы библиотеки, включающая создание триггеров, функций, процедур и транзакций.

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

## Функция проверки доступности книг

CREATE OR REPLACE FUNCTION check_book_availability(p_book_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    available_copies INTEGER;
BEGIN
    SELECT copies_count INTO available_copies 
    FROM books 
    WHERE book_id = p_book_id;
    
    RETURN available_copies > 0;
END;
$$ LANGUAGE plpgsql;

## Функция расчета штрафа за просрочку

CREATE OR REPLACE FUNCTION calculate_overdue_fine(p_loan_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    overdue_days INTEGER;
    fine_amount NUMERIC;
BEGIN
    overdue_days := GREATEST(0, CURRENT_DATE - p_loan_date - INTERVAL '30 days');
    
    IF overdue_days > 0 THEN
        fine_amount := 50 * POWER(2, overdue_days - 1);
        RETURN fine_amount;
    ELSE
        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

## Функция проверки штрафов для регистрации на мероприятия

CREATE OR REPLACE FUNCTION check_event_registration_eligibility(p_reader_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    total_active_fines NUMERIC;
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO total_active_fines
    FROM fines 
    WHERE reader_id = p_reader_id AND status = 'активный';
    
    RETURN total_active_fines <= 500;
END;
$$ LANGUAGE plpgsql;

## Триггер на выдачу книги

CREATE OR REPLACE FUNCTION check_book_loan_trigger()
RETURNS TRIGGER AS $$
DECLARE
    current_loans_count INTEGER;
BEGIN
    -- Проверка количества выданных книг
    SELECT COUNT(*) INTO current_loans_count
    FROM book_loans 
    WHERE reader_id = NEW.reader_id AND status = 'выдана';
    
    IF current_loans_count >= 5 THEN
        RAISE EXCEPTION 'Превышен лимит выдачи книг (максимум 5)';
    END IF;

    -- Проверка доступности книги
    IF NOT check_book_availability(NEW.book_id) THEN
        RAISE EXCEPTION 'Книга недоступна для выдачи';
    END IF;
    
    -- Уменьшение количества копий
    UPDATE books 
    SET copies_count = copies_count - 1 
    WHERE book_id = NEW.book_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER book_loan_limit_check
BEFORE INSERT ON book_loans
FOR EACH ROW
EXECUTE FUNCTION check_book_loan_trigger();

## Триггер на возврат книги с начислением штрафа

CREATE OR REPLACE FUNCTION process_book_return_trigger()
RETURNS TRIGGER AS $$
DECLARE
    overdue_fine NUMERIC;
BEGIN
    -- Возврат копии книги
    UPDATE books 
    SET copies_count = copies_count + 1 
    WHERE book_id = NEW.book_id;
    
    -- Расчет и начисление штрафа
    IF NEW.return_date > (OLD.loan_date + INTERVAL '30 days') THEN
        overdue_fine := calculate_overdue_fine(OLD.loan_date);
        
        INSERT INTO fines (reader_id, book_id, amount, date, status)
        VALUES (
            OLD.reader_id, 
            OLD.book_id, 
            overdue_fine, 
            CURRENT_DATE, 
            'активный'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER book_return_fine_process
BEFORE UPDATE OF status, return_date ON book_loans
FOR EACH ROW
WHEN (OLD.status = 'выдана' AND NEW.status = 'возвращена')
EXECUTE FUNCTION process_book_return_trigger();

## Триггер на регистрацию на мероприятия

CREATE OR REPLACE FUNCTION check_event_registration_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Проверка возможности регистрации
    IF NOT check_event_registration_eligibility(NEW.reader_id) THEN
        RAISE EXCEPTION 'Регистрация невозможна. Имеются непогашенные штрафы.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_registration_fine_check
BEFORE INSERT ON event_registrations
FOR EACH ROW

EXECUTE FUNCTION check_event_registration_trigger();

## Создание таблицы штрафов

CREATE TABLE fines (
    fine_id SERIAL PRIMARY KEY,
    reader_id INTEGER NOT NULL REFERENCES readers(reader_id),
    book_id INTEGER NOT NULL REFERENCES books(book_id),
    amount NUMERIC NOT NULL CHECK (amount >= 0),
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) CHECK (status IN ('активный', 'погашен')) DEFAULT 'активный'
);


## Транзакция выдачи книги читателю

BEGIN;
DO $$
DECLARE
    v_reader_id INTEGER := 1;  -- Первый читатель
    v_book_id INTEGER := 1;    -- Первая книга
    v_new_loan_id INTEGER;
BEGIN
    -- Проверка существования читателя
    IF NOT EXISTS (SELECT 1 FROM readers WHERE reader_id = v_reader_id) THEN
        RAISE EXCEPTION 'Читатель с ID % не найден', v_reader_id;
    END IF;

    -- Проверка существования книги
    IF NOT EXISTS (SELECT 1 FROM books WHERE book_id = v_book_id) THEN
        RAISE EXCEPTION 'Книга с ID % не найдена', v_book_id;
    END IF;

    -- Проверка количества выданных книг
    IF (SELECT COUNT(*) FROM book_loans WHERE reader_id = v_reader_id AND status = 'выдана') >= 5 THEN
        RAISE EXCEPTION 'Превышен лимит выдачи книг (максимум 5)';
    END IF;

    -- Проверка наличия копий книги
    IF (SELECT copies_count FROM books WHERE book_id = v_book_id) <= 0 THEN
        RAISE EXCEPTION 'Нет доступных копий книги';
    END IF;

    -- Вставка новой записи о выдаче книги
    INSERT INTO book_loans (reader_id, book_id, loan_date, status)
    VALUES (v_reader_id, v_book_id, CURRENT_DATE, 'выдана')
    RETURNING loan_id INTO v_new_loan_id;

    -- Уменьшение количества копий
    UPDATE books 
    SET copies_count = copies_count - 1 
    WHERE book_id = v_book_id;

    -- Вывод информации о успешной выдаче
    RAISE NOTICE 'Книга успешно выдана. Номер записи: %', v_new_loan_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Ошибка при выдаче книги: %', SQLERRM;
END $$;

## Транзакция возврата книги с проверкой на просрочку

BEGIN;
DO $$
DECLARE
    v_reader_id INTEGER := 1;  -- Первый читатель
    v_book_id INTEGER := 1;    -- Первая книга
    v_loan_record book_loans%ROWTYPE;
    v_fine_id INTEGER;
    v_overdue_fine NUMERIC;
BEGIN
    -- Поиск активной записи о выдаче для конкретной книги и читателя
    SELECT * INTO v_loan_record
    FROM book_loans
    WHERE reader_id = v_reader_id 
      AND book_id = v_book_id 
      AND status = 'выдана';

    -- Проверка наличия записи о выдаче
    IF v_loan_record IS NULL THEN
        RAISE EXCEPTION 'Нет активной записи о выдаче книги';
    END IF;

    -- Расчет штрафа
    v_overdue_fine := GREATEST(0, 
        50 * POWER(2, GREATEST(0, CURRENT_DATE - v_loan_record.loan_date - INTERVAL '30 days') - 1)
    );

    -- Обновление статуса книги и даты возврата
    UPDATE book_loans
    SET 
        status = 'возвращена', 
        return_date = CURRENT_DATE
    WHERE loan_id = v_loan_record.loan_id;

    -- Возврат копии книги
    UPDATE books 
    SET copies_count = copies_count + 1 
    WHERE book_id = v_book_id;

    -- Начисление штрафа при просрочке
    IF v_overdue_fine > 0 THEN
        INSERT INTO fines (
            reader_id, 
            book_id, 
            amount, 
            date, 
            status
        ) VALUES (
            v_reader_id, 
            v_book_id, 
            v_overdue_fine, 
            CURRENT_DATE, 
            'активный'
        ) RETURNING fine_id INTO v_fine_id;

        RAISE NOTICE 'Начислен штраф в размере % руб. Номер штрафа: %', 
                     v_overdue_fine, v_fine_id;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Ошибка при возврате книги: %', SQLERRM;
END $$;

## Транзакция регистрации на мероприятие

BEGIN;
DO $$
DECLARE
    v_reader_id INTEGER := 1;  -- Первый читатель
    v_event_id INTEGER := 1;   -- Первое мероприятие
    v_registration_id INTEGER;
    v_current_participants INTEGER;
    v_max_participants INTEGER;
    v_active_fines NUMERIC;
BEGIN

    -- Проверка существования читателя
    IF NOT EXISTS (SELECT 1 FROM readers WHERE reader_id = v_reader_id) THEN
        RAISE EXCEPTION 'Читатель с ID % не найден', v_reader_id;
    END IF;

    -- Проверка существования мероприятия
    SELECT max_participants INTO v_max_participants
    FROM events 
    WHERE event_id = v_event_id;

    IF v_max_participants IS NULL THEN
        RAISE EXCEPTION 'Мероприятие с ID % не найдено', v_event_id;
    END IF;

    -- Подсчет текущих участников
    SELECT COUNT(*) INTO v_current_participants
    FROM event_registrations 
    WHERE event_id = v_event_id AND registration_status = 'зарегистрирован';

    -- Проверка заполненности мероприятия
    IF v_current_participants >= v_max_participants THEN
        RAISE EXCEPTION 'Мероприятие заполнено. Регистрация невозможна.';
    END IF;

    -- Проверка штрафов
    SELECT COALESCE(SUM(amount), 0) INTO v_active_fines
    FROM fines 
    WHERE reader_id = v_reader_id AND status = 'активный';

    IF v_active_fines > 500 THEN
        RAISE EXCEPTION 'Имеются непогашенные штрафы. Регистрация запрещена.';
    END IF;

    -- Проверка существующей регистрации
    IF EXISTS (
        SELECT 1 FROM event_registrations 
        WHERE reader_id = v_reader_id 
          AND event_id = v_event_id 
          AND registration_status = 'зарегистрирован'
    ) THEN
        RAISE EXCEPTION 'Читатель уже зарегистрирован на это мероприятие';
    END IF;

    -- Регистрация на мероприятие
    INSERT INTO event_registrations (
        event_id, 
        reader_id, 
        registration_date, 
        registration_status
    ) VALUES (
        v_event_id, 
        v_reader_id, 
        CURRENT_DATE, 
        'зарегистрирован'
    ) RETURNING registration_id INTO v_registration_id;

    RAISE NOTICE 'Регистрация успешна. Номер регистрации: %', v_registration_id;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Ошибка при регистрации на мероприятие: %', SQLERRM;
END $$;

## Анализ 

В рамках проектирования информационной системы библиотеки проведен анализ частоты запросов и особенностей взаимодействия пользователей с базой данных. Установлено, что значительная часть идентификации читателей происходит не по служебному идентификатору, а по личным данным.

### Ключевые наблюдения:
- Посетители редко помнят свой уникальный идентификатор
- Наиболее часто используемый метод поиска – имя и фамилия
- Необходимость быстрого поиска читателя в больших массивах данных

### Цель индексации:
- Оптимизация поиска читателей по личным данным
- Сокращение времени выполнения запросов
- Повышение производительности информационной системы

## Запрос на создание индекса

-- Создание составного индекса для поиска по имени и фамилии
CREATE INDEX idx_reader_full_name ON readers (first_name, last_name);

### Технические характеристики индекса:
- Тип: Составной (B-tree)
- Столбцы: first_name, last_name
- Особенность: Позволяет быстро находить читателей по частичному совпадению имени и фамилии

### Примеры использования индекса:

-- Быстрый поиск читателя
SELECT * FROM readers 
WHERE first_name = 'Алексей' AND last_name = 'Иванов';
