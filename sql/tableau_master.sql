-- Master export for Tableau dashboard
-- One row per region per year, all metrics combined

SELECT
    r.region_name,
    e.year,
    e.employee_count,
    h.starts                                                AS housing_starts,
    h.completions                                           AS housing_completions,
    ROUND(h.starts * 1.0 / e.employee_count, 2)            AS starts_per_worker,
    pb.avg_annual_salary_gbp,
    pb.avg_day_rate_low,
    pb.avg_day_rate_high,
    ROUND((pb.avg_day_rate_low + pb.avg_day_rate_high) / 2.0, 0)
                                                            AS avg_day_rate_mid,
    LAG(h.starts) OVER (
        PARTITION BY r.region_id ORDER BY e.year
    )                                                       AS prev_year_starts,
    ROUND(
        (h.starts - LAG(h.starts) OVER (
            PARTITION BY r.region_id ORDER BY e.year
        )) * 100.0
        / LAG(h.starts) OVER (
            PARTITION BY r.region_id ORDER BY e.year
        ), 1
    )                                                       AS starts_yoy_pct,
    ROUND(
        (e.employee_count - LAG(e.employee_count) OVER (
            PARTITION BY r.region_id ORDER BY e.year
        )) * 100.0
        / LAG(e.employee_count) OVER (
            PARTITION BY r.region_id ORDER BY e.year
        ), 1
    )                                                       AS employment_yoy_pct
FROM regions r
JOIN employment     e  ON r.region_id = e.region_id
JOIN housebuilding  h  ON r.region_id = h.region_id AND h.year = e.year
JOIN pricing_benchmarks pb ON r.region_id = pb.region_id
ORDER BY r.region_name, e.year;