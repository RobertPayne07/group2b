1. SELECT count(*) FROM raw_clinic.visits;

2. SELECT min(visit_date) AS earliest,
       max(visit_date) AS latest
FROM raw_clinic.visits;

3. SELECT visit_type, count(*) AS rows
FROM raw_clinic.visits
GROUP BY visit_type
ORDER BY visit_type;

4. SELECT count(*)                       AS total,
       count(visit_type)            AS have_a_value,
       count(*) - count(visit_type)    AS missing
FROM raw_clinic.visits;

5. SELECT count(*)                      AS rows,
       count(DISTINCT visit_id)       AS unique_ids,
       count(*) - count(DISTINCT visit_id) AS extras
FROM raw_clinic.visits;

6. SELECT departments.department_name,
       count(*) AS rows
FROM raw_clinic.visits
JOIN raw_clinic.departments
  ON visits.department_id = departments.department_id
GROUP BY departments.department_name
ORDER BY rows DESC;

7. SELECT min(wait_minutes) AS lowest, max(wait_minutes) AS highest
FROM raw_clinic.visits;

--we wanted to see our 4 tables--
SELECT table_name FROM information_schema.tables

WHERE table_schema = 'raw_clinic' ORDER BY table_name;

select * from raw_clinic.visits;

/*select * from raw_clinic.patients;

select * from raw_clinic.departments;

select * from raw_clinic.doctors;*/
