SELECT * FROM dailyActivity_merged;
SELECT * FROM dailyCalories_merged;
SELECT * FROM dailyIntensities_merged;
SELECT * FROM dailySteps_merged;
SELECT * FROM sleepDay_merged;
SELECT * FROM weightLogInfo_merged;

/***Cleaning the Data***/

/**set to 2 decimal places**/

UPDATE dailyActivity_merged
SET TotalDistance = ROUND(TotalDistance, 2),
	TrackerDistance = ROUND(TrackerDistance, 2),
	LoggedActivitiesDistance = ROUND(LoggedActivitiesDistance, 2),
	VeryActiveDistance = ROUND(VeryActiveDistance, 2),
	ModeratelyActiveDistance = ROUND(ModeratelyActiveDistance, 2),
	LightActiveDistance = ROUND(LightActiveDistance, 2),
	SedentaryActiveDistance = ROUND(SedentaryActiveDistance, 2);

UPDATE dailyIntensities_merged
SET SedentaryActiveDistance = ROUND(SedentaryActiveDistance, 2),
	LightActiveDistance = ROUND(LightActiveDistance, 2),
	ModeratelyActiveDistance = ROUND(ModeratelyActiveDistance, 2),
	VeryActiveDistance = ROUND(VeryActiveDistance, 2);

UPDATE weightLogInfo_merged
SET WeightKg = ROUND(WeightKg, 2),
	WeightPounds = ROUND(WeightPounds, 2),
	BMI = ROUND(BMI, 2);

/***checking duplicates***/

/***dailyActivity_merged***/
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, ActivityDate
    FROM dailyActivity_merged
)d;

-- Compare to total rows
SELECT COUNT(*) AS TotalRows
FROM dailyActivity_merged;


/***dailyCalories_merged***/
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, ActivityDay
    FROM dailyCalories_merged
)d;

-- Compare to total rows
SELECT COUNT(*) AS TotalRows
FROM dailyCalories_merged;


/***dailyIntensities_merged***/
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, ActivityDay
    FROM dailyIntensities_merged
)d;

-- Compare to total rows
SELECT COUNT(*) AS TotalRows
FROM dailyIntensities_merged;

/***dailySteps_merged***/
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, ActivityDay
    FROM dailySteps_merged
)d;

-- Compare to total rows
SELECT COUNT(*) AS TotalRows
FROM dailySteps_merged;


/***sleepDay_merged***/
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, SleepDay
    FROM sleepDay_merged
)d;

-- Compare to total rows
SELECT COUNT(*) AS TotalRows
FROM sleepDay_merged;

-- List each (Id, SleepDate) that appears more than once
SELECT
  Id,
  CONVERT(DATE, SleepDay, 101) AS SleepDate,
  COUNT(*) AS DuplicateCount
FROM sleepDay_merged
GROUP BY
  Id, CONVERT(DATE, SleepDay, 101)
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC, Id, SleepDate;

-- All rows that belong to duplicated (Id, SleepDate) keys
SELECT s.*
FROM sleepDay_merged s
JOIN (
  SELECT Id, CONVERT(DATE, SleepDay, 101) AS SleepDate
  FROM sleepDay_merged
  GROUP BY Id, CONVERT(DATE, SleepDay, 101)
  HAVING COUNT(*) > 1
) d
  ON s.Id = d.Id
 AND CONVERT(DATE, s.SleepDay, 101) = d.SleepDate
ORDER BY s.Id, CONVERT(DATE, s.SleepDay, 101), s.TotalMinutesAsleep DESC;

--deleting duplicates
;WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY Id, CONVERT(DATE, SleepDay, 101)
               ORDER BY TotalMinutesAsleep DESC   -- keep the row with most sleep
           ) AS rn
    FROM sleepDay_merged
)
DELETE FROM ranked
WHERE rn > 1;

 --Recheck after removing duplicate
SELECT COUNT(*) AS TotalRows FROM sleepDay_merged;
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, CONVERT(DATE, SleepDay, 101) AS SleepDate
    FROM sleepDay_merged
) AS d;

/***weightLogInfo_merged***/
SELECT COUNT(*) AS UniqueRows
FROM (
    SELECT DISTINCT Id, Date
    FROM weightLogInfo_merged
)d;

