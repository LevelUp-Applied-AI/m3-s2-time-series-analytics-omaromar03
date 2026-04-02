-- Trend Analysis using window frame specifications
-- 7-day and 30-day moving averages for daily revenue
-- 7-day moving average for daily order count

WITH daily_metrics AS (
    SELECT
        o.order_date::date AS day,
        COUNT(DISTINCT o.order_id) AS daily_order_count,
        SUM(oi.quantity * oi.unit_price) AS daily_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.order_date::date
)

SELECT
    day,
    daily_order_count,
    ROUND(daily_revenue, 2) AS daily_revenue,

    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_7d_moving_avg,

    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_30d_moving_avg,

    ROUND(
        AVG(daily_order_count) OVER (
            ORDER BY day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS orders_7d_moving_avg

FROM daily_metrics
ORDER BY day;