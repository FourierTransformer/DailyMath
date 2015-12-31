-- adding MathJS into the database, so we can get some easy numerical compares!
INSERT INTO solution_methods (type) VALUES ('MathJS Compare');
UPDATE solution_methods SET type = 'String Compare' WHERE type = 'Numerical Compare';