-- Compare to total rows
SELECT COUNT(*) AS TotalRows
FROM weightLogInfo_merged;


/*****************************Analysis*****************************/

/******Engagement & Adoption******/
--1. How many active users and days of data do we have?
SELECT COUNT(DISTINCT Id) AS Users,
       COUNT(*)            AS UserDays
FROM dailyActivity_merged;

--2.	What % of days meet the 10,000-steps goal? (overall + by user)
-- Overall
SELECT 100.00 * SUM(CASE WHEN a.TotalSteps >= 10000 THEN 1 ELSE 0 END) / COUNT(*) AS PctDays_10k
FROM dbo.dailyActivity_merged a;

-- By user (top/bottom)
SELECT Id,
       AVG(CASE WHEN TotalSteps >= 10000 THEN 1.0 ELSE 0 END) AS PctDays_10k
FROM dbo.dailyActivity_merged
GROUP BY Id
ORDER BY PctDays_10k DESC;

--3. Which weekday is most/least active (steps)?
SELECT DATENAME(WEEKDAY, ActivityDate) AS Weekday,
       AVG(CAST(TotalSteps AS FLOAT))  AS AvgSteps
FROM dbo.dailyActivity_merged
GROUP BY DATENAME(WEEKDAY, ActivityDate), DATEPART(WEEKDAY, ActivityDate)
ORDER BY DATEPART(WEEKDAY, ActivityDate);


/******Activity, Calories & Intensity******/
--4. What’s the relationship between steps and calories?
SELECT
  (SUM( (a.TotalSteps*1.0 - s.avgS) * (c.Calories*1.0 - cc.avgC) )
   / NULLIF(
       SQRT( SUM( SQUARE(a.TotalSteps*1.0 - s.avgS) )
           * SUM( SQUARE(c.Calories*1.0 - cc.avgC) ) ), 0)
  ) AS Corr_StepsCalories
FROM (
  SELECT AVG(a2.TotalSteps*1.0) AS avgS
  FROM dailyActivity_merged a2
) s
CROSS JOIN (
  SELECT AVG(c2.Calories*1.0) AS avgC
  FROM dailyCalories_merged c2
) cc
JOIN dailyActivity_merged a
  ON 1 = 1
JOIN dailyCalories_merged c
  ON c.Id = a.Id
 AND CONVERT(date, c.ActivityDay, 101) = a.ActivityDate
WHERE a.TotalSteps IS NOT NULL
  AND c.Calories   IS NOT NULL;


--5. Do days ≥10k steps burn more calories than <10k?
SELECT 
    CASE WHEN a.TotalSteps >= 10000 THEN '≥10k steps' ELSE '<10k steps' END AS StepBucket,
    COUNT(*) AS TotalDays,
    AVG(c.Calories*1.0) AS AvgCalories
FROM dailyActivity_merged a
JOIN dailyCalories_merged c
  ON c.Id = a.Id 
 AND c.ActivityDay = a.ActivityDate
GROUP BY CASE WHEN a.TotalSteps >= 10000 THEN '≥10k steps' ELSE '<10k steps' END;



--6. Which intensity contributes most on high-calorie days?
SELECT TOP 10 a.Id, a.ActivityDate, c.Calories,
       i.VeryActiveMinutes, i.FairlyActiveMinutes, i.LightlyActiveMinutes, i.SedentaryMinutes
FROM dailyActivity_merged a
JOIN dailyCalories_merged c ON c.Id=a.Id AND c.ActivityDay=a.ActivityDate
JOIN dailyIntensities_merged i ON i.Id=a.Id AND i.ActivityDay=a.ActivityDate
ORDER BY c.Calories DESC;


/******Sleep & Recovery******/
--7. Does more sleep correlate with more steps next day?
SELECT
  CAST(SLEEP.TotalMinutesAsleep AS FLOAT) AS MinutesAsleep,
  CAST(ACT.TotalSteps AS FLOAT)           AS Steps
FROM sleepDay_merged SLEEP
JOIN dailyActivity_merged ACT
  ON ACT.Id = SLEEP.Id
 AND ACT.ActivityDate = SLEEP.SleepDay;   -- dates aligned earlier


