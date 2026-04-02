-- Cohort Analysis using ROW_NUMBER

WITH first_purchase AS (
    SELECT
        customer_id,
        order_date,
        DATE_TRUNC('month', order_date) AS cohort_month,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS rn
    FROM orders
    WHERE status = 'completed'
),

cohorts AS (
    SELECT
        customer_id,
        cohort_month,
        order_date AS first_order_date
    FROM first_purchase
    WHERE rn = 1
),

repeat_orders AS (
    SELECT
        c.customer_id,
        c.cohort_month,
        c.first_order_date,
        o.order_date,
        (o.order_date - c.first_order_date) AS days_since_first
    FROM cohorts c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
      AND o.order_date > c.first_order_date
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
),

retention AS (
    SELECT
        cs.cohort_month,
        cs.cohort_size,

        COUNT(DISTINCT CASE
            WHEN r.days_since_first <= 30 THEN r.customer_id
        END) AS retained_30,

        COUNT(DISTINCT CASE
            WHEN r.days_since_first <= 60 THEN r.customer_id
        END) AS retained_60,

        COUNT(DISTINCT CASE
            WHEN r.days_since_first <= 90 THEN r.customer_id
        END) AS retained_90

    FROM cohort_sizes cs
    LEFT JOIN repeat_orders r
        ON cs.cohort_month = r.cohort_month
    GROUP BY cs.cohort_month, cs.cohort_size
)

SELECT
    cohort_month,
    cohort_size,

    retained_30,
    ROUND(100.0 * retained_30 / cohort_size, 2) AS retention_30_pct,

    retained_60,
    ROUND(100.0 * retained_60 / cohort_size, 2) AS retention_60_pct,

    retained_90,
    ROUND(100.0 * retained_90 / cohort_size, 2) AS retention_90_pct
#hi
FROM retention
ORDER BY cohort_month;