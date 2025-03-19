SELECT * FROM md_water_services.employee;
-- create an email for employees using '@ndogowater.gov'
SELECT 
    employee_name
FROM
    employee;
-- TASK 1. create an email for employees using '@ndogowater.gov'
SELECT 
    CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),
            '@ndogowater.gov') AS new_email
FROM
    employee;

SET SESSION sql_safe_updateS = OFF;

UPDATE employee 
SET 
    email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),
            '@ndogowater.gov');

SELECT 
    LENGTH(phone_number)
FROM
    employee;
-- TASK 2. Trim off the trialling white space in the phone numbers 
SELECT 
    RTRIM(phone_number)
FROM
    employee;
-- Update your database with the new phone numbers
UPDATE employee 
SET 
    phone_number = RTRIM(phone_number);
-- Let's have a look at where our employees live.
SELECT town_name, COUNT(employee_name) AS no_of_employee
FROM employee
GROUP BY town_name;
-- get the employee_ids and use those to get the names, email and phone numbers of the three field surveyors with the most location visits.
SELECT 
    assigned_employee_id, SUM(visit_count) AS Number_of_visits
FROM
    visits
GROUP BY assigned_employee_id
ORDER BY Number_of_visits DESC
LIMIT 3;
-- Get the Name, Email address and phone number of employee 1, 30 and 34 from our employee table.
SELECT 
    employee_name, email, phone_number, position
FROM
    employee
WHERE
    assigned_employee_id IN (1 , 30, 34);

-- Analysing locations
-- Create a query that counts the number of records per town
SELECT 
    town_name, COUNT(location_id) AS Record_per_town
FROM
    location
GROUP BY town_name
ORDER BY Record_per_town DESC;

-- Count the records per province.

SELECT 
    province_name, COUNT(location_id) AS Records_per_province
FROM
    location
GROUP BY province_name
ORDER BY Records_per_province DESC;
/*Can you find a way to do the following:
1. Create a result set showing:
• province_name
• town_name
• An aggregated count of records for each town (consider naming this records_per_town).
• Ensure your data is grouped by both province_name and town_name.
2. Order your results primarily by province_name. Within each province, 
further sort the towns by their record counts in descending order.*/
SELECT 
    province_name,
    town_name,
    COUNT(location_id) AS records_per_town
FROM
    location
GROUP BY province_name , town_name
ORDER BY province_name , records_per_town DESC;
-- Finally, look at the number of records for each location type
SELECT 
    location_type, COUNT(location_id) AS number_of_records
FROM
    location
GROUP BY location_type
ORDER BY number_of_records DESC;
-- Rural records in percentage 
SELECT ROUND(23740 / (15910 + 23740) * 100, 0) AS Percentage_rural_area_record;
-- Diving into the sources 
-- How many people did we survey in total? 
SELECT SUM(number_of_people_served) AS Total_population_served
FROM water_source;
-- count how many of each of the different water source types there are, and remember to sort them.
SELECT 
    type_of_water_source, COUNT(*) AS number_of_sources
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY number_of_sources DESC;
-- What is the average number of people that are served by each water source? Remember to make the numbers easy to read.
SELECT 
    type_of_water_source,
    ROUND(AVG(number_of_people_served), 0) AS ave_people_per_source
FROM
    water_source
GROUP BY type_of_water_source;
-- calculate the total number of people served by each type of water source in total, to make it easier to interpret, order them so the most
-- people served by a source is at the top.
SELECT 
    type_of_water_source,
    avg(number_of_people_served) AS population_served
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;
SELECT 
    type_of_water_source,
    ROUND((SUM(number_of_people_served) / 27628140) * 100, 0) AS Percentage_population_served
FROM
    water_source
GROUP BY type_of_water_source
ORDER BY Percentage_population_served DESC;
-- Ranking the total number of people served 
SELECT 
    type_of_water_source,
    SUM(number_of_people_served) AS population_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_by_population
FROM
    water_source
WHERE  type_of_water_source <> 'tap_in_home'
GROUP BY type_of_water_source
ORDER BY population_served DESC;
/*create a query to do this, and keep these requirements in mind:
1. The sources within each type should be assigned a rank.
2. Limit the results to only improvable sources.
3. Think about how to partition, filter and order the results set.
4. Order the results to see the top of the list.*/

SELECT source_id, type_of_water_source, number_of_people_served,
RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM water_source
WHERE type_of_water_source <> 'tap_in_home';

-- UNDERSTANDING DENSE_RANKING 
SELECT source_id, type_of_water_source, number_of_people_served,
DENSE_RANK() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM water_source
WHERE type_of_water_source <> 'tap_in_home';

-- UNDERSTANDING ROW_NUMBER 
SELECT source_id, type_of_water_source, number_of_people_served,
ROW_NUMBER() OVER (PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS priority_rank
FROM water_source
WHERE type_of_water_source <> 'tap_in_home';

-- Analysing queues
-- How long did the survey take?
SELECT 
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS Total_number_of_days
FROM
    visits;
-- What is the average total queue time for water?
SELECT 
    ROUND(AVG(time_in_queue), 0) AS Avg_queue_time
FROM
    visits
WHERE
    time_in_queue <> 0;
-- What is the average total queue time for water? Using the NULLIF function 
SELECT 
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS Avg_queue_time
FROM
    visits;
-- let's look at the queue times aggregated across the different days of the week.
SELECT DAYNAME(time_of_record) AS Days_of_week,
ROUND(AVG(NULLIF(time_in_queue, 0)), 0)  AS Avg_queue_time
FROM 
visits
GROUP BY Days_of_week;
-- Avg time by hour of day 
SELECT 
    HOUR(time_of_record) AS Hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS Avg_queue_time
FROM
    visits
GROUP BY Hour_of_day
ORDER BY Hour_of_day ASC;
-- Let's make the time fprmat more realistic 
SELECT 
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS Avg_queue_time
FROM
    visits
GROUP BY Hour_of_day
ORDER BY Hour_of_day ASC;

-- Break down the time in queue into days of the week and hour of the days.
-- Sunday 
SELECT TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_day,
-- SUNDAY
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END), 0) AS Sunday,
-- Monday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END), 0) AS Monday,
-- Tuesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END), 0) AS Tuesday,
-- Wednesday 
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END), 0) AS Wednesday,
-- Thursday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END), 0) AS Thursday,
-- Friday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END), 0) AS Friday,
-- Saturday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END), 0) AS Saturday
FROM
    visits
GROUP BY Hour_of_day
ORDER BY Hour_of_day;