-- Correlation between sleep minutes and NEXT-DAY steps
SELECT
  (SUM( (s.MinAsleep - m.avgSleep) * (a.Steps - n.avgSteps) )
   / NULLIF(
       SQRT( SUM( SQUARE(s.MinAsleep - m.avgSleep) )
           * SUM( SQUARE(a.Steps - n.avgSteps) ) ), 0)
  ) AS Corr_Sleep_vs_NextDaySteps
FROM (
  SELECT Id,
         CONVERT(date, SleepDay, 101) AS SleepDate,
         CAST(TotalMinutesAsleep AS float) AS MinAsleep
  FROM sleepDay_merged
) s
JOIN (
  SELECT Id,
         ActivityDate,
         CAST(TotalSteps AS float) AS Steps
  FROM dailyActivity_merged
) a
  ON a.Id = s.Id
 AND a.ActivityDate = DATEADD(day, 1, s.SleepDate)  -- <-- next day
CROSS JOIN ( SELECT AVG(CAST(TotalMinutesAsleep AS float)) AS avgSleep FROM sleepDay_merged ) m
CROSS JOIN ( SELECT AVG(CAST(TotalSteps AS float))          AS avgSteps FROM dailyActivity_merged ) n
WHERE s.MinAsleep IS NOT NULL
  AND a.Steps     IS NOT NULL;

--8. Sleep efficiency = minutes asleep / time in bed
SELECT AVG(1.0 * TotalMinutesAsleep / NULLIF(TotalTimeInBed,0)) AS AvgSleepEfficiency
FROM sleepDay_merged;

-- By user
SELECT Id,
       AVG(1.0 * TotalMinutesAsleep / NULLIF(TotalTimeInBed,0)) AS AvgSleepEfficiency
FROM sleepDay_merged
GROUP BY Id
ORDER BY AvgSleepEfficiency DESC;


--9. Segment users by average daily steps
WITH per_user AS (
  SELECT Id, AVG(CAST(TotalSteps AS FLOAT)) AS AvgSteps
  FROM dailyActivity_merged
  GROUP BY Id
)
SELECT CASE
         WHEN AvgSteps < 5000 THEN 'Low (<5k)'
         WHEN AvgSteps < 10000 THEN 'Moderate (5k-10k)'
         ELSE 'High (>=10k)'
       END AS Segment,
       COUNT(*) AS Users
FROM per_user
GROUP BY CASE
         WHEN AvgSteps < 5000 THEN 'Low (<5k)'
         WHEN AvgSteps < 10000 THEN 'Moderate (5k-10k)'
         ELSE 'High (>=10k)'
       END
ORDER BY Users DESC;




/******Segmentation & Consistency******/
--10. Who is most consistent (lowest std dev of steps)?
WITH stats AS (
  SELECT Id,
         AVG(CAST(TotalSteps AS FLOAT)) AS meanS,
         STDEV(CAST(TotalSteps AS FLOAT)) AS sdS
  FROM dailyActivity_merged
  GROUP BY Id
)
SELECT TOP 10 Id, meanS, sdS
FROM stats
ORDER BY sdS ASC;   -- lowest variation = most consistent


--11. Weekly trend of steps and calories
SELECT DATEFROMPARTS(YEAR(ActivityDate), MONTH(ActivityDate), 1) AS MonthStart,
       DATEPART(WEEK, ActivityDate) AS WeekNum,
       AVG(CAST(a.TotalSteps AS FLOAT)) AS AvgSteps,
       AVG(CAST(c.Calories AS FLOAT))   AS AvgCalories
FROM dailyActivity_merged a
JOIN dailyCalories_merged c
  ON c.Id=a.Id AND c.ActivityDay=a.ActivityDate
GROUP BY DATEFROMPARTS(YEAR(ActivityDate), MONTH(ActivityDate), 1),
         DATEPART(WEEK, ActivityDate)
ORDER BY MonthStart, WeekNum;


