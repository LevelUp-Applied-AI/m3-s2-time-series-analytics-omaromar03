-- Growth Analysis using LAG and LEAD
-- 1) Month-over-month revenue and order growth
-- 2) Quarter-over-quarter revenue growth

WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
),
monthly_growth AS (
    SELECT
        month,
        order_count,
        revenue,
        LAG(order_count) OVER (ORDER BY month) AS prev_order_count,
        LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
        LEAD(revenue) OVER (ORDER BY month) AS next_month_revenue
    FROM monthly_metrics
)
SELECT
    month,
    order_count,
    prev_order_count,
    ROUND(
        100.0 * (order_count - prev_order_count) / NULLIF(prev_order_count, 0),
        2
    ) AS mom_order_growth_pct,
    ROUND(revenue, 2) AS revenue,
    ROUND(prev_revenue, 2) AS prev_revenue,
    ROUND(
        100.0 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0),
        2
    ) AS mom_revenue_growth_pct,
    ROUND(next_month_revenue, 2) AS next_month_revenue
FROM monthly_growth
ORDER BY month;

WITH quarterly_metrics AS (
    SELECT
        DATE_TRUNC('quarter', o.order_date) AS quarter,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('quarter', o.order_date)
),
quarterly_growth AS (
    SELECT
        quarter,
        order_count,
        revenue,
        LAG(revenue) OVER (ORDER BY quarter) AS prev_quarter_revenue
    FROM quarterly_metrics
)
SELECT
    quarter,
    order_count,
    ROUND(revenue, 2) AS revenue,
    ROUND(prev_quarter_revenue, 2) AS prev_quarter_revenue,
    ROUND(
        100.0 * (revenue - prev_quarter_revenue) / NULLIF(prev_quarter_revenue, 0),
        2
    ) AS qoq_revenue_growth_pct
FROM quarterly_growth
ORDER BY quarter;