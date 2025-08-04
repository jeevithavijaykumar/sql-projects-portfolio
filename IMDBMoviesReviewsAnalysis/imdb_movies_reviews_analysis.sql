------------------------------------------------------
-- IMDb Movies and Reviews Analysis
------------------------------------------------------

-- Create database
CREATE DATABASE imdb_analysis;


-- Drop existing tables if they exist
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS movies_staging;


CREATE TABLE movies_staging (
    idx INT,
    id VARCHAR(20),
    title TEXT,
    rating NUMERIC(3,2),
    genre TEXT,
    year INT
);

-- Create movies table
CREATE TABLE movies (
    id VARCHAR(20) PRIMARY KEY,
    title TEXT NOT NULL,
    rating NUMERIC(3,1),
    genre TEXT,
    year INT
);

-- Create reviews table
CREATE TABLE reviews (       
    imdb_id VARCHAR(20) NOT NULL,         
    review_title TEXT,
    review_rating NUMERIC(3,1),           
    review TEXT
);

-- -------------------------------------------------------------
-- Data Cleaning: Check for NULLs & duplicates in movies_staging
-- --------------------------------------------------------------

-- Count NULLs in critical columns
SELECT
    COUNT(*) FILTER (WHERE id IS NULL) AS null_ids,
    COUNT(*) FILTER (WHERE title IS NULL) AS null_titles,
    COUNT(*) FILTER (WHERE rating IS NULL) AS null_ratings,
    COUNT(*) FILTER (WHERE year IS NULL) AS null_years
FROM movies_staging;

-- Remove rows with NULL id or title
DELETE FROM movies_staging
WHERE id IS NULL OR title IS NULL;

-- Check duplicates by id
SELECT id, COUNT(*) AS cnt
FROM movies_staging
GROUP BY id
HAVING COUNT(*) > 1;

-- remove duplicate rows keeping the lowest idx for each id
DELETE FROM movies_staging a
USING movies_staging b
WHERE a.id = b.id
  AND a.idx > b.idx;

-- Insert cleaned unique movies into movies table
INSERT INTO movies (id, title, rating, genre, year)
SELECT DISTINCT id, title, rating, genre, year
FROM movies_staging
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------
-- Data Cleaning for reviews table
-- -----------------------------------

-- Check for NULLs in imdb_id (required)
SELECT COUNT(*) AS null_imdb_id
FROM reviews
WHERE imdb_id IS NULL;

-- Remove reviews with NULL imdb_id
DELETE FROM reviews
WHERE imdb_id IS NULL;

-- Check for invalid review_rating values (outside 0-10)
SELECT review_rating
FROM reviews
WHERE review_rating < 0 OR review_rating > 10;

--Remove invalid ratings (if any)
DELETE FROM reviews
WHERE review_rating < 0 OR review_rating > 10;

-- Add Primary Key to reviews table
ALTER TABLE reviews ADD COLUMN review_id SERIAL PRIMARY KEY;

-- Add foreign key constraint to reviews.imdb_id referencing movies.id
ALTER TABLE reviews
ADD CONSTRAINT fk_movie
FOREIGN KEY (imdb_id)
REFERENCES movies(id);

-- Create indexes for performance
CREATE INDEX idx_reviews_imdb_id ON reviews(imdb_id);
CREATE INDEX idx_movies_year ON movies(year);
CREATE INDEX idx_reviews_rating ON reviews(review_rating);


--------------------------------------------------------------------
-- Business Analysis and Insights
----------------------------------------------------------------------

-- Total number of movies
SELECT COUNT(*) AS total_movies FROM movies;

-- Total number of reviews
SELECT COUNT(*) AS total_reviews FROM reviews;

-- Average movie rating overall
SELECT ROUND(AVG(rating), 2) AS avg_movie_rating FROM movies;

-- Average user review rating
SELECT ROUND(AVG(review_rating), 2) AS avg_review_rating FROM reviews;


-- Top 5 most frequent genres
SELECT genre, COUNT(*) AS movie_count
FROM movies
WHERE genre IS NOT NULL
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 5;

-- Average movie rating by genre
SELECT genre, ROUND(AVG(rating), 1) AS avg_rating
FROM movies
GROUP BY genre
ORDER BY avg_rating DESC;


-- Number of movies released per year (last 10 years)
SELECT year, COUNT(*) AS movie_count
FROM movies
WHERE year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
GROUP BY year
ORDER BY year;


-- Average rating by year
SELECT year, ROUND(AVG(rating), 1) AS avg_rating
FROM movies
WHERE year IS NOT NULL
GROUP BY year
ORDER BY year;


-- Top 10 highest-rated movies
SELECT title, rating
FROM movies
WHERE rating IS NOT NULL
ORDER BY rating DESC
LIMIT 10;


-- Bottom 10 lowest-rated movies
SELECT title, rating
FROM movies
WHERE rating IS NOT NULL
ORDER BY rating ASC
LIMIT 10;

-- Top 10 most reviewed movies
SELECT m.title, COUNT(r.review_id) AS total_reviews
FROM movies m
JOIN reviews r ON m.id = r.imdb_id
GROUP BY m.title
ORDER BY total_reviews DESC
LIMIT 10;

-- Movies with highest average user review rating (min 5 reviews)
SELECT m.title, 
	 ROUND(AVG(r.review_rating), 1) AS avg_user_rating, 
	 COUNT(*) AS review_count
FROM reviews r
JOIN movies m 
	ON r.imdb_id = m.id
GROUP BY m.title
HAVING COUNT(*) >= 5
ORDER BY avg_user_rating DESC
LIMIT 10;

-- Rating distribution from user reviews
SELECT
  CASE
    WHEN review_rating >= 8 THEN 'Positive'
    WHEN review_rating >= 5 THEN 'Neutral'
    ELSE 'Negative'
  END AS sentiment,
  COUNT(*) AS review_count
FROM reviews
GROUP BY sentiment;


-- Average rating by genre over years (for recent years)
SELECT year, genre, ROUND(AVG(rating), 2) AS avg_rating
FROM movies
WHERE year >= 2015
GROUP BY year, genre
ORDER BY genre, year;




------------------------------------------------------
-- End of IMDb Movies and Reviews Analysis 
------------------------------------------------------