-- drop the old pointer columns from problems (i'm using lead and lag to get this)
-- also there was never any data in here.
ALTER TABLE problems DROP COLUMN previous;
ALTER TABLE problems DROP COLUMN next;

-- this isn't being used.
ALTER TABLE problems DROP COLUMN solution_json;
