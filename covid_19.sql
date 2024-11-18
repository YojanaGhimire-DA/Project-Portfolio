-- Data Cleaning
ALTER TABLE country_wise
CHANGE COLUMN `New cases` new_cases INT;
ALTER TABLE country_wise
CHANGE COLUMN `New deaths` new_deaths INT,
CHANGE COLUMN `New recovered` new_recovered INT;

ALTER TABLE country_wise
CHANGE COLUMN `Recovered / 100 Cases` recovered_100cases INT,
CHANGE COLUMN `Deaths / 100 Cases` deaths_100cases INT,
CHANGE COLUMN `Confirmed last week` confirmed_last_week INT, 
CHANGE COLUMN `1 week change` one_week_change INT,
CHANGE COLUMN `weekly_percentage_increase` weekly_percentage_growth double,
CHANGE COLUMN `WHO Region` WHO_region VARCHAR(100) ;
ALTER TABLE country_wise
CHANGE COLUMN `weekly_percentage_increase` weekly_percentage_growth double;

SELECT * FROM country_wise;
-- 1.What is the total number of confirmed, deaths, recovered, and active cases in Nepal?

SELECT Country, sum(Confirmed) AS total_confirmed_cases, SUM(Deaths) AS total_deaths, SUM(Recovered) AS total_recovered, SUM(Active) AS total_active FROM country_wise
WHERE Country = 'Nepal'
GROUP BY Country;

-- 2. How many new cases, new deaths, and new recoveries have been reported in Nepal in the most recent update?

SELECT Country,SUM(new_cases), SUM(new_deaths), SUM(new_recovered) FROM country_wise
WHERE Country = 'Nepal'
GROUP BY Country;

-- 3. What is the recovery rate for nepal?
SELECT recovered_100cases FROM country_wise
WHERE Country = 'Nepal';

-- 4. What is the case fatality rate in Nepal?

SELECT deaths_100cases FROM country_wise
WHERE Country= 'Nepal';

-- 5. How does Nepal's number of active cases compare to the number of recovered cases?
SELECT SUM(Recovered), SUM(Active) FROM country_wise
WHERE Country = 'Nepal'
GROUP BY Country; 

-- 6.How has the number of confirmed cases in Nepal changed over the past week ("1 week change")?
SELECT SUM(Confirmed), SUM(confirmed_last_week) FROM country_wise
WHERE Country = 'Nepal'
GROUP BY Country;

-- 7. By what percentage have COVID-19 cases increased in Nepal over the last week?
SELECT weekly_percentage_increase FROM country_wise
WHERE Country = 'Nepal';

-- 8. How do new cases in Nepal compare to the global average?
SELECT  Country, new_cases ,
     (SELECT AVG(new_cases) FROM country_wise WHERE new_cases > 0) AS Global_Avg_new_cases FROM country_wise
WHERE Country = 'Nepal';     

-- 9. What is the ratio of deaths to recoveries ("Death/100 Recovered") in Nepal?

SELECT Country, `Deaths / 100 Recovered` AS death_to_recovery_ratio FROM country_wise
WHERE Country = 'Nepal';

-- 10. How does Nepal’s recovery rate compare to the global averages?

WITH Nepal_recovery AS (
  SELECT Country, 
  (Recovered/Confirmed)*100 AS recovery_rate
  FROM country_wise
  WHERE Country = 'Nepal' AND Confirmed > 0
),
Global_recovery AS (
  SELECT
  AVG((Recovered/Confirmed)*100) AS global_recovery
  FROM country_wise
  WHERE Confirmed > 0
)
SELECT 
(SELECT recovery_rate FROM Nepal_recovery) AS Nepal_recovery_rate,
(SELECT global_recovery FROM Global_recovery) AS Global_recovery_rate;

-- 11 What percentage of Nepal’s confirmed cases are still active?
SELECT Country, 
(`Active`/Confirmed)*100 AS percent_of_confirmed_active_cases
FROM country_wise
WHERE Country = 'Nepal' AND Confirmed >0;

