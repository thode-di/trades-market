-- Q1: Regional concentration of specialised construction workers (2023)
-- Business question: Which regions have the highest absolute number of
-- trades workers? This is the supply side of the market equation.

SELECT
    r.region_name,
    e.employee_count,
    ROUND(
        e.employee_count * 100.0 / SUM(e.employee_count) OVER (),
        1
    ) AS pct_of_england_total,
    RANK() OVER (ORDER BY e.employee_count DESC) AS supply_rank
FROM employment e
JOIN regions r ON e.region_id = r.region_id
WHERE e.year = 2023
ORDER BY e.employee_count DESC;

-- Q2: Year-on-year change in specialised construction employment by region
-- Business question: Which regions are growing their trades workforce,
-- and which are shrinking? Rising employment could signal either strong
-- demand pulling workers in, or oversupply developing.

SELECT
    r.region_name,
    e.year,
    e.employee_count,
    LAG(e.employee_count) OVER (
        PARTITION BY e.region_id ORDER BY e.year
    ) AS prev_year_count,
    ROUND(
        (e.employee_count
            - LAG(e.employee_count) OVER (
                PARTITION BY e.region_id ORDER BY e.year
              )
        ) * 100.0
        / LAG(e.employee_count) OVER (
            PARTITION BY e.region_id ORDER BY e.year
          ),
        1
    ) AS yoy_growth_pct
FROM employment e
JOIN regions r ON e.region_id = r.region_id
ORDER BY r.region_name, e.year;

-- Q3: Housebuilding starts growth by region, year-on-year
-- Business question: Which regions show the strongest growth in new
-- residential projects? More starts = more demand for electrical
-- installation work in the near term.

SELECT
    r.region_name,
    h.year,
    h.starts,
    LAG(h.starts) OVER (
        PARTITION BY h.region_id ORDER BY h.year
    ) AS prev_year_starts,
    ROUND(
        (h.starts
            - LAG(h.starts) OVER (
                PARTITION BY h.region_id ORDER BY h.year
              )
        ) * 100.0
        / LAG(h.starts) OVER (
            PARTITION BY h.region_id ORDER BY h.year
          ),
        1
    ) AS starts_yoy_growth_pct
FROM housebuilding h
JOIN regions r ON h.region_id = r.region_id
ORDER BY r.region_name, h.year;

-- Q4: Electrician pricing benchmarks ranked by region
-- Business question: Where are day rates highest relative to salary?
-- A wide gap between employed salary and self-employed day rate
-- signals strong independent market activity and pricing power.

SELECT
    r.region_name,
    pb.avg_annual_salary_gbp,
    pb.avg_day_rate_low  AS day_rate_low_gbp,
    pb.avg_day_rate_high AS day_rate_high_gbp,
    ROUND(
        (pb.avg_day_rate_low + pb.avg_day_rate_high) / 2, 0
    ) AS day_rate_mid_gbp,
    ROUND(
        ((pb.avg_day_rate_low + pb.avg_day_rate_high) / 2) * 220, 0
    ) AS implied_annual_self_employed_gbp,
    RANK() OVER (ORDER BY pb.avg_annual_salary_gbp DESC) AS salary_rank
FROM pricing_benchmarks pb
JOIN regions r ON pb.region_id = r.region_id
ORDER BY pb.avg_annual_salary_gbp DESC;

-- Q5: Regional market opportunity scorecard (2024)
-- Business question: Which regions show the combination of high housing
-- demand, relatively low trades worker supply, and pricing that signals
-- an active independent market? These are the highest-priority regions
-- for a platform building a partner network.

WITH demand_supply AS (
    SELECT
        r.region_name,
        r.region_id,
        e.employee_count                                AS trades_workers,
        h.starts                                        AS housing_starts,
        ROUND(h.starts * 1.0 / e.employee_count, 2)    AS starts_per_worker
    FROM regions r
    JOIN employment     e ON r.region_id = e.region_id AND e.year = 2024
    JOIN housebuilding  h ON r.region_id = h.region_id AND h.year = 2024
),
averages AS (
    SELECT AVG(starts_per_worker) AS avg_ratio FROM demand_supply
)
SELECT
    ds.region_name,
    ds.trades_workers,
    ds.housing_starts,
    ds.starts_per_worker,
    ROUND((pb.avg_day_rate_low + pb.avg_day_rate_high) / 2, 0) AS mid_day_rate_gbp,
    pb.avg_annual_salary_gbp,
    CASE
        WHEN ds.starts_per_worker > (SELECT avg_ratio FROM averages)
        THEN 'UNDERSERVED'
        ELSE 'WELL-SUPPLIED'
    END AS market_signal
FROM demand_supply ds
JOIN pricing_benchmarks pb ON ds.region_id = pb.region_id
ORDER BY ds.starts_per_worker DESC;