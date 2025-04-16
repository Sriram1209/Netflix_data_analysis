-- Adding show_id as primary key
ALTER TABLE netflix 
ADD CONSTRAINT PK PRIMARY KEY(show_id);

-- Converting date_added column from varchar to date type
ALTER TABLE netflix
ALTER COLUMN date_added TYPE DATE USING date_added::DATE;

-- Creating view with unnested
DROP VIEW IF EXISTS TEMP
CREATE VIEW TEMP AS
SELECT *,
UNNEST (STRING_TO_ARRAY(country, ',')) AS Country_unnested,
UNNEST (STRING_TO_ARRAY(listed_in, ',')) AS Genre,
UNNEST (STRING_TO_ARRAY(casts, ',')) AS Actor
FROM netflix;

--Q1: Count the number of Movies vs TV Shows

SELECT type, COUNT(*) FROM netflix
GROUP BY type;

--Q2: Find the most common rating for movies and TV shows

WITH RatingCounts AS (
    SELECT type, rating, COUNT(*) AS rating_count FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT type, rating,rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank
    FROM RatingCounts
)
SELECT type, rating AS most_frequent_rating FROM RankedRatings
WHERE rank = 1;

--Q3: List all movies released in a specific year (e.g., 2020)

SELECT title FROM netflix
WHERE release_year = 2020;

--Q4: Find the top 5 countries with the most content on Netflix

SELECT * FROM 
(
	SELECT 
		UNNEST(STRING_TO_ARRAY(country, ',')) as country,
		COUNT(*) as total_content
	FROM netflix
	GROUP BY 1
)
WHERE country IS NOT NULL
ORDER BY total_content DESC
LIMIT 5;

--Q5: Identify the Longest Movie

SELECT * FROM netflix
WHERE type = 'Movie'
ORDER BY SPLIT_PART(duration, ' ', 1)::INT DESC;

--Q6: Find Content Added in the Last 5 Years

SELECT * FROM netflix
WHERE EXTRACT(YEAR FROM date_added) BETWEEN 2016 AND 2021
ORDER BY date_added DESC;

--Q7: Find All Movies/TV Shows by Director 'Rajiv Chilaka'

SELECT * FROM (
	SELECT *,
		UNNEST(STRING_TO_ARRAY(director, ',')) AS director_name FROM netflix
) WHERE director_name = 'Rajiv Chilaka';

--Q8: List All TV Shows with More Than 5 Seasons

SELECT * FROM netflix
WHERE type = 'TV Show' AND SPLIT_PART(duration, ' ', 1)::INT > 5;

--Q9: Count the Number of Content Items in Each Genre

SELECT Genre, COUNT(Genre) AS total_content FROM (
	SELECT *, 
		UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS Genre FROM netflix
) 
GROUP BY Genre
ORDER BY COUNT(Genre) DESC;

--Q10: Find each year and the average numbers of content release in India on netflix.

SELECT country_altered AS country,
EXTRACT(YEAR FROM date_added) AS year,
ROUND(COUNT(show_id)::NUMERIC / (SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100, 2) AS Average 
FROM (
	SELECT *,
		UNNEST(STRING_TO_ARRAY(country, ',')) AS country_altered
	FROM netflix
)
WHERE country_altered = 'India'
GROUP BY country_altered, EXTRACT(YEAR FROM date_added);

--Q11: List All Movies that are Documentaries

SELECT * FROM TEMP
WHERE Genre = 'Documentaries' AND type = 'Movie';

--Q12: Find All Content Without a Director

SELECT * FROM netflix
WHERE director IS NULL;

--Q13: Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

SELECT * FROM netflix
WHERE casts ILIKE '%Salman Khan%' 
AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;

--Q14: Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

SELECT Actor, COUNT(Actor) AS NO_OF_MOVIES FROM TEMP
WHERE Country LIKE '%India%'
GROUP BY Actor
ORDER BY COUNT(Actor) DESC
LIMIT 10;

--Q15: Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

WITH CTE AS (
	SELECT (
		CASE
			WHEN description ILIKE '%KILL%' OR description ILIKE '%VIOLENCE%' THEN 'A'
			ELSE 'U/A'
		END
	) AS category, 
	COUNT(*) AS NO_OF_ITEMS FROM netflix
	GROUP BY 1
)
SELECT * FROM CTE;

