#1 Where can buyers find undervalued houses?

WITH house_metrics AS (
    SELECT
        street,
        city,
        price,
        price_per_sqft,
        sqft_living,
        bedrooms,
        bathrooms,
        floors,
        condition,
        view,
        waterfront,
        is_renovated,
        house_age,

        AVG(price_per_sqft) OVER (
            PARTITION BY city
        ) AS city_avg_ppsf
    FROM housing
    WHERE price > 0
      AND sqft_living > 0
),

value_houses AS (
    SELECT
        *,
        price_per_sqft - city_avg_ppsf AS ppsf_gap,

        (price_per_sqft / city_avg_ppsf - 1) * 100
            AS discount_vs_city
    FROM house_metrics
)

SELECT
    street,
    city,

    '$' ||
    CASE
        WHEN price >= 1000000
            THEN ROUND((price / 1000000)::numeric, 1) || 'M'
        ELSE ROUND((price / 1000)::numeric, 0) || 'K'
    END AS price,

    ROUND(price_per_sqft::numeric, 0) AS price_per_sqft,
    ROUND(city_avg_ppsf::numeric, 0) AS city_avg_price_per_sqft,

    ROUND(discount_vs_city::numeric, 1) AS discount_vs_city_pct,

    sqft_living,
    bedrooms,
    bathrooms,
    floors,
    condition,
    view,
    waterfront,
    is_renovated,
    house_age

FROM value_houses
WHERE discount_vs_city <= -20
  AND sqft_living >= 1000
ORDER BY discount_vs_city
LIMIT 50;


#2 Which house features actually command a higher price?

WITH house_groups AS (
    SELECT
        CASE
            WHEN sqft_living < 1000 THEN 'Under 1,000 sqft'
            WHEN sqft_living < 2000 THEN '1,000–1,999 sqft'
            WHEN sqft_living < 3000 THEN '2,000–2,999 sqft'
            WHEN sqft_living < 4000 THEN '3,000–3,999 sqft'
            ELSE '4,000+ sqft'
        END AS living_space_group,
        CASE
            WHEN condition <= 2 THEN 'Poor'
            WHEN condition = 3 THEN 'Average'
            ELSE 'Good'
        END AS condition_group,
        price,
        price_per_sqft
    FROM housing
)

SELECT
    living_space_group,
    condition_group,
    COUNT(*) AS homes,
    ROUND(AVG(price)::numeric, 0) AS avg_price,
    ROUND(AVG(price_per_sqft)::numeric, 0) AS avg_price_per_sqft,
    '$' ||
    CASE
        WHEN AVG(price) >= 1000000
            THEN ROUND((AVG(price) / 1000000)::numeric, 1)::text || 'M'
        ELSE ROUND((AVG(price) / 1000)::numeric, 0)::text || 'K'
    END AS avg_price_display
FROM house_groups
GROUP BY living_space_group, condition_group
HAVING COUNT(*) >= 50
ORDER BY AVG(price) DESC;



#3 Which cities offer the best value for buyers?

WITH city_stats AS (
    SELECT
        city,
        COUNT(*) AS homes,
        AVG(price) AS avg_price,
        AVG(price_per_sqft) AS avg_price_per_sqft,
        AVG(sqft_living) AS avg_living_space,
        AVG(house_age) AS avg_house_age
    FROM housing
    WHERE price > 0
    GROUP BY city
),

city_ranked AS (
    SELECT
        *,
        PERCENT_RANK() OVER (
            ORDER BY avg_price_per_sqft
        ) AS value_rank
    FROM city_stats
    WHERE homes >= 30
)

