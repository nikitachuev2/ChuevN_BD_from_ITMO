# Отчет по лабораторной работе 3

**Имя студента:** Чуев Никита  
**Группа:** p4150  
**Дата выполнения задания:** 25.03.2025  
**Именование дисциплины:** Взаимодействие с базами данных  

## Текст задания
1. Реализованную в рамках лабораторной работы №2 даталогическую модель привести в 3 нормальную форму.
2. Привести 3 примера анализа функциональной зависимости атрибутов.
3. Обеспечить целостность данных таблиц при помощи средств языка DDL.
4. Заполнить таблицы данными.
5. Разработать скрипты-примеры для создания/удаления объектов базы данных, заполнения/удаления содержимого таблиц.
6. Составить 6+3 примеров SQL запросов на объединение таблиц предметной области.

## Описание предметной области
Библиотека предоставляет читателям доступ к книгам и другим информационным ресурсам, обрабатывает учет выданных книг и осуществляет регистрацию на мероприятия.

#### Анализ функциональной зависимости атрибутов
1. Книги (Таблица books):
   - Зависимость: book_id → title, author, genre, publication_date, copies_count.
   - Описание: Идентификатор книги (book_id) уникально определяет все остальные атрибуты записи о книге, включая название (title), автора (author), жанр (genre), дату публикации (publication_date) и количество доступных экземпляров (copies_count). Это значит, что для каждой книги, представленной в системе, ее идентификатор будет однозначно соответствовать всем другим ее характеристикам.

2. Читатели (Таблица readers):
   - Зависимость: reader_id → first_name, last_name, birth_date, contact_info, registration_date.
   - Описание: Идентификатор читателя (reader_id) обеспечивает уникальность для всех атрибутов, относящихся к этому читателю. Имя (first_name), фамилия (last_name), дата рождения (birth_date), контактная информация (contact_info) и дата регистрации (registration_date) являются производными от уникального идентификатора и изменяются исключительно в зависимости от него. Это позволяет избежать дублирования информации и гарантирует целостность данных о пользователях.

3. Учёт выданных книг (Таблица book_loans):
   - Зависимость: loan_id → reader_id, book_id, loan_date, return_date, status.
   - Описание: Идентификатор займа (loan_id) является ключом, который определяет все атрибуты, связанные с конкретным займом книги. Он уникально связывает читателя (reader_id), книгу (book_id), дату займа (loan_date), дату возврата (return_date) и статус займа (status). Это позволяет отслеживать, какая книга выдана какому читателю, и обеспечивает целостность записей о займах.

4. Мероприятия (Таблица events):
   - Зависимость: event_id → title, event_datetime, description, max_participants, status.
   - Описание: Идентификатор мероприятия (event_id) уникально определяет все атрибуты, относящиеся к мероприятию, включая название (title), дату и время проведения (event_datetime), описание (description), максимальное количество участников (max_participants) и статус мероприятия (status). Каждый идентификатор события гарантирует, что данные о нем не будут перепутаны с данными других мероприятий.

5. Регистрация на мероприятия (Таблица event_registrations):
   - Зависимость: registration_id → event_id, reader_id, registration_date, registration_status.
   - Описание: Идентификатор регистрации (registration_id) однозначно связывает запись о регистрации с идентификатором мероприятия (event_id), читателем (reader_id), датой регистрации (registration_date) и статусом регистрации (registration_status). Это позволяет отслеживать, кто именно зарегистрировался на конкретное мероприятие и в каком статусе находится регистрация.

#### Целостность данных таблиц
Используем следующие виды ограничений целостности:
- **PRIMARY KEY**: гарантирует уникальность идентификатора записи.
- **FOREIGN KEY**: обеспечивает целостность связей между таблицами.
- **CHECK**: гарантирует, что значение в столбце соответствует определенным условиям.
- **UNIQUE**: обеспечивает уникальность значений в столбце или комбинации столбцов.
- **NOT NULL**: запрещает присутствие пустых значений в столбце.
- **DEFAULT**: задает значение по умолчанию для столбца, если оно не указано.

**Таблицы:**

1. **Книги:**

    CREATE TABLE books (book_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL UNIQUE, author VARCHAR(255) NOT NULL, genre VARCHAR(100) NOT NULL, publication_date DATE NOT NULL, copies_count INTEGER NOT NULL CHECK (copies_count >= 0) DEFAULT 1);
    ```

2. **Читатели:**
    CREATE TABLE readers (reader_id SERIAL PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL, birth_date DATE NOT NULL CHECK (birth_date < CURRENT_DATE), contact_info VARCHAR(255) UNIQUE NOT NULL, registration_date DATE NOT NULL DEFAULT CURRENT_DATE);
    ```

3. **Учёт выданных книг:**    
CREATE TABLE book_loans (loan_id SERIAL PRIMARY KEY, reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE, book_id INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE, loan_date DATE NOT NULL DEFAULT CURRENT_DATE, return_date DATE, status VARCHAR(50) CHECK (status IN ('выдана', 'возвращена')) NOT NULL);
    ```

4. **Мероприятия:**

    CREATE TABLE events (event_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL, event_datetime TIMESTAMP NOT NULL, description TEXT, max_participants INTEGER CHECK (max_participants >= 0) NOT NULL, status VARCHAR(50) CHECK (status IN ('грядущее', 'действующее', 'прошедшее')) NOT NULL);
    ```

