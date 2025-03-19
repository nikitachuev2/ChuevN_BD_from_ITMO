# Лабораторная работа 2

Чуев Никита  
Группа: p4150  
Дата выполнения задания: 15.03.2025  
Именование дисциплины: Взаимодействие с базами данных  

## Текст задания

1. Из описания предметной области, полученной в ходе выполнения ЛР 1, выделить сущности, их атрибуты и связи, отразить их в инфологической модели (она же концептуальная).
2. Составить даталогическую (она же ER-диаграмма, она же диаграмма сущность-связь) модель. При описании типов данных для атрибутов должны использоваться типы из СУБД PostgreSQL.
3. Реализовать даталогическую модель в PostgreSQL. При описании и реализации даталогической модели должны учитываться ограничения целостности, которые характерны для полученной предметной области.
4. Заполнить созданные таблицы тестовыми данными.
Для построения моделей можно использовать plantUML.

## Описание предметной области
Библиотека предоставляет читателям доступ к книгам и другим информационным ресурсам. Она обслуживает читателей, предоставляет возможность брать книги и организует различные мероприятия.

## Список сущностей и их классификация
1. Книги (стержневая сущность)
   - ID книги (INTEGER, PRIMARY KEY)
   - Название книги (VARCHAR)
   - Автор (VARCHAR)
   - Жанр (VARCHAR)
   - Дата издания (DATE)
   - Количество экземпляров (INTEGER)

2. Читатели (стержневая сущность)
   - ID читателя (INTEGER, PRIMARY KEY)
   - Имя (VARCHAR)
   - Фамилия (VARCHAR)
   - Дата рождения (DATE)
   - Контактная информация (VARCHAR)
   - Дата регистрации (DATE)

3. Учёт выданных книг (стержневая сущность)
   - ID учёта (INTEGER, PRIMARY KEY)
   - ID читателя (INTEGER, FOREIGN KEY)
   - ID книги (INTEGER, FOREIGN KEY)
   - Дата выдачи (DATE)
   - Дата возврата (DATE)
   - Статус книги (VARCHAR) (например, "выдана", "возвращена")

4. Мероприятия (стержневая сущность)
   - ID мероприятия (INTEGER, PRIMARY KEY)
   - Название мероприятия (VARCHAR)
   - Дата и время проведения (TIMESTAMP)
   - Описание мероприятия (TEXT)
   - Максимальное количество участников (INTEGER)
   - Статус (VARCHAR) (например, "грядущее", "действующее", "прошедшее")

5. Регистрация на мероприятия (ассоциационная сущность)
   - ID регистрации (INTEGER, PRIMARY KEY)
   - ID мероприятия (INTEGER, FOREIGN KEY)
   - ID читателя (INTEGER, FOREIGN KEY)
   - Дата регистрации (DATE)
   - Статус регистрации (VARCHAR) (например, "зарегистрирован", "отменён")

## Инфологическая модель (ER-диаграмма)

@startuml
entity "Книги" {
  + ID книги : INT <<PK>>
  + Название книги : VARCHAR
  + Автор : VARCHAR
  + Жанр : VARCHAR
  + Дата издания : DATE
  + Количество экземпляров : INT
}

entity "Читатели" {
  + ID читателя : INT <<PK>>
  + Имя : VARCHAR
  + Фамилия : VARCHAR
  + Дата рождения : DATE
  + Контактная информация : VARCHAR
  + Дата регистрации : DATE
}

entity "Учёт выданных книг" {
  + ID учёта : INT <<PK>>

  + ID читателя : INT <<FK>>
  + ID книги : INT <<FK>>
  + Дата выдачи : DATE
  + Дата возврата : DATE
  + Статус книги : VARCHAR
}

entity "Мероприятия" {
  + ID мероприятия : INT <<PK>>
  + Название мероприятия : VARCHAR
  + Дата и время проведения : TIMESTAMP
  + Описание мероприятия : TEXT
  + Максимальное количество участников : INT
  + Статус : VARCHAR
}

entity "Регистрация на мероприятия" {
  + ID регистрации : INT <<PK>>
  + ID мероприятия : INT <<FK>>
  + ID читателя : INT <<FK>>
  + Дата регистрации : DATE
  + Статус регистрации : VARCHAR
}

