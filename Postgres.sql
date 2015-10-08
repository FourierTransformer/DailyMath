CREATE TABLE CATEGORY(
   ID SERIAL UNIQUE PRIMARY KEY NOT NULL,
   NAME TEXT NOT NULL,
   LEVEL INT NOT NULL
);

CREATE TABLE USERS(
    ID SERIAL UNIQUE PRIMARY KEY NOT NULL,
    DISPLAYNAME TEXT NOT NULL,
    PRIMARY_EMAIL TEXT,
    ALL_EMAIL TEXT[],
    PASSWORD TEXT,
    OLD_PASSWORDS TEXT[],
    APPROVER BOOL DEFAULT FALSE
);

CREATE TABLE PROBLEMS(
   ID SERIAL UNIQUE PRIMARY KEY NOT NULL,
   DATE DATE,
   PROBLEM TEXT NOT NULL,
   CATEGORY_ID INT REFERENCES CATEGORY (ID),
   HINT TEXT,
   ANSWER TEXT,
   ANSWER_DESC TEXT,
   APPROVED BOOL DEFAULT FALSE
);

CREATE TABLE APPROVED_QUESTIONS(
    USER_ID INT REFERENCES USERS (ID) NOT NULL,
    PROBLEM_ID INT REFERENCES PROBLEMS (ID) NOT NULL,
    APPROVED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(USER_ID, PROBLEM_ID)
);

CREATE TABLE CORRECT_ANSWERS(
    USER_ID INT REFERENCES USERS (ID) NOT NULL,
    PROBLEM_ID INT REFERENCES PROBLEMS (ID) NOT NULL,
    ANSWERED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(USER_ID, PROBLEM_ID)
);