--12. Do users who log their weight consistently show better activity engagement (more steps) than those who rarely log?
WITH weight_logs AS (
  SELECT
    w.Id,
    CONVERT(date, w.[Date], 101) AS LogDate
  FROM weightLogInfo_merged w
),
log_counts AS (
  SELECT
    wl.Id,
    COUNT(*) AS LogCount
  FROM weight_logs wl
  GROUP BY wl.Id
),
all_users AS (
  SELECT DISTINCT Id FROM dailyActivity_merged
),
user_bucket AS (
  SELECT
    u.Id,
    COALESCE(lc.LogCount, 0) AS LogCount,
    CASE
      WHEN COALESCE(lc.LogCount, 0) = 0 THEN 'None'
      WHEN COALESCE(lc.LogCount, 0) BETWEEN 1 AND 2 THEN 'Rare (1–2)'
      WHEN COALESCE(lc.LogCount, 0) BETWEEN 3 AND 5 THEN 'Occasional (3–5)'
      ELSE 'Frequent (6+)'
    END AS WeightLogBucket
  FROM all_users u
  LEFT JOIN log_counts lc ON lc.Id = u.Id
),
user_steps AS (
  SELECT
    a.Id,
    AVG(CAST(a.TotalSteps AS float)) AS AvgDailySteps
  FROM dailyActivity_merged a
  GROUP BY a.Id
)
SELECT
  b.WeightLogBucket,
  COUNT(*)                                 AS Users,
  AVG(us.AvgDailySteps)                    AS AvgDailySteps_perUser,
  MIN(us.AvgDailySteps)                    AS MinAvgSteps_user,
  MAX(us.AvgDailySteps)                    AS MaxAvgSteps_user
FROM user_bucket b
JOIN user_steps us ON us.Id = b.Id
GROUP BY b.WeightLogBucket
ORDER BY
  CASE b.WeightLogBucket
    WHEN 'None' THEN 1
    WHEN 'Rare (1–2)' THEN 2
    WHEN 'Occasional (3–5)' THEN 3
    ELSE 4
  END;




 --13. Do users who start logging weight maintain or increase their average daily steps over the following month?
  WITH weight_logs AS (
  SELECT
    w.Id,
    CONVERT(date, w.[Date], 101) AS LogDate
  FROM weightLogInfo_merged w
),
first_log AS (
  SELECT Id, MIN(LogDate) AS FirstLogDate
  FROM weight_logs
  GROUP BY Id
),
steps_before AS (
  SELECT
    a.Id,
    AVG(CAST(a.TotalSteps AS float)) AS AvgSteps_Before30
  FROM dailyActivity_merged a
  JOIN first_log f ON f.Id = a.Id
  WHERE a.ActivityDate >= DATEADD(day, -30, f.FirstLogDate)
    AND a.ActivityDate <  f.FirstLogDate
  GROUP BY a.Id
),
steps_after AS (
  SELECT
    a.Id,
    AVG(CAST(a.TotalSteps AS float)) AS AvgSteps_After30
  FROM dailyActivity_merged a
  JOIN first_log f ON f.Id = a.Id
  WHERE a.ActivityDate >= f.FirstLogDate
    AND a.ActivityDate <  DATEADD(day, 30, f.FirstLogDate)
  GROUP BY a.Id
),
paired AS (
  SELECT
    f.Id,
    f.FirstLogDate,
    sb.AvgSteps_Before30,
    sa.AvgSteps_After30,
    (sa.AvgSteps_After30 - sb.AvgSteps_Before30) AS DeltaSteps
  FROM first_log f
  LEFT JOIN steps_before sb ON sb.Id = f.Id
  LEFT JOIN steps_after  sa ON sa.Id = f.Id
)
SELECT
  COUNT(*)                                           AS Users_With_WeightStart,
  SUM(CASE WHEN DeltaSteps IS NOT NULL AND DeltaSteps > 0 THEN 1 ELSE 0 END)           AS Users_Increased,
  SUM(CASE WHEN DeltaSteps IS NOT NULL AND DeltaSteps < 0 THEN 1 ELSE 0 END)           AS Users_Decreased,
  SUM(CASE WHEN DeltaSteps IS NOT NULL AND DeltaSteps = 0 THEN 1 ELSE 0 END)           AS Users_NoChange,
  AVG(DeltaSteps)                                   AS Avg_Step_Change_30d,
  AVG(AvgSteps_Before30)                            AS AvgSteps_Before30_perUser,
  AVG(AvgSteps_After30)                             AS AvgSteps_After30_perUser
FROM paired
WHERE AvgSteps_Before30 IS NOT NULL
  AND AvgSteps_After30  IS NOT NULL;