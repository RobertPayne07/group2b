/* ============================================================
   CLINIC VISITS — POWER BI STAR SCHEMA
   ============================================================

                     DimDate
                        |
                        |
   DimPatient ---- FactVisits ---- DimDoctor
                        |
                        |
                 DimDepartment
                        |
                        |
                  DimVisitType

   Grain of FactVisits: one row per cleaned, de-duplicated visit
   (VisitID is unique). 25,000 rows.

   IMPORTANT — data actually available: the source file supplied
   for this project is a single fact-level extract. There is no
   separate patient roster, doctor roster, or department-name file.
   DimPatient, DimDoctor and DimDepartment below are therefore
   built as SURROGATE dimensions from the distinct keys present in
   the fact table, not from real master data. Attributes the brief
   lists (BirthYear, Sex, Region, InsuranceScheme, doctor Name,
   YearsOfExperience, department Floor) do not exist in the source
   and are NOT invented here — they are left out rather than
   populated with placeholder values, and are called out as an
   open item for whoever owns that master data.
   ============================================================ */

-- ------------------------------------------------------------
-- DimDate
-- ------------------------------------------------------------
CREATE TABLE DimDate (
    DateKey     INT         PRIMARY KEY,   -- YYYYMMDD
    [Date]      DATE        NOT NULL,
    [Day]       INT         NOT NULL,
    [Week]      INT         NOT NULL,
    [Month]     INT         NOT NULL,
    MonthName   VARCHAR(20) NOT NULL,
    Quarter     INT         NOT NULL,
    [Year]      INT         NOT NULL
);
-- Populated for every calendar day between the min and max visit_date
-- found in the cleaned data (2024-01-01 to 2025-12-30), so month/week
-- totals with zero visits still appear in a trend chart instead of
-- being skipped. Mark this table as the Power BI "Date Table" and
-- build the hierarchy Year > Quarter > MonthName > Day on [Date].

-- ------------------------------------------------------------
-- DimDepartment (surrogate — see note above)
-- ------------------------------------------------------------
CREATE TABLE DimDepartment (
    DepartmentKey  INT         PRIMARY KEY,   -- 1-8, taken directly from source department_id
    DepartmentName VARCHAR(50) NOT NULL       -- placeholder label "Department N"; replace with
                                               -- real names once a department master file exists
);

-- ------------------------------------------------------------
-- DimDoctor (surrogate — see note above)
-- ------------------------------------------------------------
CREATE TABLE DimDoctor (
    DoctorKey   INT         PRIMARY KEY,   -- 1-40, taken directly from source doctor_id
    DoctorLabel VARCHAR(50) NOT NULL       -- placeholder "Doctor N"; Name/Department/
                                           -- YearsOfExperience not present in source data
);

-- ------------------------------------------------------------
-- DimVisitType
-- ------------------------------------------------------------
CREATE TABLE DimVisitType (
    VisitTypeKey INT         PRIMARY KEY,
    VisitType    VARCHAR(20) NOT NULL     -- 'Outpatient' | 'Follow-up' | 'Emergency' | 'Unknown'
);
-- 'Unknown' is a genuine 4th member, not an error: it represents the 1,508 visits
-- whose visit_type was recorded as literal '[NULL]' in the source. Keeping it as
-- a real dimension member (Kimball's "Unknown" pattern) means those visits still
-- count everywhere in the model instead of disappearing from Total Visits.

-- ------------------------------------------------------------
-- DimPatient (surrogate — see note above)
-- ------------------------------------------------------------
CREATE TABLE DimPatient (
    PatientKey          INT     PRIMARY KEY,  -- taken directly from source patient_id
    IsRegisteredPatient BIT     NOT NULL      -- FALSE for the 62 walk-in/placeholder IDs (90000-90061)
                                              -- BirthYear/Sex/Region/InsuranceScheme not present in source
);

-- ------------------------------------------------------------
-- FactVisits
-- ------------------------------------------------------------
CREATE TABLE FactVisits (
    VisitID             INT PRIMARY KEY,      -- de-duplicated business key
    DateKey             INT NOT NULL REFERENCES DimDate(DateKey),
    PatientKey          INT NOT NULL REFERENCES DimPatient(PatientKey),
    DoctorKey           INT NOT NULL REFERENCES DimDoctor(DoctorKey),
    DepartmentKey       INT NOT NULL REFERENCES DimDepartment(DepartmentKey),
    VisitTypeKey        INT NOT NULL REFERENCES DimVisitType(VisitTypeKey),
    WaitMinutes         INT NOT NULL,          -- raw value retained, including the negative ones
    Fee                 INT NOT NULL,
    IsValidWait         BIT NOT NULL,          -- FALSE for the 51 negative wait-time rows
    IsRegisteredPatient BIT NOT NULL           -- denormalised copy of the DimPatient flag, for fast filtering
);

/* ------------------------------------------------------------
   RELATIONSHIPS (Power BI Model view)
   ------------------------------------------------------------
   DimDate.DateKey             1 --- * FactVisits.DateKey        (single direction, Date -> Fact)
   DimPatient.PatientKey       1 --- * FactVisits.PatientKey     (single direction)
   DimDoctor.DoctorKey         1 --- * FactVisits.DoctorKey      (single direction)
   DimDepartment.DepartmentKey 1 --- * FactVisits.DepartmentKey  (single direction)
   DimVisitType.VisitTypeKey   1 --- * FactVisits.VisitTypeKey   (single direction)

   All five relationships: One-to-Many, single-direction filter
   (dimension filters fact). Do not set any of these to bidirectional —
   with five dimensions on one fact table, bidirectional filtering
   creates ambiguous filter paths and is unnecessary here since no
   dimension needs to be filtered by another through the fact table.

   Post-build validation (Week 4 of the brief):
   1. Confirm FactVisits row count = 25,000 in the model.
   2. Slice by one Department -> row count should match the SQL
      profiling query for that department_id.
   3. Add Visit Type = Emergency on top of that -> count should
      shrink further and match the cross-tab from the Python notebook.
   4. Confirm DimDate is marked as the official Date Table (Model
      view > right-click DimDate > "Mark as date table" > Date column).
------------------------------------------------------------ */
