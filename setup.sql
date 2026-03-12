--this code creates a new database called survior_fantasy 
--it runs in Docker SQL Server container mountained in my local folder 
--Docker is mapped to host port 1434 → container 1433

CREATE DATABASE survivor_fantasy;
GO
USE survivor_fantasy;
GO
SELECT DB_NAME() AS current_database;

--creating four tables to match existing CSV datafiles
-- note: prior to loading castaways dataset was altered to remove NA's and the last two columns ack_quote and ack_score
CREATE TABLE dbo.castaways (
    version VARCHAR(20),
    version_season VARCHAR(50),
    season INT NOT NULL,
    full_name VARCHAR(100),
    castaway_id VARCHAR(50) NOT NULL,
    castaway VARCHAR(100),
    age INT,
    city VARCHAR(200),
    state VARCHAR(50),
    episode INT,
    day INT,
    [order] INT NULL,
    result VARCHAR(50) NULL,
    jury_status VARCHAR(50) NULL,
    place INT,
    original_tribe VARCHAR(50) NULL,
    jury VARCHAR(20),
    finalist VARCHAR(20),
    winner VARCHAR(20),
    acknowledge VARCHAR(20),
    ack_look VARCHAR(20),
    ack_speak VARCHAR(20),
    ack_gesture VARCHAR(20),
    ack_smile VARCHAR(20),

    CONSTRAINT PK_castaways 
        PRIMARY KEY (castaway_id)
);
--DROP TABLE dbo.castaways 

CREATE TABLE dbo.advantage_details (
    version VARCHAR(20),
    version_season VARCHAR(50),
    season INT NOT NULL,
    advantage_id INT NOT NULL,
    advantage_type VARCHAR(50),
    clue_details VARCHAR(100),
    location_found VARCHAR(500),
    conditions VARCHAR(500),

    CONSTRAINT PK_advantage_details 
        PRIMARY KEY (version_season, advantage_id)
);
--DROP TABLE dbo.advantage_details

CREATE TABLE dbo.advantage_movement (
    version VARCHAR(20),
    version_season VARCHAR(50),
    season INT NOT NULL,
    castaway VARCHAR(100),
    castaway_id VARCHAR(50),
    advantage_id INT NOT NULL,
    sequence_id INT NOT NULL,
    day INT,
    episode INT,
    event VARCHAR(100), 
    played_for VARCHAR(50),
    played_for_id VARCHAR(50),
    success VARCHAR(50),
    votes_nullified INT,
    sog_id INT,

    CONSTRAINT PK_advantage_movement
        PRIMARY KEY (version_season, advantage_id, sequence_id)
);
DROP TABLE dbo.advantage_movement


-- List all user tables in the current database
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

--change column type for catsaway_id to character e.g. US0554
-- first need to drop PK constraint then bring it back
ALTER TABLE dbo.castaways
DROP CONSTRAINT PK_castaways;

ALTER TABLE castaways
ALTER COLUMN castaway_id VARCHAR(50) NOT NULL;

ALTER TABLE castaways
ALTER COLUMN version_season VARCHAR(50) NOT NULL;

ALTER TABLE dbo.castaways
ADD CONSTRAINT PK_castaways PRIMARY KEY (version_season, castaway_id);


--bulk imprt csv files
--getting conversion error - mismatching column types
-- clean up .csv files to remove "NA" --> empty cells 

-- create another csv with my own fantasy pool data - make a table for it
CREATE TABLE dbo.fantasy (
    version VARCHAR(20),
    version_season VARCHAR(50),
    season INT NOT NULL,
    episode INT NOT NULL,
    fantasy_player VARCHAR(50),
    fantasy_point_earned INT,
    fanatsy_points INT,

    CONSTRAINT PK_fantasy
        PRIMARY KEY (episode, fantasy_player)
);

--
ALTER TABLE dbo.fantasy
DROP CONSTRAINT PK_fantasy;

ALTER TABLE dbo.fantasy
ADD CONSTRAINT PK_fantasy PRIMARY KEY (season, episode, fantasy_player);

-- List all user tables in the current database, new table should now be there
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

---------------------------Fantasy table load
-- trying to import now
BULK INSERT dbo.fantasy
FROM '/csv/survivor_fantasy_master.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
--validating
SELECT TOP 10 * FROM dbo.fantasy;
SELECT DISTINCT fantasy_player FROM dbo.fantasy;

--------------------------- Castaways table load
--checking over data types
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'castaways';

BULK INSERT dbo.castaways
FROM '/csv/castaways.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"', -- important for city column that has some commas 
    TABLOCK
);

--getting errors with boolean columns e.g. jury in castaways
-- errors like "Bulk load data conversion error (type mismatch or invalid character for the specified codepage) for row 7, column 17 (jury).
-- IMPORTANT: backtracking to drop castwasy table and re-building it with VARCHAR for all BIT colunmns
--            then changing them to BIT safely if desired
--validating
SELECT TOP 10 * FROM dbo.castaways;
--validating rows with commas within single columns (e.g. city in UK02)
SELECT * FROM dbo.castaways
WHERE version_season='UK02'

-- adding boolean column for those that had to be loaded as VARCHAR initially
ALTER TABLE dbo.castaways
ADD jury_clean BIT;

UPDATE dbo.castaways
SET jury_clean =
    CASE
        WHEN jury IN ('TRUE','True','true','1') THEN 1
        WHEN jury IN ('FALSE','False','false','0') THEN 0
        ELSE NULL
    END;

--validatng new jury-clean boolean column
SELECT * FROM dbo.castaways
WHERE version_season='US49'

--repeating for (some) others 
ALTER TABLE dbo.castaways
ADD finalist_clean BIT,
    winner_clean BIT;

UPDATE dbo.castaways
SET finalist_clean =
    CASE
        WHEN finalist IN ('TRUE','True','true','1') THEN 1
        WHEN finalist IN ('FALSE','False','false','0') THEN 0
        ELSE NULL
    END,
     winner_clean =
    CASE
        WHEN winner IN ('TRUE','True','true','1') THEN 1
        WHEN winner IN ('FALSE','False','false','0') THEN 0
        ELSE NULL
    END; 

--validatng new finalist-clean and winner-clean boolean columns
SELECT * FROM dbo.castaways
WHERE version_season='US49'

---------------------------Advantage_details table load
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'advantage_details';

BULK INSERT dbo.advantage_details
FROM '/csv/advantage_details.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIELDQUOTE = '"', -- important for character columns that have commas 
    TABLOCK
);
--validating
SELECT TOP 10 * FROM dbo.advantage_details;

--------------------------- Advantage_movement table load
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'advantage_movement';

BULK INSERT dbo.advantage_movement
FROM '/csv/advantage_movement.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    FIELDQUOTE = '"', -- important for character columns that have commas 
    TABLOCK
);
--validating
SELECT TOP 10 * FROM dbo.advantage_movement;
--validating rows with commas within single columns (e.g. castaway in US47)
SELECT * FROM dbo.advantage_movement
WHERE version_season='US47'

--confirming all my tables exist
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;