SELECT
    city,
    homes,
    ROUND(avg_price::numeric, 0) AS avg_price,
    CASE
        WHEN avg_price >= 1000000
            THEN '$' || ROUND((avg_price / 1000000)::numeric, 1) || 'M'
        ELSE '$' || ROUND((avg_price / 1000)::numeric, 0) || 'K'
    END AS avg_price_display,
    ROUND(avg_price_per_sqft::numeric, 0) AS avg_price_per_sqft,
    ROUND(avg_living_space::numeric, 0) AS avg_living_space,
    ROUND(avg_house_age::numeric, 1) AS avg_house_age,
    ROUND((value_rank * 100)::numeric, 1) AS price_per_sqft_percentile
FROM city_ranked
ORDER BY avg_price_per_sqft;


#4 Does renovation actually justify the higher price?

WITH renovation_stats AS (
    SELECT
        is_renovated,
        COUNT(*) AS homes,
        AVG(price) AS avg_price,
        AVG(price_per_sqft) AS avg_price_per_sqft,
        AVG(sqft_living) AS avg_living_space,
        AVG(house_age) AS avg_house_age
    FROM housing
    WHERE price > 0
    GROUP BY is_renovated
),

comparison AS (
    SELECT
        *,
        AVG(avg_price) FILTER (
            WHERE is_renovated = FALSE
        ) OVER () AS non_renovated_avg_price,
        AVG(avg_price_per_sqft) FILTER (
            WHERE is_renovated = FALSE
        ) OVER () AS non_renovated_avg_ppsf
    FROM renovation_stats
)

SELECT
    is_renovated,
    homes,
    ROUND(avg_price::numeric, 0) AS avg_price,
    '$' ||
    CASE
        WHEN avg_price >= 1000000
            THEN ROUND((avg_price / 1000000)::numeric, 1) || 'M'
        ELSE ROUND((avg_price / 1000)::numeric, 0) || 'K'
    END AS avg_price_display,
    ROUND(avg_price_per_sqft::numeric, 0) AS avg_price_per_sqft,
    ROUND(avg_living_space::numeric, 0) AS avg_living_space,
    ROUND(avg_house_age::numeric, 1) AS avg_house_age,

    ROUND(
        ((avg_price / non_renovated_avg_price - 1) * 100)::numeric,
        1
    ) AS price_premium_pct,

    ROUND(
        ((avg_price_per_sqft / non_renovated_avg_ppsf - 1) * 100)::numeric,
        1
    ) AS price_per_sqft_premium_pct

FROM comparison
ORDER BY is_renovated;



#5 Waterfront and view: are buyers paying for the location premium?

WITH view_groups AS (
    SELECT
        CASE
            WHEN waterfront = 1 THEN 'Waterfront'
            WHEN view = 0 THEN 'No View'
            WHEN view BETWEEN 1 AND 2 THEN 'Limited View'
            WHEN view BETWEEN 3 AND 4 THEN 'Good View'
            ELSE 'Exceptional View'
        END AS property_type,
        price,
        price_per_sqft,
        sqft_living
    FROM housing
    WHERE price > 0
),

stats AS (
    SELECT
        property_type,
        COUNT(*) AS homes,
        AVG(price) AS avg_price,
        AVG(price_per_sqft) AS avg_price_per_sqft,
        AVG(sqft_living) AS avg_living_space
    FROM view_groups
    GROUP BY property_type
)

SELECT
    property_type,
    homes,
    ROUND(avg_price::numeric, 0) AS avg_price,
    '$' ||
    CASE
        WHEN avg_price >= 1000000
            THEN ROUND((avg_price / 1000000)::numeric, 1) || 'M'
        ELSE ROUND((avg_price / 1000)::numeric, 0) || 'K'
    END AS avg_price_display,
    ROUND(avg_price_per_sqft::numeric, 0) AS avg_price_per_sqft,
    ROUND(avg_living_space::numeric, 0) AS avg_living_space,

    ROUND(
        (
            avg_price_per_sqft /
            MAX(avg_price_per_sqft) OVER () * 100
        )::numeric,
        1
    ) AS price_per_sqft_vs_top_pct

FROM stats
ORDER BY avg_price DESC;