Книги o--o{ Учёт выданных книг : "имеет"
Читатели --o{ Учёт выданных книг : "берет"
Читатели }o--o{ Регистрация на мероприятия : "участвует"
Мероприятия --o{ Регистрация на мероприятия : "проведено"
@enduml

## Даталогическая модель
### Список таблиц
1. Книги

CREATE TABLE books (book_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL, author VARCHAR(255) NOT NULL, genre VARCHAR(100), publication_date DATE, copies_count INTEGER NOT NULL CHECK (copies_count >= 0));

2. Читатели

CREATE TABLE readers (reader_id SERIAL PRIMARY KEY, first_name VARCHAR(100) NOT NULL, last_name VARCHAR(100) NOT NULL, birth_date DATE, contact_info VARCHAR(255), registration_date DATE DEFAULT CURRENT_DATE);

3. Учёт выданных книг

CREATE TABLE issued_books (issue_id SERIAL PRIMARY KEY, reader_id INT REFERENCES readers(reader_id) ON DELETE CASCADE, book_id INT REFERENCES books(book_id) ON DELETE CASCADE, issue_date DATE, return_date DATE, status VARCHAR(100) CHECK (status IN ('выдан', 'возвращен')));

4. Мероприятия

CREATE TABLE events (event_id SERIAL PRIMARY KEY, title VARCHAR(255) NOT NULL, date_time TIMESTAMP NOT NULL, description TEXT, max_participants INTEGER CHECK (max_participants > 0), status VARCHAR(100) CHECK (status IN ('грядущее', 'действующее', 'прошедшее')));

5. Регистрация на мероприятия

CREATE TABLE event_registration (registration_id SERIAL PRIMARY KEY, event_id INT REFERENCES events(event_id) ON DELETE CASCADE, reader_id INT REFERENCES readers(reader_id) ON DELETE CASCADE, registration_date DATE, status VARCHAR(100) CHECK (status IN ('зарегистрирован', 'отменён')));

### Заполнение таблиц тестовыми данными

-- Вставка данных в таблицу books
INSERT INTO books (title, author, genre, publication_date, copies_count) VALUES ('Гарри Поттер', 'Дж.К. Роулинг', 'Фэнтези', '1997-06-26', 5), ('Война и мир', 'Лев Толстой', 'Исторический роман', '1869-01-01', 3);

-- Вставка данных в таблицу readers
INSERT INTO readers (first_name, last_name, birth_date, contact_info) VALUES ('Чуев', 'Никита', '2002-09-22', 'nikita@example.com'), ('Выдумкин', 'Илья', '1987-07-26', 'ilya@example.com');

-- Вставка данных в таблицу issued_books
INSERT INTO issued_books (reader_id, book_id, issue_date, return_date, status) VALUES (1, 1, '2023-01-01', NULL, 'выдан'), (2, 2, '2023-01-02', NULL, 'выдан');

-- Вставка данных в таблицу events
INSERT INTO events (title, date_time, description, max_participants, status) VALUES ('Книжная ярмарка', '2025-03-15 10:00:00', 'Ярмарка для любителей книг', 100, 'грядущее'), ('Литературный вечер', '2025-03-20 19:00:00', 'Вечер поэзии и прозы', 50, 'грядущее');

-- Вставка данных в таблицу event_registration
INSERT INTO event_registration (event_id, reader_id, registration_date, status) VALUES (1, 1, '2025-03-01', 'зарегистрирован'), (2, 2, '2025-03-05', 'зарегистрирован');

###  Запросы для проверки заполненных данных

#### SQL-запросы для проверки данных в таблицах:

-- Проверка данных в таблице books
SELECT * FROM books;

 book_id |    title     |    author     |       genre        | publication_date | copies_count 
---------+--------------+---------------+--------------------+------------------+--------------
       1 | Гарри Поттер | Дж.K. Роулинг | Фэнтези            | 1997-06-26       |            5
       2 | Война и мир  | Лев Толстой   | Исторический роман | 1869-01-01       |            3
(2 строки)

(END)

-- Проверка данных в таблице readers
SELECT * FROM readers;

 reader_id | first_name | last_name | birth_date |    contact_info    | registration_date 
-----------+------------+-----------+------------+--------------------+-------------------
         1 | Чуев       | Никита    | 2002-09-22 | nikita@example.com | 2025-03-14
         2 | Выдумкин   | Илья      | 1987-07-26 | ilya@example.com   | 2025-03-14
(2 строки)

(END)

-- Проверка данных в таблице issued_books 
SELECT * FROM issued_books ;
Вы подключены к базе данных "li" как пользователь "postgres".
li=# select * from  issued_books;
 issue_id | reader_id | book_id | issue_date | return_date | status 
----------+-----------+---------+------------+-------------+--------
        1 |         1 |       1 | 2023-01-01 |             | выдан
        2 |         2 |       2 | 2023-01-02 |             | выдан
(2 строки)

li=# 
nikita@debian:~$ sudo -u postgres psql


-- Проверка данных в таблице events
SELECT * FROM events;

 event_id |       title        |      date_time      |        description         | max_participants 
----------+--------------------+---------------------+----------------------------+------------------
        1 | Книжная ярмарка    | 2025-03-15 10:00:00 | Ярмарка для любителей книг |              100
        2 | Литературный вечер | 2025-03-20 19:00:00 | Вечер поэзии и прозы       |               50
(2 строки)

(END)

-- Проверка данных в таблице event_registration 

select * from event_registration ;

х "li" как пользователь "postgres".
li=# select * from  event_registration;
 registration_id | event_id | reader_id | registration_date |     status      
-----------------+----------+-----------+-------------------+-----------------
               1 |        1 |         1 | 2025-03-01        | зарегистрирован
               2 |        2 |         2 | 2025-03-05        | зарегистрирован
(2 строки)

li=# 
