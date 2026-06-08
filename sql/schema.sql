-- ============================================================
-- UK Trades Market Analysis
-- Schema: four-table relational model
-- Author: Maung Maung Thode Di
-- Last updated: June 2026
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- TABLE 1: regions
-- Reference/anchor table. All other tables join to this one.
-- Source: ONS Open Geography Portal, December 2024 release.
-- ============================================================

CREATE TABLE IF NOT EXISTS regions (
    region_id   TEXT    PRIMARY KEY,   -- ONS region code, e.g. E12000001
    region_name TEXT    NOT NULL,      -- Official region name
    country     TEXT    NOT NULL DEFAULT 'England'
);

-- ============================================================
-- TABLE 2: employment
-- Annual employee counts for SIC 43 (Specialised construction)
-- by English region.
-- Source: ONS Business Register and Employment Survey (BRES),
-- via NOMIS. SIC code 43 covers electrical installation.
-- ============================================================

CREATE TABLE IF NOT EXISTS employment (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id           TEXT    NOT NULL,
    year                INTEGER NOT NULL,
    sic_code            TEXT    NOT NULL DEFAULT '43',
    sector_description  TEXT    DEFAULT 'Specialised construction activities',
    employee_count      INTEGER NOT NULL,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- ============================================================
-- TABLE 3: housebuilding
-- Annual residential building starts and completions by region.
-- Source: MHCLG Live Table 217, England only.
-- Starts = planning-approved projects that broke ground.
-- Completions = finished units. Both are demand-side signals.
-- ============================================================

CREATE TABLE IF NOT EXISTS housebuilding (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id       TEXT    NOT NULL,
    year            INTEGER NOT NULL,
    starts          INTEGER,
    completions     INTEGER,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

-- ============================================================
-- TABLE 4: pricing_benchmarks
-- Estimated electrician day rates and annual salaries by region.
-- Source: ONS Annual Survey of Hours and Earnings (ASHE) 2024
-- for salary data (via elec.training); day rates manually
-- compiled from Logic4training 2025 survey and fixatrader.com.
-- Note: salary = employed electrician; day rate = self-employed
-- charge to customer. These are different metrics and are not
-- directly comparable.
-- ============================================================

CREATE TABLE IF NOT EXISTS pricing_benchmarks (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    region_id               TEXT    NOT NULL,
    trade_type              TEXT    NOT NULL DEFAULT 'electrician',
    avg_annual_salary_gbp   REAL,
    avg_hourly_rate_low     REAL,
    avg_hourly_rate_high    REAL,
    avg_day_rate_low        REAL,
    avg_day_rate_high       REAL,
    data_source             TEXT,
    reference_year          INTEGER,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);

--=============================================================
--Data imported into regions table from ons_regions_reference.csv.
--Table staging_employment is created to prepare data for the actual employment table.
--Data imported into staging_employment from bres_construction_by_region.csv.
--=============================================================

CREATE TABLE staging_employment (
    region_name TEXT,
    "2015" INTEGER,
    "2016" INTEGER,
    "2017" INTEGER,
    "2018" INTEGER,
    "2019" INTEGER,
    "2020" INTEGER,
    "2021" INTEGER,
    "2022" INTEGER,
    "2023" INTEGER,
    "2024" INTEGER
);

--=============================================================
--Data from staging_employment inserted into employment.
--Data imported into housebuilding table from mhclg_housebuilding_by_region.csv.
--Data imported into pricing_benchmarks from pricing_benchmarks_manual.csv.
--=============================================================

INSERT INTO employment (region_id, year, employee_count)
SELECT r.region_id, 2015, s."2015"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2016, s."2016"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2017, s."2017"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2018, s."2018"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2019, s."2019"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2020, s."2020"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2021, s."2021"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2022, s."2022"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2023, s."2023"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name
UNION ALL
SELECT r.region_id, 2024, s."2024"
FROM staging_employment s
JOIN regions r ON s.region_name = r.region_name;

-- Counting rows in each table.

SELECT 'regions'            AS tbl, COUNT(*) AS row_count FROM regions
UNION ALL
SELECT 'employment'         AS tbl, COUNT(*) AS row_count FROM employment
UNION ALL
SELECT 'housebuilding'      AS tbl, COUNT(*) AS row_count FROM housebuilding
UNION ALL
SELECT 'pricing_benchmarks' AS tbl, COUNT(*) AS row_count FROM pricing_benchmarks;

-- Verifying employment range looks plausible.

SELECT
    MIN(year)           AS earliest_year,
    MAX(year)           AS latest_year,
    MIN(employee_count) AS min_employees,
    MAX(employee_count) AS max_employees
FROM employment;

-- Checking for any region_id mismatches.

SELECT region_id FROM employment WHERE region_id IS NULL;
