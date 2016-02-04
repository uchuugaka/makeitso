BEGIN TRANSACTION;

CREATE TABLE keys (
    nextID INTEGER PRIMARY KEY NOT NULL,
    name TEXT
);
INSERT INTO keys (nextID, name) VALUES (0, 'global');

CREATE TABLE team (
    objectID INTEGER PRIMARY KEY NOT NULL,
    name TEXT
);

CREATE TABLE team_player (
    rowID INTEGER PRIMARY KEY NOT NULL,
    ownerID INTEGER NOT NULL,
    memberID INTEGER NOT NULL,
    FOREIGN KEY(ownerID) REFERENCES team(objectID),
    FOREIGN KEY(memberID) REFERENCES player(objectID)
);

CREATE TABLE player (
    objectID INTEGER PRIMARY KEY NOT NULL,
    firstName TEXT,
    lastName TEXT,
    team INTEGER
);


END TRANSACTION;
