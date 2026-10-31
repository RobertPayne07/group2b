/* ============================================================
   CLINIC VISITS — SQL DATA PROFILING QUERIES
   Run against the raw table exactly as loaded from Clinic_Visits.xlsx.
   Assumes a table: raw_clinic_visits(
       row_num INT, visit_id INT, visit_date TEXT/DATE, patient_id INT,
       doctor_id INT, department_id INT, visit_type TEXT,
       wait_minutes INT, consultation_fee INT
   )
   Written in ANSI SQL; a couple of lines are flagged where a
   specific engine (Postgres/SQL Server/MySQL) needs a different
   function — swap as needed.
   ============================================================ */

-- ------------------------------------------------------------
-- 0. Row count sanity check
-- ------------------------------------------------------------
SELECT COUNT(*) AS raw_row_count
FROM raw_clinic_visits;
-- Expected: 25,100


-- ------------------------------------------------------------
-- 1. MISSING VALUES — every column that could plausibly be blank
-- ------------------------------------------------------------
SELECT
    SUM(CASE WHEN department_id IS NULL THEN 1 ELSE 0 END)  AS missing_department,
    SUM(CASE WHEN visit_date    IS NULL THEN 1 ELSE 0 END)  AS missing_visit_date,
    SUM(CASE WHEN wait_minutes  IS NULL THEN 1 ELSE 0 END)  AS missing_wait_minutes,
    SUM(CASE WHEN patient_id    IS NULL THEN 1 ELSE 0 END)  AS missing_patient_id,
    SUM(CASE WHEN doctor_id     IS NULL THEN 1 ELSE 0 END)  AS missing_doctor_id,
    SUM(CASE WHEN visit_type    IS NULL
              OR TRIM(visit_type) = ''
              OR UPPER(TRIM(visit_type)) = '[NULL]' THEN 1 ELSE 0 END) AS missing_visit_type
FROM raw_clinic_visits;
-- Finding: missing_visit_type = 1,508 (stored as literal text '[NULL]', not a true NULL).
-- All other columns: 0 missing.


-- ------------------------------------------------------------
-- 2. DUPLICATES
-- ------------------------------------------------------------

-- 2a. Duplicate visit_id
SELECT visit_id, COUNT(*) AS occurrences
FROM raw_clinic_visits
GROUP BY visit_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, visit_id;
-- Finding: 50 visit_id values appear exactly twice = 100 duplicate rows.

-- 2b. Confirm duplicates are exact row repeats, not just a colliding key
SELECT visit_id, visit_date, patient_id, doctor_id, department_id,
       visit_type, wait_minutes, consultation_fee, COUNT(*) AS occurrences
FROM raw_clinic_visits
GROUP BY visit_id, visit_date, patient_id, doctor_id, department_id,
         visit_type, wait_minutes, consultation_fee
HAVING COUNT(*) > 1;
-- Finding: every duplicated visit_id is a full-row duplicate (all 100 rows collapse
-- to 50 distinct combinations) -> safe to drop the repeat rather than merge/investigate further.

-- 2c. Duplicate patients / duplicate doctors
-- NOTE: cannot be checked as scoped — no DimPatient / DimDoctor master table was supplied,
-- only this fact-level extract. This section is a placeholder for when that master data exists:
-- SELECT patient_id, COUNT(*) FROM dim_patient GROUP BY patient_id HAVING COUNT(*) > 1;
-- SELECT doctor_id,  COUNT(*) FROM dim_doctor  GROUP BY doctor_id  HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 3. INVALID VALUES
-- ------------------------------------------------------------

-- 3a. Negative wait times
SELECT *
FROM raw_clinic_visits
WHERE wait_minutes < 0
ORDER BY wait_minutes;
-- Finding: 51 rows, ranging from -3 to -209 minutes.

-- 3b. Wait time distribution shape (sanity check for absurd upper outliers too)
SELECT
    MIN(wait_minutes) AS min_wait,
    MAX(wait_minutes) AS max_wait,
    AVG(wait_minutes) AS avg_wait,
    SUM(CASE WHEN wait_minutes < 0 THEN 1 ELSE 0 END)   AS negative_count,
    SUM(CASE WHEN wait_minutes > 480 THEN 1 ELSE 0 END) AS over_8h_count
FROM raw_clinic_visits;

-- 3c. Impossible / out-of-range dates
SELECT *
FROM raw_clinic_visits
WHERE visit_date IS NOT NULL
  AND (
        -- adapt CAST/TRY_CAST syntax to your engine, e.g. TRY_CONVERT (SQL Server),
        -- STR_TO_DATE (MySQL), TO_DATE (Postgres/Oracle)
        visit_date > CURRENT_DATE                    -- future-dated visit
     OR visit_date < DATE '2020-01-01'                -- implausibly old for this clinic's launch
  );