5. **Регистрация на мероприятия:**

    CREATE TABLE event_registrations (registration_id SERIAL PRIMARY KEY, event_id INTEGER NOT NULL REFERENCES events(event_id) ON DELETE CASCADE, reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE, registration_date DATE NOT NULL DEFAULT CURRENT_DATE, registration_status VARCHAR(50) CHECK (registration_status IN ('зарегистрирован', 'отменён')) NOT NULL);
    ```

#### Скрипты для создания и удаления объектов базы данных
1. Создание таблиц: (были приведены выше).
2. Удаление таблиц: DROP TABLE IF EXISTS event_registrations; DROP TABLE IF EXISTS events; DROP TABLE IF EXISTS book_loans; DROP TABLE IF EXISTS readers; DROP TABLE IF EXISTS books;`


### : Заполнение таблиц данными

#### Заполнение таблицы "Книги"

INSERT INTO books (title, author, genre, publication_date, copies_count) VALUES ('1984', 'George Orwell', 'Dystopian', '1949-06-08', 5), ('To Kill a Mockingbird', 'Harper Lee', 'Fiction', '1960-07-11', 3), ('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', '1925-04-10', 2), ('Moby Dick', 'Herman Melville', 'Adventure', '1851-10-18', 1);

#### Заполнение таблицы "Читатели"

INSERT INTO readers (first_name, last_name, birth_date, contact_info, registration_date) VALUES ('Алексей', 'Иванов', '1990-05-12', 'ivanov@example.com', '2023-01-15'), ('Мария', 'Петрова', '1985-09-23', 'petrova@example.com', '2023-02-20'), ('Иван', 'Сидоров', '2000-11-30', 'sidorov@example.com', '2023-03-10'), ('Наталья', 'Смирнова', '1995-06-05', 'smirnova@example.com', '2023-04-17');

#### Заполнение таблицы "Учёт выданных книг"

INSERT INTO book_loans (reader_id, book_id, loan_date, return_date, status) VALUES (1, 1, '2023-03-01', NULL, 'выдана'), (2, 2, '2023-03-05', '2023-03-15', 'возвращена'), (1, 3, '2023-04-01', NULL, 'выдана'), (3, 1, '2023-04-10', '2023-04-20', 'возвращена');

#### Заполнение таблицы "Мероприятия"

INSERT INTO events (title, event_datetime, description, max_participants, status) VALUES ('Книжная выставка', '2023-05-10 10:00:00', 'Выставка новых книг', 50, 'грядущее'), ('Лекция по литературе', '2023-05-15 14:00:00', 'Лекция о современных авторах', 30, 'грядущее'), ('Чтение вслух', '2023-05-20 18:00:00', 'Чтение классической литературы', 20, 'грядущее'), ('Воркшоп по писательству', '2023-06-01 16:00:00', 'Обучение основам писательского мастерства', 25, 'грядущее');

#### Заполнение таблицы "Регистрация на мероприятия"

INSERT INTO event_registrations (event_id, reader_id, registration_date, registration_status) VALUES (1, 1, '2023-04-01', 'зарегистрирован'), (1, 2, '2023-04-02', 'зарегистрирован'), (2, 1, '2023-04-05', 'зарегистрирован'), (3, 3, '2023-04-10', 'зарегистрирован');

### : Составление SQL запросов для извлечения и анализа данных

#### : Получение списка всех книг и их авторов

SELECT title, author FROM books;

#### : Получение информации о читателях, которые взяли книги

SELECT r.first_name, r.last_name, bl.loan_date, b.title FROM readers r JOIN book_loans bl ON r.reader_id = bl.reader_id JOIN books b ON bl.book_id = b.book_id;

#### : Получение списка всех мероприятий и количества участников

SELECT e.title, e.event_datetime, COUNT(er.registration_id) AS participant_count FROM events e LEFT JOIN event_registrations er ON e.event_id = er.event_id GROUP BY e.event_id;

#### : Получение списка выданных книг с информацией о дате возврата

SELECT b.title, bl.loan_date, bl.return_date FROM books b JOIN book_loans bl ON b.book_id = bl.book_id WHERE bl.status = 'выдана';

#### : Получение всех читателей с количеством книг на руках

SELECT r.first_name, r.last_name, COUNT(bl.loan_id) AS books_on_loan FROM readers r LEFT JOIN book_loans bl ON r.reader_id = bl.reader_id WHERE bl.status = 'выдана' GROUP BY r.reader_id;

### : Составление SQL запросов на объединение таблиц предметной области

#### : Получение полного списка данных о читателях и их выданных книгах

SELECT r.first_name, r.last_name, b.title, bl.loan_date FROM readers r JOIN book_loans bl ON r.reader_id = bl.reader_id JOIN books b ON bl.book_id = b.book_id WHERE bl.status = 'выдана';

#### : Получение статистики по мероприятиям и зарегистрированным читателям

SELECT e.title, COUNT(er.reader_id) AS registered_count FROM events e LEFT JOIN event_registrations er ON e.event_id = er.event_id GROUP BY e.event_id;

#### : Получение списка читателей, которые зарегистрированы на каждое мероприятие

SELECT e.title, r.first_name, r.last_name FROM events e JOIN event_registrations er ON e.event_id = er.event_id JOIN readers r ON er.reader_id = r.reader_id;

#### : Получение информации о книгах и количестве раз, когда они были выданы

SELECT b.title, COUNT(bl.loan_id) AS loan_count FROM books b LEFT JOIN book_loans bl ON b.book_id = bl.book_id GROUP BY b.book_id;

#### : Получение списка всех мероприятий с читателями, зарегистрированными на них

SELECT e.title, r.first_name, r.last_name FROM events e LEFT JOIN event_registrations er ON e.event_id = er.event_id LEFT JOIN readers r ON er.reader_id = r.reader_id;
