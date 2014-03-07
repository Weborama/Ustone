CREATE TABLE issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description varchar(100) not null,
    root_cause text,
    uptime_score int,
    created_at int
);
