-- Combined Analysis
-- Query 1: Monthly revenue by segment with growth rate and running total
-- Uses: LAG + SUM OVER
WITH monthly_segment_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        c.segment,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date), c.segment
),
segment_growth AS (
    SELECT
        month,
        segment,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY segment
            ORDER BY month
        ) AS prev_month_revenue,
        SUM(revenue) OVER (
            PARTITION BY segment
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_revenue
    FROM monthly_segment_revenue
)
SELECT
    month,
    segment,
    ROUND(revenue, 2) AS revenue,
    ROUND(prev_month_revenue, 2) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0),
        2
    ) AS mom_growth_pct,
    ROUND(running_total_revenue, 2) AS running_total_revenue
FROM segment_growth
ORDER BY segment, month;


-- Query 2: Category revenue share with moving average trend
-- Uses: SUM OVER + AVG OVER with ROWS BETWEEN
WITH daily_category_revenue AS (
    SELECT
        o.order_date::date AS day,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS category_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'completed'
    GROUP BY o.order_date::date, p.category
),
category_share AS (
    SELECT
        day,
        category,
        category_revenue,
        SUM(category_revenue) OVER (
            PARTITION BY day
        ) AS total_daily_revenue
    FROM daily_category_revenue
),
category_trend AS (
    SELECT
        day,
        category,
        category_revenue,
        total_daily_revenue,
        100.0 * category_revenue / NULLIF(total_daily_revenue, 0) AS revenue_share_pct,
        AVG(category_revenue) OVER (
            PARTITION BY category
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS category_7d_avg_revenue
    FROM category_share
)
SELECT
    day,
    category,
    ROUND(category_revenue, 2) AS category_revenue,
    ROUND(total_daily_revenue, 2) AS total_daily_revenue,
    ROUND(revenue_share_pct, 2) AS revenue_share_pct,
    ROUND(category_7d_avg_revenue, 2) AS category_7d_avg_revenue
FROM category_trend
ORDER BY day, category;