-- Finding on the cleaned/parsed dates: 0 rows. Range is 2024-01-01 to 2025-12-30.
-- IMPORTANT: 963 raw rows store visit_date as text ('DD/MM/YYYY') rather than a native
-- date type, so a naive date-typed comparison will silently exclude/mishandle them.
-- Parse those explicitly first, e.g. (Postgres):
--   TO_DATE(visit_date, 'DD/MM/YYYY')
-- or (SQL Server):
--   CONVERT(date, visit_date, 103)

-- 3d. Invalid fees
SELECT DISTINCT consultation_fee
FROM raw_clinic_visits
ORDER BY consultation_fee;
-- Finding: {0, 20, 35, 50, 80, 120} only — no negative fees, no nulls, no absurd outliers.

SELECT department_id, visit_type,
       SUM(CASE WHEN consultation_fee = 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS pct_zero_fee
FROM raw_clinic_visits
GROUP BY department_id, visit_type
ORDER BY department_id, visit_type;
-- Finding: ~35% zero-fee rate is stable across every department and visit type,
-- so fee = 0 looks like a legitimate tier (e.g. waived/covered visit), not a data error.
-- Flag as an assumption to confirm with the business owner, not as a defect to "fix."

-- 3e. Invalid department references (orphan check, range-based proxy)
SELECT DISTINCT department_id
FROM raw_clinic_visits
WHERE department_id NOT BETWEEN 1 AND 8
ORDER BY department_id;
-- Finding: 0 rows returned -> all department_id values fall inside the expected 1-8 range.
-- Caveat: this is a plausibility check, not a true foreign-key check, because no
-- DimDepartment master table was supplied with this extract.

SELECT DISTINCT doctor_id
FROM raw_clinic_visits
WHERE doctor_id NOT BETWEEN 1 AND 40
ORDER BY doctor_id;
-- Finding: 0 rows returned -> all doctor_id values fall inside the expected 1-40 range.


-- ------------------------------------------------------------
-- 4. INCONSISTENT CATEGORIES — visit_type spelling/casing/whitespace
-- ------------------------------------------------------------
SELECT visit_type,
       UPPER(TRIM(visit_type)) AS normalised,
       COUNT(*) AS occurrences
FROM raw_clinic_visits
GROUP BY visit_type
ORDER BY normalised, visit_type;
-- Finding: 13 distinct raw spellings collapse to 3 real categories + literal '[NULL]':
--   OUTPATIENT-family: Outpatient / OUTPATIENT / outpatient / '  Outpatient  '
--   FOLLOW-UP-family:  Follow-up / FOLLOW-UP / follow-up / '  Follow-up  '
--   EMERGENCY-family:  Emergency / EMERGENCY / emergency / '  Emergency  '
--   [NULL] (1,508 rows) -> should become its own explicit "Unknown" category,
--   never silently folded into one of the three real types.


-- ------------------------------------------------------------
-- 5. ORPHAN KEYS (once master/dimension tables are available)
-- ------------------------------------------------------------
-- Template for when dim_patient / dim_doctor / dim_department exist as real tables:

-- SELECT f.*
-- FROM raw_clinic_visits f
-- LEFT JOIN dim_patient p ON f.patient_id = p.patient_id
-- WHERE p.patient_id IS NULL;                 -- visits referencing an unknown patient

-- SELECT f.*
-- FROM raw_clinic_visits f
-- LEFT JOIN dim_doctor d ON f.doctor_id = d.doctor_id
-- WHERE d.doctor_id IS NULL;                  -- visits referencing an unknown doctor

-- SELECT f.*
-- FROM raw_clinic_visits f
-- LEFT JOIN dim_department dep ON f.department_id = dep.department_id
-- WHERE dep.department_id IS NULL;            -- visits referencing an unknown department

-- Proxy used in this project (no master files supplied): flag patient_id values
-- outside the documented 1-900 patient range instead of a true anti-join.
SELECT *
FROM raw_clinic_visits
WHERE patient_id >= 10000
ORDER BY patient_id;
-- Finding: 62 rows, patient_id 90000-90061 -- a distinct contiguous block,
-- consistent with a walk-in / unregistered-patient placeholder range.


-- ------------------------------------------------------------
-- 6. HEADLINE VALIDATION QUERIES (for cross-checking Python / Power BI later)
-- ------------------------------------------------------------

-- 6a. Deduplicated visit count
SELECT COUNT(DISTINCT visit_id) AS unique_visits
FROM raw_clinic_visits;
-- Expected: 25,000

-- 6b. Average wait time by department, valid wait times only, de-duplicated
WITH dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY visit_id ORDER BY row_num) AS rn
    FROM raw_clinic_visits
)
SELECT department_id,
       COUNT(*)              AS n_visits,
       AVG(wait_minutes)     AS avg_wait_minutes
FROM dedup
WHERE rn = 1
  AND wait_minutes >= 0
GROUP BY department_id
ORDER BY avg_wait_minutes DESC;
-- Use this result to cross-check the Python-cleaned average and the Power BI
-- "Average Wait Time" measure sliced by Department — all three should agree (Week 6).
