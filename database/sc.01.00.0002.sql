-- we need some timestamps with our dates!
alter table versions add column date_applied2 timestamp DEFAULT now() NOT NULL;
update versions set date_applied2 = date_applied;
alter table versions drop column date_applied;
alter table versions rename date_applied2 to date_applied;
