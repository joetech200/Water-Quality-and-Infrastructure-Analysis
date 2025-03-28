-- Start by joining location to visits.
SELECT 
    l.province_name,
    l.location_id, 
    l.town_name,
    v.visit_count
FROM
    Location AS l
        JOIN
    Visits AS v ON l.location_id = v.location_id;
-- join the water_source table on the key shared between water_source and visits.
SELECT 
    l.province_name,
    l.town_name,
    v.visit_count,
    l.location_id,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM
    Location AS l
        JOIN
    Visits AS v ON l.location_id = v.location_id
        JOIN
    water_source AS ws ON v.source_id = ws.source_id;

-- Removing Duplicate on the visit count
SELECT 
    l.province_name,
    l.town_name,
    v.visit_count,
    l.location_id,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM
    Location AS l
        JOIN
    Visits AS v ON l.location_id = v.location_id
        JOIN
    water_source AS ws ON v.source_id = ws.source_id
WHERE
    v.visit_count = 1;
-- Remove the location_id and visit_count columns. then Add the location_type column from location and time_in_queue from visits to our results set.
SELECT 
    l.province_name,
    l.town_name,
    ws.type_of_water_source,
    l.location_type,
    ws.number_of_people_served,
    v.time_in_queue
FROM
    Location AS l
        JOIN
    Visits AS v ON l.location_id = v.location_id
        JOIN
    water_source AS ws ON v.source_id = ws.source_id
WHERE
    v.visit_count = 1;  
-- Now we need to grab the results from the well_pollution table (join the well_polution table to the visit table) 
SELECT 
    l.province_name,
    l.town_name,
    ws.type_of_water_source,
    l.location_type,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM
    Location AS l
        JOIN
    Visits AS v ON l.location_id = v.location_id
        JOIN
    water_source AS ws ON v.source_id = ws.source_id
 LEFT JOIN
    well_pollution AS wp ON v.source_id = wp.source_id
WHERE
    v.visit_count = 1;  
    
-- Create a view and call it the combined_analysis_table.
CREATE VIEW combined_analysis_table AS
SELECT 
    l.province_name,
    l.town_name,
    ws.type_of_water_source,
    l.location_type,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM
    Location AS l
        JOIN
    Visits AS v ON l.location_id = v.location_id
        JOIN
    water_source AS ws ON v.source_id = ws.source_id
 LEFT JOIN
    well_pollution AS wp ON v.source_id = wp.source_id
WHERE
    v.visit_count = 1;  
-- The last analysis
WITH province_totals AS (-- This CTE calculates the population of each province
	SELECT
		province_name,
		SUM(number_of_people_served) AS total_ppl_serv
	FROM
		combined_analysis_table
	GROUP BY
		province_name
	)
SELECT
	ct.province_name,
	-- These case statements create columns for each type of source.
	-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well' 
				THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN
	province_totals AS pt ON ct.province_name = pt.province_name
GROUP BY
	ct.province_name
ORDER BY
	ct.province_name;
-- Aggregating data per town 
WITH town_totals AS (-- This CTE calculates the population of each province
	SELECT
		province_name, town_name,
		SUM(number_of_people_served) AS total_ppl_serv
	FROM
		combined_analysis_table
	GROUP BY
		province_name, town_name
	)
SELECT
	ct.province_name, ct.town_name,
	-- These case statements create columns for each type of source.
	-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well' 
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN
	town_totals AS tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
	ct.province_name, ct.town_name
ORDER BY
	ct.province_name;

-- Create a temporary table 

CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (-- This CTE calculates the population of each province
	SELECT
		province_name, town_name,
		SUM(number_of_people_served) AS total_ppl_serv
	FROM
		combined_analysis_table
	GROUP BY
		province_name, town_name
	)
SELECT
	ct.province_name, ct.town_name,
	-- These case statements create columns for each type of source.
	-- The results are aggregated and percentages are calculated
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well'
				THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table AS ct
JOIN
	town_totals AS tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
	ct.province_name, ct.town_name
ORDER BY
	ct.province_name;

-- Create a table to track solution progress - creating a table with explanation. 

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future.
*/
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity.
*/
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
*/
Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);
-- creating a table called project_progress (standard form)
CREATE TABLE Project_progress (
    Project_id SERIAL PRIMARY KEY,
    source_id VARCHAR(20) NOT NULL REFERENCES water_source (source_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
    Address VARCHAR(50),
    Town VARCHAR(30),
    Province VARCHAR(30),
    Source_type VARCHAR(50),
    Improvement VARCHAR(50),
    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog' , 'In progress', 'Complete')),
    Date_of_completion DATE,
    Comments TEXT
);




-- Project_progress_query
SELECT 
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE
        WHEN
            (type_of_water_source = 'well'
                AND well_pollution.results = 'Contaminated: Chemical')
        THEN
            'Install RO filter'
        WHEN
            (type_of_water_source = 'well'
                AND well_pollution.results = 'Contaminated: Biological')
        THEN
            'Install UV and RO filter'
        WHEN type_of_water_source = 'river' THEN 'Drill wells'
        WHEN
            (type_of_water_source = 'shared_tap'
                AND time_in_queue >= 30)
        THEN
            (CONCAT('Install ',
                    FLOOR(visits.time_in_queue / 30),
                    ' taps nearby'))
        WHEN type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source
        LEFT JOIN
    well_pollution ON water_source.source_id = well_pollution.source_id
        INNER JOIN
    visits ON water_source.source_id = visits.source_id
        INNER JOIN
    location ON location.location_id = visits.location_id
WHERE
    visit_count = 1
        AND (results != 'Clean'
        OR type_of_water_source IN ('river' , 'tap_in_home_broken')
        OR (type_of_water_source = 'shared_tap'
        AND visits.time_in_queue >= 30));
        
-- Insert  into the Project_progress table 
INSERT INTO project_progress (
    source_id,
    address,
    town,
    province,
    source_type,
    improvement
)
SELECT 
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE
        WHEN (type_of_water_source = 'well' AND well_pollution.results = 'Contaminated: Chemical') 
        THEN 'Install RO filter'
        WHEN (type_of_water_source = 'well' AND well_pollution.results = 'Contaminated: Biological') 
        THEN 'Install UV and RO filter'
        WHEN type_of_water_source = 'river' 
        THEN 'Drill wells'
        WHEN (type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30) 
        THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
        WHEN type_of_water_source = 'tap_in_home_broken' 
        THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM water_source
LEFT JOIN well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN visits ON water_source.source_id = visits.source_id
INNER JOIN location ON location.location_id = visits.location_id
WHERE visit_count = 1
AND (results != 'Clean'
    OR type_of_water_source IN ('river', 'tap_in_home_broken')
    OR (type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30));
    
