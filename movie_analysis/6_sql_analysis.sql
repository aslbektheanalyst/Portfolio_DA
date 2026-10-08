#Does a higher IMDb rating actually translate into more audience interest?

WITH rating_groups AS (
    SELECT
        CASE
            WHEN imdb_rating < 7.0 THEN 'Below 7.0'
            WHEN imdb_rating < 8.0 THEN '7.0–7.9'
            WHEN imdb_rating < 9.0 THEN '8.0–8.9'
            ELSE '9.0+'
        END AS rating_group,
        no_of_votes,
        gross
    FROM movies
    WHERE imdb_rating IS NOT NULL
      AND no_of_votes IS NOT NULL
)
SELECT
    rating_group,
    COUNT(*) AS movie_count,
    ROUND(AVG(no_of_votes)) AS avg_votes,
    TO_CHAR(AVG(gross), '$FM999,999,999') AS avg_gross
FROM rating_groups
GROUP BY rating_group
ORDER BY MIN(
    CASE
        WHEN rating_group = 'Below 7.0' THEN 1
        WHEN rating_group = '7.0–7.9' THEN 2
        WHEN rating_group = '8.0–8.9' THEN 3
        ELSE 4
    END
);



#2 Which genres combine strong ratings with commercial success?

WITH genre_movies AS (
    SELECT
        TRIM(genre) AS genre,
        imdb_rating,
        gross,
        no_of_votes
    FROM movies
    WHERE genre IS NOT NULL
      AND imdb_rating IS NOT NULL
      AND gross IS NOT NULL
      AND no_of_votes IS NOT NULL
),
genre_performance AS (
    SELECT
        genre,
        COUNT(*) AS movie_count,
        ROUND(AVG(imdb_rating), 2) AS avg_rating,
        ROUND(AVG(no_of_votes)) AS avg_votes,
        AVG(gross) AS avg_gross
    FROM genre_movies
    GROUP BY genre
)
SELECT
    genre,
    movie_count,
    avg_rating,
    avg_votes,
    TO_CHAR(avg_gross, '$FM999,999,999') AS avg_gross
FROM genre_performance
WHERE movie_count >= 10
ORDER BY avg_gross DESC;


#3 Does a longer movie actually earn more?


WITH runtime_groups AS (
    SELECT
        CASE
            WHEN CAST(REPLACE(runtime, ' min', '') AS INTEGER) < 90
                THEN 'Under 90 min'
            WHEN CAST(REPLACE(runtime, ' min', '') AS INTEGER) < 120
                THEN '90–119 min'
            WHEN CAST(REPLACE(runtime, ' min', '') AS INTEGER) < 150
                THEN '120–149 min'
            ELSE '150+ min'
        END AS runtime_group,
        imdb_rating,
        gross,
        no_of_votes
    FROM movies
    WHERE runtime IS NOT NULL
      AND imdb_rating IS NOT NULL
      AND gross IS NOT NULL
      AND no_of_votes IS NOT NULL
)
SELECT
    runtime_group,
    COUNT(*) AS movie_count,
    ROUND(AVG(imdb_rating), 2) AS avg_rating,
    ROUND(AVG(no_of_votes)) AS avg_votes,
    TO_CHAR(AVG(gross), '$FM999,999,999') AS avg_gross
FROM runtime_groups
GROUP BY runtime_group
ORDER BY
    CASE
        WHEN runtime_group = 'Under 90 min' THEN 1
        WHEN runtime_group = '90–119 min' THEN 2
        WHEN runtime_group = '120–149 min' THEN 3
        ELSE 4
    END;


#4. Which directors consistently produce both acclaimed and commercially successful movies?

WITH director_stats AS (
    SELECT
        director,
        COUNT(*) AS movie_count,
        ROUND(AVG(imdb_rating), 2) AS avg_rating,
        ROUND(AVG(no_of_votes)) AS avg_votes,
        AVG(gross) AS avg_gross
    FROM movies
    WHERE director IS NOT NULL
      AND imdb_rating IS NOT NULL
      AND gross IS NOT NULL
      AND no_of_votes IS NOT NULL
    GROUP BY director
)
SELECT
    director,
    movie_count,
    avg_rating,
    avg_votes,
    TO_CHAR(avg_gross, '$FM999,999,999') AS avg_gross
FROM director_stats
WHERE movie_count >= 3
ORDER BY avg_rating DESC, avg_gross DESC
LIMIT 20;



#5 Are the highest-grossing movies actually the highest-rated?

WITH blockbuster_movies AS (
    SELECT
        series_title,
        director,
        genre,
        imdb_rating,
        gross,
        no_of_votes,
        NTILE(5) OVER (ORDER BY gross DESC) AS gross_group
    FROM movies
    WHERE gross IS NOT NULL
      AND imdb_rating IS NOT NULL
      AND no_of_votes IS NOT NULL
),
ranked_blockbusters AS (
    SELECT
        series_title,
        director,
        genre,
        imdb_rating,
        gross,
        no_of_votes,
        CASE
            WHEN ROW_NUMBER() OVER (ORDER BY imdb_rating DESC) <= 5
                THEN 'Top 5 Rated Blockbusters'
            WHEN ROW_NUMBER() OVER (ORDER BY imdb_rating ASC) <= 5
                THEN 'Bottom 5 Rated Blockbusters'
        END AS rating_group
    FROM blockbuster_movies
    WHERE gross_group = 1
)
SELECT
    rating_group,
    series_title,
    director,
    genre,
    imdb_rating,
    TO_CHAR(gross, '$FM999,999,999') AS gross,
    no_of_votes
FROM ranked_blockbusters
WHERE rating_group IS NOT NULL
ORDER BY
    CASE
        WHEN rating_group = 'Top 5 Rated Blockbusters' THEN 1
        ELSE 2
    END,
    imdb_rating DESC;
