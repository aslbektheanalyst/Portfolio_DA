#1 Monthly Sales Trend Analysis

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS sales_month,
        SUM(sales_amount) AS monthly_revenue,
        SUM(cost_amount) AS monthly_cost,
        SUM(sales_amount - cost_amount) AS monthly_profit,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM orders2
    GROUP BY DATE_TRUNC('month', order_date)
),

monthly_growth AS (
    SELECT
        sales_month,
        monthly_revenue,
        monthly_cost,
        monthly_profit,
        total_orders,
        unique_customers,

        LAG(monthly_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue

    FROM monthly_sales
)

SELECT
    TO_CHAR(sales_month, 'YYYY-MM') AS month,

    CASE
        WHEN monthly_revenue >= 1000000
            THEN '$' || ROUND(monthly_revenue / 1000000.0, 2) || 'M'
        WHEN monthly_revenue >= 1000
            THEN '$' || ROUND(monthly_revenue / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(monthly_revenue, 2)
    END AS revenue,

    CASE
        WHEN monthly_profit >= 1000000
            THEN '$' || ROUND(monthly_profit / 1000000.0, 2) || 'M'
        WHEN monthly_profit >= 1000
            THEN '$' || ROUND(monthly_profit / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(monthly_profit, 2)
    END AS profit,

    total_orders,
    unique_customers,

    ROUND(
        (monthly_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS revenue_growth_percentage

FROM monthly_growth
ORDER BY sales_month;


#2 Product Category Performance Ranking

WITH category_performance AS (
    SELECT
        product_category,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT product_id) AS unique_products,
        SUM(quantity) AS units_sold,
        SUM(sales_amount) AS revenue,
        SUM(cost_amount) AS cost,
        SUM(sales_amount - cost_amount) AS profit
    FROM orders2
    GROUP BY product_category
),

ranked_categories AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY profit DESC
        ) AS profit_rank
    FROM category_performance
)

SELECT
    profit_rank,
    product_category,
    total_orders,
    unique_products,
    units_sold,

    CASE
        WHEN revenue >= 1000000
            THEN '$' || ROUND(revenue / 1000000.0, 2) || 'M'
        WHEN revenue >= 1000
            THEN '$' || ROUND(revenue / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(revenue, 2)
    END AS revenue,

    CASE
        WHEN profit >= 1000000
            THEN '$' || ROUND(profit / 1000000.0, 2) || 'M'
        WHEN profit >= 1000
            THEN '$' || ROUND(profit / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(profit, 2)
    END AS profit,

    ROUND(
        profit / NULLIF(revenue, 0) * 100,
        2
    ) AS profit_margin_percentage

FROM ranked_categories
ORDER BY profit_rank;



#3 Top Performing Products

WITH product_performance AS (
    SELECT
        product_id,
        product_name,
        product_category,

        SUM(quantity) AS units_sold,
        SUM(sales_amount) AS revenue,
        SUM(cost_amount) AS cost,
        SUM(sales_amount - cost_amount) AS profit,

        AVG(unit_price) AS average_unit_price
    FROM orders2
    GROUP BY
        product_id,
        product_name,
        product_category
),

ranked_products AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            ORDER BY profit DESC
        ) AS profit_rank
    FROM product_performance
)

SELECT
    profit_rank,
    product_name,
    product_category,
    units_sold,

    CASE
        WHEN revenue >= 1000000
            THEN '$' || ROUND(revenue / 1000000.0, 2) || 'M'
        WHEN revenue >= 1000
            THEN '$' || ROUND(revenue / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(revenue, 2)
    END AS revenue,

    CASE
        WHEN profit >= 1000000
            THEN '$' || ROUND(profit / 1000000.0, 2) || 'M'
        WHEN profit >= 1000
            THEN '$' || ROUND(profit / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(profit, 2)
    END AS profit,

    ROUND(
        profit / NULLIF(revenue, 0) * 100,
        2
    ) AS profit_margin_percentage,

    ROUND(average_unit_price, 2) AS average_unit_price

FROM ranked_products
ORDER BY profit_rank
LIMIT 15;



#4 Store Performance Analysis

WITH store_metrics AS (
    SELECT
        store_name,
        city,
        country,

        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(quantity) AS units_sold,
        SUM(sales_amount) AS revenue,
        SUM(sales_amount - cost_amount) AS profit
    FROM orders2
    GROUP BY
        store_name,
        city,
        country
),

store_rankings AS (
    SELECT
        *,
        RANK() OVER (
            ORDER BY profit DESC
        ) AS profit_rank,

        RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM store_metrics
)

SELECT
    profit_rank,
    revenue_rank,
    store_name,
    city,
    country,
    total_orders,
    unique_customers,
    units_sold,

    CASE
        WHEN revenue >= 1000000
            THEN '$' || ROUND(revenue / 1000000.0, 2) || 'M'
        WHEN revenue >= 1000
            THEN '$' || ROUND(revenue / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(revenue, 2)
    END AS revenue,

    CASE
        WHEN profit >= 1000000
            THEN '$' || ROUND(profit / 1000000.0, 2) || 'M'
        WHEN profit >= 1000
            THEN '$' || ROUND(profit / 1000.0, 1) || 'K'
        ELSE '$' || ROUND(profit, 2)
    END AS profit,

    ROUND(
        profit / NULLIF(revenue, 0) * 100,
        2
    ) AS profit_margin_percentage

FROM store_rankings
ORDER BY profit_rank;



#5 High Revenue Products with Low Profit Margins

SELECT
    product_name,
    product_category,
    SUM(quantity) AS units_sold,

    '$' || ROUND(SUM(sales_amount) / 1000.0, 1) || 'K' AS revenue,

    '$' || ROUND(
        SUM(sales_amount - cost_amount) / 1000.0,
        1
    ) || 'K' AS profit,

    ROUND(
        SUM(sales_amount - cost_amount)
        / NULLIF(SUM(sales_amount), 0) * 100,
        2
    ) AS profit_margin_percentage

FROM orders2
GROUP BY
    product_name,
    product_category

HAVING
    SUM(sales_amount) > (
        SELECT AVG(product_revenue)
        FROM (
            SELECT SUM(sales_amount) AS product_revenue
            FROM orders2
            GROUP BY product_id
        ) AS product_sales
    )

ORDER BY profit_margin_percentage ASC;