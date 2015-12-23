CREATE TABLE account_types (
	id SERIAL UNIQUE PRIMARY KEY NOT NULL,
	type text NOT NULL
);

CREATE TABLE categories (
	id SERIAL UNIQUE PRIMARY KEY NOT NULL,
	type text NOT NULL
);

CREATE TABLE solution_methods (
	id SERIAL UNIQUE PRIMARY KEY NOT NULL,
	type text NOT NULL
);

CREATE TABLE problems (
	id SERIAL UNIQUE PRIMARY KEY NOT NULL,
	date date,
	problem text NOT NULL,
	category_id integer REFERENCES categories(id),
	level integer NOT NULL,
	hint text,
	answer text,
	answer_desc text,
	name text,
	solution_id integer REFERENCES solution_methods(id),
	solution_json text,
	previous date,
	next date,
	correct_message text
);

CREATE INDEX on problems (date);

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;

CREATE TABLE users (
	id SERIAL UNIQUE PRIMARY KEY NOT NULL,
	displayname text NOT NULL,
	primary_email citext,
	all_email citext[],
	password text NOT NULL,
	old_passwords text[],
	account_id integer references account_types(id)
);

CREATE TABLE versions (
	id SERIAL UNIQUE PRIMARY KEY NOT NULL,
	major_release_number character varying(2) NOT NULL,
	minor_release_number character varying(2) NOT NULL,
	point_release_number character varying(4) NOT NULL,
	script_name character varying(40) NOT NULL,
	date_applied date DEFAULT now() NOT NULL
);

insert into versions values (1, '01', '00', '0000', 'install');



-- add in the admin account
insert into account_types values (1, 'admin');


-- add in solution methods (how a problem gets evaluated on "Submit")

COPY solution_methods (id, type) FROM stdin;
1	Numerical Compare
2	Duration Compare
3	Byte Compare
\.

SELECT pg_catalog.setval('solution_methods_id_seq', 3, true);

GRANT ALL PRIVILEGES ON TABLE categories TO "DailyMath";
GRANT ALL PRIVILEGES ON TABLE problems TO "DailyMath";
GRANT SELECT ON TABLE users TO "DailyMath";
GRANT SELECT ON TABLE versions TO "DailyMath";
GRANT SELECT ON TABLE solution_methods TO "DailyMath";
GRANT SELECT ON TABLE account_types TO "DailyMath";
GRANT USAGE, SELECT ON SEQUENCE problems_id_seq TO "DailyMath";
GRANT USAGE, SELECT ON SEQUENCE categories_id_seq TO "DailyMath";
-- ALTER USER "DailyMath" PASSWORD '[CREATE A SECURE PASSWORD]';