-- 12. What are the trends in Nepal’s new cases, new deaths, and new recoveries over time?

WITH Numbered_Data AS (
 SELECT 
 ROW_NUMBER() OVER(PARTITION BY Country ORDER BY (Recovered + Active + Deaths) DESC) AS Period,
 Country,
 new_cases,
 new_deaths,
 new_recovered
 FROM country_wise
 WHERE Country = 'Nepal'
)
SELECT
   Period, new_cases,new_deaths, new_recovered
   FROM Numbered_Data
   ORDER BY period;

-- 13 How has the death-to-recovery ratio changed in Nepal during the pandemic?

With death_recovery AS(
   SELECT 
   ROW_NUMBER() OVER(ORDER BY (Recovered + Active+ Deaths) DESC ) AS Period,
   new_deaths, new_recovered
   FROM country_wise
   WHERE Country = 'Nepal'
)
SELECT Period, new_deaths, new_recovered,
IF(new_recovered > 0, new_deaths/ new_recovered, NULL) AS death_to_recovery_ratio
FROM death_recovery
ORDER BY Period;

-- 14 How does Nepals' precentage growth  in cases compare to other countries in the region?

WITH Regional_growth AS (
 SELECT country, WHO_region,weekly_percentage_growth
 FROM country_wise
 WHERE WHO_region = (SELECT WHO_region FROM country_wise WHERE Country = 'Nepal')
)
SELECT Country, weekly_percentage_growth
FROM Regional_growth
ORDER BY 2 DESC;

-- 15 How much does Nepal contribute to the total cases, deaths, and recoveries in its WHO region?
WITH Region_Total AS(
SELECT WHO_region, SUM(Confirmed) total_confirmed, SUM(Deaths) AS total_deaths, SUM(Recovered) total_recoveries 
FROM country_wise
WHERE WHO_region = (SELECT WHO_region FROM country_wise WHERE Country = 'Nepal')
GROUP BY WHO_region
),
Nepal_Data AS(
  SELECT SUM(Confirmed) AS nepal_confirmed,
  SUM(Deaths) AS nepal_deaths, 
  SUM(Recovered) AS nepal_recovered
  FROM country_wise
  WHERE Country='Nepal'
)
SELECT (nepal_confirmed / total_confirmed) * 100 AS nepal_confirmed_rate,
       (nepal_deaths/total_deaths)*100 AS nepal_death_rate,
       (nepal_recovered/total_recoveries)*100 AS nepal_recovered_rate
       FROM Nepal_data, Region_Total
;

-- 16 Which factors (new cases, deaths, recoveries) had the most significant weekly changes in Nepal?

WITH  Weekly_changes AS (
   SELECT Country, (one_week_change/confirmed_last_week)*100 AS cases_weekly_change,
   (new_deaths/confirmed_last_week)*100 AS death_weekly_change,
   (new_recovered/confirmed_last_week)*100 AS recovered_weekly
   FROM country_wise
   WHERE Country = 'Nepal' AND confirmed_last_week > 0
)
SELECT 
     Country, cases_weekly_change,
     death_weekly_change,
     recovered_weekly,
     GREATEST(cases_weekly_change, death_weekly_change,recovered_weekly) AS Max_change
FROM Weekly_changes;   

-- 17 How successful has Nepal been in reducing active cases compared to its growth in confirmed cases?
WITH Nepal_Analysis AS (
    SELECT 
        Country,
        weekly_percentage_growth AS Confirmed_Growth_rate, 
        ((Active - (confirmed_last_week-Deaths-Recovered)) / Active) * 100 AS Active_Cases_Reduction_rate
    FROM country_wise
    WHERE Country = 'Nepal' AND Active > 0 AND Confirmed>0
)
SELECT 
    Country,
    Confirmed_Growth_rate,
    Active_Cases_Reduction_rate,
    CASE 
        WHEN Active_Cases_Reduction_rate > Confirmed_Growth_rate THEN 'Success in Reducing Active Cases'
        ELSE 'Active Cases Reduction Lags Behind Growth'
    END AS Success_Indicator
FROM Nepal_Analysis;
  