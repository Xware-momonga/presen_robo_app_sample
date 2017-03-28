CREATE TABLE IF NOT EXISTS presen(
    id TEXT NOT NULL,
    title TEXT NOT NULL,
    createdtimestamp TIMESTAMP DEFAULT (DATETIME('now','localtime')),
    PRIMARY KEY(id)
);

CREATE TABLE IF NOT EXISTS page(
    id TEXT NOT NULL,
    saytext TEXT,
    pageno INTEGER NOT NULL,
    filename TEXT NOT NULL,
    presenid TEXT NOT NULL,
    PRIMARY KEY(id)
);
