DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

PRAGMA foreign_keys = ON;


CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    author_id INTEGER NOT NULL,

    FOREIGN KEY (author_id)
        REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    author_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (author_id)
        REFERENCES users(id),
    FOREIGN KEY (question_id)
        REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_id INTEGER,
    body TEXT NOT NULL,

    FOREIGN KEY (question_id)
        REFERENCES questions(id),
    FOREIGN KEY (parent_id)
        REFERENCES replies(id),
    FOREIGN KEY (user_id)
        REFERENCES users(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    likes INTEGER NOT NULL,

    FOREIGN KEY (user_id)
        REFERENCES users(id),
    FOREIGN KEY (question_id)
        REFERENCES questions(id)
);



INSERT INTO 
    users (fname, lname)
VALUES 
    ('John', 'Doe'),
    ('Jane', 'The Virgin');


INSERT INTO 
    questions (title, body, author_id)
VALUES
    ('How to program?',
    'Hey Jane, please teach me how to program!! Thanks :(',
    (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe' ));


INSERT INTO 
    question_follows (author_id, question_id)
VALUES
    (
        (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'),
        (SELECT id FROM questions WHERE title = 'How to program?')
    );

INSERT INTO 
    replies (question_id, user_id, parent_id, body)
VALUES
    (
        (SELECT id FROM questions WHERE title = 'How to program?'),
        (SELECT id FROM users WHERE fname = 'Jane' AND lname = 'The Virgin'),
        (NULL),
        ("Programming is about the mind, the body, and the soul...")       
    ),

    (
        (SELECT id FROM questions WHERE title = 'How to program?'),
        (SELECT id FROM users WHERE fname = 'Jane' AND lname = 'The Virgin'),
        (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'),
        ("Thanks Jane!!!! :)")
    );

INSERT INTO 
    question_likes (user_id, question_id, likes)
VALUES  
    (
        (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe'),
        (SELECT id FROM questions WHERE title = 'How to program?'),
        (4)
    );

    