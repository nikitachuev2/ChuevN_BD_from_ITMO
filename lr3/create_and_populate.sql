CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL UNIQUE,
    author VARCHAR(255) NOT NULL,
    genre VARCHAR(100) NOT NULL,
    publication_date DATE NOT NULL,
    copies_count INTEGER NOT NULL CHECK (copies_count >= 0) DEFAULT 1
);

CREATE TABLE readers (
    reader_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL CHECK (birth_date < CURRENT_DATE),
    contact_info VARCHAR(255) UNIQUE NOT NULL,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE,
    book_id INTEGER NOT NULL REFERENCES books(book_id) ON DELETE CASCADE,
    loan_date DATE NOT NULL DEFAULT CURRENT_DATE,
    return_date DATE,
    status VARCHAR(50) CHECK (status IN ('выдана', 'возвращена')) NOT NULL
);

CREATE TABLE events (
    event_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    event_datetime TIMESTAMP NOT NULL,
    description TEXT,
    max_participants INTEGER CHECK (max_participants >= 0) NOT NULL,
    status VARCHAR(50) CHECK (status IN ('грядущее', 'действующее', 'прошедшее')) NOT NULL
);

CREATE TABLE event_registrations (
    registration_id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
    reader_id INTEGER NOT NULL REFERENCES readers(reader_id) ON DELETE CASCADE,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE,
    registration_status VARCHAR(50) CHECK (registration_status IN ('зарегистрирован', 'отменён')) NOT NULL
);

-- Заполнение таблицы "Книги"
INSERT INTO books (title, author, genre, publication_date, copies_count) VALUES
('1984', 'George Orwell', 'Dystopian', '1949-06-08', 5),
('To Kill a Mockingbird', 'Harper Lee', 'Fiction', '1960-07-11', 3),
('The Great Gatsby', 'F. Scott Fitzgerald', 'Classic', '1925-04-10', 2),
('Moby Dick', 'Herman Melville', 'Adventure', '1851-10-18', 1);

-- Заполнение таблицы "Читатели"
INSERT INTO readers (first_name, last_name, birth_date, contact_info, registration_date) VALUES
('Алексей', 'Иванов', '1990-05-12', 'ivanov@example.com', '2023-01-15'),
('Мария', 'Петрова', '1985-09-23', 'petrova@example.com', '2023-02-20'),
('Иван', 'Сидоров', '2000-11-30', 'sidorov@example.com', '2023-03-10'),
('Наталья', 'Смирнова', '1995-06-05', 'smirnova@example.com', '2023-04-17');

-- Заполнение таблицы "Учёт выданных книг"
INSERT INTO book_loans (reader_id, book_id, loan_date, return_date, status) VALUES
(1, 1, '2023-03-01', NULL, 'выдана'),
(2, 2, '2023-03-05', '2023-03-15', 'возвращена'),
(1, 3, '2023-04-01', NULL, 'выдана'),
(3, 1, '2023-04-10', NULL, 'выдана');

-- Заполнение таблицы "Мероприятия"
INSERT INTO events (title, event_datetime, description, max_participants, status) VALUES
('Литературный вечер', '2023-05-10 18:00:00', 'Обсуждение книг и авторов.', 50, 'грядущее'),
('Книжная выставка', '2023-06-15 10:00:00', 'Выставка новых книг.', 100, 'грядущее');

-- Заполнение таблицы "Регистрация на мероприятия"
INSERT INTO event_registrations (event_id, reader_id, registration_date, registration_status) VALUES
(1, 1, CURRENT_DATE, 'зарегистрирован'),
(1, 2, CURRENT_DATE, 'зарегистрирован'),
(2, 3, CURRENT_DATE, 'зарегистрирован');

