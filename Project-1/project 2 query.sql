SELECT 
    *
FROM
    md_water_services.auditor_report;
    
-- integrating the auditor's report
SELECT 
    auditor_report.location_id AS audit_location,
    auditor_report.true_water_source_score,
    visits.location_id AS visit_location,
    visits.record_id,
    water_quality.subjective_quality_score
FROM
    auditor_report
        INNER JOIN
visits ON auditor_report.location_id = visits.location_id
        JOIN
     water_quality ON visits.record_id = water_quality.record_id;
    
    
    SELECT 
    auditor_report.location_id,
	visits.record_id,
    auditor_report.true_water_source_score as auditor_score,
    water_quality.subjective_quality_score AS surveyor_score,
	employee.employee_name
FROM
    auditor_report
        INNER JOIN
    visits ON auditor_report.location_id = visits.location_id
        JOIN
    water_quality ON visits.record_id = water_quality.record_id
    INNER JOIN
	employee ON visits.assigned_employee_id = employee.assigned_employee_id
     WHERE
     auditor_report.true_water_source_score <> water_quality.subjective_quality_score 
     AND
        visits.visit_count = 1;
        
-- Linking records to employees
WITH Incorrect_records AS (
SELECT 
    a.location_id,
    v.record_id,
    a.true_water_source_score AS auditor_score,
    w.subjective_quality_score AS surveyor_score,
    e.employee_name
FROM
    auditor_report AS a
        INNER JOIN
    visits AS v ON a.location_id = v.location_id
        INNER JOIN
    water_quality AS w ON v.record_id = w.record_id
		INNER JOIN
	employee AS e ON v.assigned_employee_id = e.assigned_employee_id
WHERE
    a.true_water_source_score != w.subjective_quality_score
        AND v.visit_count = 1)
	SELECT DISTINCT employee_name
    FROM Incorrect_records;
    
    
    
WITH Incorrect_records AS (
SELECT 
    a.location_id,
    v.record_id,
    a.true_water_source_score AS auditor_score,
    w.subjective_quality_score AS surveyor_score,
    e.employee_name
FROM
    auditor_report AS a
        INNER JOIN
    visits AS v ON a.location_id = v.location_id
        INNER JOIN
    water_quality AS w ON v.record_id = w.record_id
		INNER JOIN
	employee AS e ON v.assigned_employee_id = e.assigned_employee_id
WHERE
    a.true_water_source_score != w.subjective_quality_score
        AND v.visit_count = 1)
	SELECT 
		employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM incorrect_records
    GROUP BY employee_name;
    
    WITH error_count AS (
	SELECT 
		employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM incorrect_records
    GROUP BY employee_name)
    SELECT * FROM error_count
    WHERE number_of_mistakes > (
		SELECT AVG(number_of_mistakes) 
		FROM error_count);
-- Gathering the evidence 
CREATE VIEW Incorrect_records AS
    (SELECT 
        auditor_report.location_id,
        visits.record_id,
        employee.employee_name,
        auditor_report.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score,
        auditor_report.statements AS statements
    FROM
        auditor_report
            JOIN
        visits ON auditor_report.location_id = visits.location_id
            JOIN
        water_quality AS wq ON visits.record_id = wq.record_id
            JOIN
        employee ON employee.assigned_employee_id = visits.assigned_employee_id
    WHERE
        visits.visit_count = 1
            AND auditor_report.true_water_source_score != wq.subjective_quality_score);

WITH error_count AS (
	SELECT 
		employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM incorrect_records
    GROUP BY employee_name)
    SELECT * FROM error_count
    WHERE number_of_mistakes > (
		SELECT AVG(number_of_mistakes) 
		FROM error_count);
	-- This query filters all of the records where the "corrupt" employees gathered data.
WITH suspect_list AS (
	SELECT 
		employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM incorrect_records
    GROUP BY employee_name)
    SELECT employee_name, location_id, statements
    FROM incorrect_records
    WHERE employee_name IN ('Bello Azibo', 'Zuriel Matembo', 'Malachi Mavuso', 'Lalitha Kaburi')
    AND statements LIKE ("%Suspicion%");
    
  -- Check if there are any employees in the Incorrect_records table with statements mentioning "cash" that are not in our suspect list. This should
-- be as simple as adding one word.

    WITH suspect_list AS (
	SELECT 
		employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM incorrect_records
    GROUP BY employee_name)
    SELECT employee_name, location_id, statements
    FROM incorrect_records
    WHERE employee_name 
    AND statements LIKE ("%cash%");
    
    
    
    SELECT
auditorRep.location_id,
visitsTbl.record_id,
auditorRep.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS employee_score,
wq.subjective_quality_score - auditorRep.true_water_source_score  AS score_diff
FROM auditor_report AS auditorRep
JOIN visits AS visitsTbl
ON auditorRep.location_id = visitsTbl.location_id
JOIN water_quality AS wq
ON visitsTbl.record_id = wq.record_id
WHERE (wq.subjective_quality_score - auditorRep.true_water_source_score) > 9;
	