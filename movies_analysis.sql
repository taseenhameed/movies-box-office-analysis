Create database moviesanalysis
USE moviesanalysis;
select * from movies_dataset 
-- 1. Overall dataset summary
SELECT
    COUNT(*) AS total_movies,
    ROUND(AVG(imdb_rating), 2) AS avg_rating,
    ROUND(AVG(budget_million_usd), 1) AS avg_budget,
    ROUND(AVG(revenue_million_usd), 1) AS avg_revenue
FROM movies_dataset;
-- FINDING: 800 movies in the dataset, averaging a 6.53 IMDb rating, $47.5M budget,
-- and $177.2M revenue. This is the baseline scale for the whole dataset.

-- 2. Top 10 movies by revenue
SELECT TOP 10
    title, release_year, revenue_million_usd, budget_million_usd, roi_pct
FROM movies_dataset
ORDER BY revenue_million_usd DESC;
-- FINDING: "Dark Vengeance" (2021) leads with $5.93B revenue on a $107.8M budget
-- (5404% ROI) - a clear outlier compared to the rest of the top 10, which range $1B-2.1B. 
-- This kind of single breakout hit is typical of real box office data too.
 

 -- 3. Top 10 highest-rated movies
SELECT TOP 10
    title, release_year, imdb_rating, votes
FROM movies_dataset
ORDER BY imdb_rating DESC;
-- FINDING: Top-rated movies cluster at 9.0-9.5, but vote counts vary hugely(9,054 to 336,885) 
-- showing that a high rating alone doesn't imply high audience reach 
-- some of the top-rated films are lower-visibility titles


-- 4. Yearly release trend
SELECT
    release_year, COUNT(*) AS movies_released,
    ROUND(AVG(budget_million_usd), 1) AS avg_budget,
    ROUND(AVG(revenue_million_usd), 1) AS avg_revenue
FROM movies_dataset
GROUP BY release_year
ORDER BY release_year;
-- FINDING: Average budgets trend upward over time (from ~$35M in 2000 to ~$58-64M
-- in 2022-2024), consistent with real-world budget inflation in the film industry.
-- Revenue is far more volatile year to year, largely driven by individual outlier hits.



-- 5. Budget bracket vs average rating
SELECT
    CASE
        WHEN budget_million_usd < 10 THEN 'Under 10M'
        WHEN budget_million_usd < 30 THEN '10-30M'
        WHEN budget_million_usd < 60 THEN '30-60M'
        ELSE '60M+'
    END AS budget_bracket,
    COUNT(*) AS total_movies,
    ROUND(AVG(imdb_rating), 2) AS avg_rating
FROM movies_dataset
GROUP BY
    CASE
        WHEN budget_million_usd < 10 THEN 'Under 10M'
        WHEN budget_million_usd < 30 THEN '10-30M'
        WHEN budget_million_usd < 60 THEN '30-60M'
        ELSE '60M+'
    END
ORDER BY avg_rating DESC;
-- FINDING:
-- Rating is fairly flat across budget brackets (6.36-6.65)
-- bigger budgets do NOT reliably produce better-rated movies in this dataset, which
-- matches a common real-world finding that budget and critical quality are only weakly related.




-- 6. Top directors by average rating (min 3 movies)
SELECT TOP 10
    director, COUNT(*) AS total_movies,
    ROUND(AVG(imdb_rating), 2) AS avg_rating,
    ROUND(SUM(revenue_million_usd), 1) AS total_revenue
FROM movies_dataset
GROUP BY director
HAVING COUNT(*) >= 3
ORDER BY avg_rating DESC;
-- FINDING: 
-- "M. Chen" has the highest average rating (6.80) across 48 movies.
-- "T. Wilson" generated the most total revenue ($15.7B) across 60 movies -
-- The highest-rated director and the highest-revenue director are not the same person.


-- 7. Biggest flops (revenue below budget)
SELECT TOP 10
    title, release_year, genre, budget_million_usd, revenue_million_usd, roi_pct
FROM movies_dataset
WHERE revenue_million_usd < budget_million_usd
ORDER BY roi_pct ASC;
-- FINDING:
-- The worst flop lost -87.4% of its budget ("Broken Chronicles", 2005,Action, $64.1M budget vs $8.1M revenue).
-- Adventure appears disproportionately often in the flop list, suggesting it carries higher financial risk 
-- than its average performance in Q4 would suggest.
  


-- 8. Top-grossing movie per year (window function - RANK)
WITH ranked AS (
    SELECT
        release_year, title, revenue_million_usd,
        RANK() OVER (PARTITION BY release_year ORDER BY revenue_million_usd DESC) AS rnk
    FROM movies_dataset
)
SELECT TOP 10
    release_year, title, revenue_million_usd
FROM ranked
WHERE rnk = 1
ORDER BY release_year DESC;
-- FINDING: 
-- "Dark Vengeance" (2021, $5.93B) is the standout top-grossing movie of any year shown ,
-- far ahead of every other year's leader, which range $470M-1.8B.
-- Demonstrates RANK() with PARTITION BY for "best per group" queries.