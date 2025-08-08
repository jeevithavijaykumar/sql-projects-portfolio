---------------------------------------------------------
-- Video Game Sales - FULL SQL PIPELINE
---------------------------------------------------------

CREATE DATABASE video_game_sales;

-- Drop table if exists
DROP TABLE IF EXISTS staging_vgsales;
DROP TABLE IF EXISTS platforms;
DROP TABLE IF EXISTS publishers ;
DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS sales;

-- Staging table for raw data
CREATE TABLE staging_vgsales (
    Name VARCHAR,
    Platform VARCHAR,
    Year_of_Release VARCHAR,
    Genre VARCHAR,
    Publisher VARCHAR,
    NA_Sales NUMERIC,
    EU_Sales NUMERIC,
    JP_Sales NUMERIC,
    Other_Sales NUMERIC,
    Global_Sales NUMERIC,
    Critic_Score VARCHAR,
    Critic_Count INTEGER,
    User_Score VARCHAR,
    User_Count INTEGER,
    Developer VARCHAR,           
    Rating VARCHAR               
);


---------------------------------------------------------------------
-- Data Cleaning
---------------------------------------------------------------------

-- Replace 'tbd' with NULL in User_Score
UPDATE staging_vgsales
SET User_Score = NULL
WHERE LOWER(User_Score) = 'tbd';

-- Invalid years
UPDATE staging_vgsales
SET Year_of_Release = NULL
WHERE Year_of_Release !~ '^\d{4}$';

-- Invalid critic scores
UPDATE staging_vgsales
SET Critic_Score = NULL
WHERE Critic_Score !~ '^\d+$';

-- Remove whitespace 
UPDATE staging_vgsales
SET Name = TRIM(Name),
    Platform = TRIM(Platform),
    Publisher = TRIM(Publisher),
    Genre = TRIM(Genre);

----------------------------------------------------------------------
-- Normalized Tables
----------------------------------------------------------------------

CREATE TABLE platforms (
    platform_id SERIAL PRIMARY KEY,
    platform_name VARCHAR UNIQUE NOT NULL
);

CREATE TABLE publishers (
    publisher_id SERIAL PRIMARY KEY,
    publisher_name VARCHAR UNIQUE NOT NULL
);

CREATE TABLE games (
    game_id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    platform_id INT REFERENCES platforms(platform_id),
    year_of_release INT,
    genre VARCHAR,
    publisher_id INT REFERENCES publishers(publisher_id),
    critic_score INT,
    critic_count INT,
    user_score NUMERIC(3,1),
    user_count INT
);

CREATE TABLE sales (
    sale_id SERIAL PRIMARY KEY,
    game_id INT REFERENCES games(game_id),
    na_sales NUMERIC(6,2),
    eu_sales NUMERIC(6,2),
    jp_sales NUMERIC(6,2),
    other_sales NUMERIC(6,2),
    global_sales NUMERIC(6,2)
);

-- Insert cleaned data into platforms table
INSERT INTO platforms (platform_name)
SELECT DISTINCT Platform
FROM staging_vgsales
WHERE Platform IS NOT NULL AND Platform <> ''
AND Platform NOT IN (
      SELECT platform_name FROM platforms) ;

-- Insert cleaned data into publishers table
INSERT INTO publishers (publisher_name)
SELECT DISTINCT Publisher
FROM staging_vgsales
WHERE Publisher IS NOT NULL AND Publisher <> ''
AND Publisher NOT IN (
      SELECT publisher_name FROM publishers);

-- Insert cleaned data into games table
INSERT INTO games (name, platform_id, year_of_release, genre, publisher_id,
                   critic_score, critic_count, user_score, user_count)
SELECT
    sv.name,
    p.platform_id,
    CASE 
      WHEN Year_of_Release ~ '^\d{4}$' THEN Year_of_Release::INT
      ELSE NULL
    END,
    sv.Genre,
    pub.publisher_id,
    CASE WHEN Critic_Score ~ '^\d+$' THEN Critic_Score::INT ELSE NULL END,
    sv.Critic_Count,
    CASE 
      WHEN User_Score ~ '^\d+(\.\d+)?$' THEN User_Score::NUMERIC
      ELSE NULL
    END,
    sv.User_Count
FROM staging_vgsales sv
JOIN platforms p ON sv.Platform = p.platform_name
JOIN publishers pub ON sv.Publisher = pub.publisher_name
WHERE sv.Name IS NOT NULL;

-- Insert cleaned data into sales table
INSERT INTO sales (game_id, na_sales, eu_sales, jp_sales, other_sales, global_sales)
SELECT
    g.game_id,
    sv.NA_Sales,
    sv.EU_Sales,
    sv.JP_Sales,
    sv.Other_Sales,
    sv.Global_Sales
FROM staging_vgsales sv
JOIN platforms p ON sv.Platform = p.platform_name
JOIN publishers pub ON sv.Publisher = pub.publisher_name
JOIN games g 
    ON sv.Name = g.name
   AND g.platform_id = p.platform_id
   AND g.publisher_id = pub.publisher_id;


----------------------------------------------------------------
-- Business Insights
----------------------------------------------------------------

-- Top 10 games by global sales
SELECT g.name, p.platform_name, pub.publisher_name, s.global_sales
FROM sales s
JOIN games g ON s.game_id = g.game_id
JOIN platforms p ON g.platform_id = p.platform_id
JOIN publishers pub ON g.publisher_id = pub.publisher_id
ORDER BY s.global_sales DESC
LIMIT 10;

-- Average critic score by genre
SELECT genre, AVG(critic_score) AS avg_critic_score
FROM games
WHERE critic_score IS NOT NULL
GROUP BY genre
ORDER BY avg_critic_score DESC;

-- Top publishers by North America sales
SELECT pub.publisher_name, SUM(s.na_sales) AS total_na_sales
FROM sales s
JOIN games g ON s.game_id = g.game_id
JOIN publishers pub ON g.publisher_id = pub.publisher_id
GROUP BY pub.publisher_name
ORDER BY total_na_sales DESC
LIMIT 5;

-- Yearly game release count
SELECT year_of_release, COUNT(*) AS games_released
FROM games
WHERE year_of_release IS NOT NULL
GROUP BY year_of_release
ORDER BY year_of_release;

-- Top genre in each region
SELECT genre,
       SUM(na_sales) AS total_na,
       SUM(eu_sales) AS total_eu,
       SUM(jp_sales) AS total_jp
FROM sales s
JOIN games g ON s.game_id = g.game_id
GROUP BY genre
ORDER BY total_na DESC;

-- Publishers with highest average critic score (min 5 games)
SELECT pub.publisher_name, ROUND(AVG(critic_score),2) AS avg_score
FROM games g
JOIN publishers pub ON g.publisher_id = pub.publisher_id
WHERE critic_score IS NOT NULL
GROUP BY pub.publisher_name
HAVING COUNT(*) >= 5
ORDER BY avg_score DESC;




----------------------------------------------------------------------
-- End of Video Game Sales script
----------------------------------------------------------------------