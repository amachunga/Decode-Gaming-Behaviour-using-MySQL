DECODE GAMING BEHAVIOUR
Q1. 
/* Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0. */
SELECT level_details.P_ID, level_details.Dev_ID, player_details.PName, level_details.Difficulty
FROM game_analysis.level_details
JOIN game_analysis.player_details
ON level_details.P_ID = player_details.P_ID
WHERE Level = 0;

Q2. 
/* Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3 stages are crossed. */
SELECT player_details.L1_code, ROUND(AVG(level_details.Kill_Count),2) AS Kill_Count
FROM player_details
LEFT JOIN level_details
ON level_details.P_ID = player_details.P_ID
WHERE Lives_Earned = 2 AND Stages_crossed >=3
GROUP BY L1_code;

Q3.
/* Find the total number of stages crossed at each difficulty level for Level 2 with players using `zm_series` devices. Arrange the result in decreasing order of the total number of stages crossed. */
SELECT SUM(level_details.Stages_crossed) AS Total_Num_of_Stages_Crossed , Dev_ID, level_details.Difficulty
FROM level_details
WHERE Level = 2 AND Dev_ID LIKE 'zm%'
GROUP BY Difficulty, DEV_ID
ORDER BY Total_Num_of_Stages_Crossed DESC;

Q4.
/* Extract `P_ID` and the total number of unique dates for those players who have played games on multiple days. */
SELECT level_details.P_ID, COUNT(DISTINCT level_details.Start_time) AS Total_Num_of_Unique_Dates
FROM level_details
GROUP BY P_ID
HAVING COUNT(DISTINCT level_details.Start_time) > 1;

Q5.
/* Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than the average kill count for Medium difficulty. */
SELECT level_details.P_ID, Level, SUM(level_details.Kill_Count) AS Total_Kill_Count
FROM level_details
WHERE Kill_Count > ( SELECT AVG(level_details.Kill_Count) AS Average_Kill_Count
FROM level_details
WHERE Difficulty = 'Medium')
GROUP BY P_ID, Level
ORDER BY P_ID;

Q6.
/* Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level 0. Arrange in ascending order of level. */
SELECT level_details.Level, COALESCE(player_details.L1_code, player_details.L2_code) AS Level_Code, SUM(level_details.Lives_Earned) AS Total_Lives_Earned
FROM level_details
LEFT JOIN player_details
ON level_details.P_ID = player_details.P_ID
WHERE Level != 0
GROUP BY Level, L1_code, L2_code
ORDER BY Level;

Q7.
/* Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well */
WITH Top_Scores AS (
	SELECT Score, Dev_ID, Difficulty, ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score DESC) AS Ranking
	FROM level_details
)
SELECT Score, Dev_ID, Difficulty, Ranking
FROM Top_Scores
WHERE Ranking <= 3;

Q8.
/* Find the `first_login` datetime for each device ID. */
SELECT MIN(CAST(Start_time AS DATETIME)) AS First_login, Dev_ID
FROM level_details
GROUP BY Dev_ID;

Q9.
/* Find the top 5 scores based on each difficulty level and rank them in increasing order using `Rank`. Display `Dev_ID` as well. */
WITH Top_Scores AS(
	SELECT Dev_ID, Score, Difficulty, RANK() OVER (PARTITION BY Difficulty ORDER BY Score DESC) AS Ranking
    FROM level_details
)
SELECT Dev_ID, Score, Difficulty, Ranking
FROM Top_Scores
WHERE Ranking <=5;

Q10.
/*Find the device ID that is first logged in (based on `start_datetime`) for each player (`P_ID`). Output should contain player ID, device ID, and first login datetime.*/
SELECT P_ID, Dev_ID, MIN(CAST(Start_time AS DATETIME)) AS First_Login
FROM level_details
GROUP BY P_ID, Dev_ID;

Q11.
/* For each player and date, determine how many `kill_counts` were played by the player so far. 
a) Using window functions 
b) Without window functions */
a.	# With Window Function

SELECT P_ID, DATE(Start_time) AS DATE, SUM(Kill_Count) OVER (PARTITION BY P_ID ORDER BY Start_time) AS Total_Kill_Counts
FROM level_details;

b.	# Without Window Function
SELECT P_ID, DATE(Start_time) AS Date, SUM(Kill_Count) AS Total_Kill_Counts
FROM level_details
GROUP BY P_ID, Date;


Q12.
/* Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`. */
WITH Stages_crossed AS (
	SELECT P_ID, Start_time, Stages_crossed, SUM(Stages_crossed) OVER ( PARTITION BY P_ID ORDER BY Start_time ASC) AS Cumulative_Sum_of_Stages_Crossed,
    ROW_NUMBER() OVER ( PARTITION BY P_ID ORDER BY Start_time ASC) AS Row_Num
	FROM level_details
)
SELECT P_ID, Start_time, Stages_crossed, Cumulative_Sum_of_Stages_Crossed
FROM Stages_crossed
WHERE Row_Num > 1;


Q13.
/* Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`. */
WITH Top_scores AS (
	SELECT P_ID, DEV_ID, SUM(Score) OVER ( PARTITION BY DEV_ID ORDER BY Score DESC) AS Total_Scores,
    RANK() OVER ( PARTITION BY DEV_ID ORDER BY Score) AS Ranking
    FROM level_details
)
SELECT P_ID, DEV_ID, Total_Scores
FROM Top_scores
WHERE Ranking <=3;

Q14.
/* Find players who scored more than 50% of the average score, scored by the sum of scores for each `P_ID`. */
SELECT P_ID, ROUND(AVG(Score),0) AS Average_Score, SUM(Score) AS Total_Score
FROM level_details
GROUP BY P_ID
HAVING Total_Score > Average_Score * 0.5
ORDER BY P_ID;

Q15.
/* Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID` and rank them in increasing order using `Row_Number`. Display the difficulty as well. */
DELIMITER //
CREATE PROCEDURE Top_n_headshots(IN n INT)
BEGIN
	SELECT Dev_ID, Difficulty, Headshots_Count,
    ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_Count ASC) AS Score_Rank
    FROM level_details
    ORDER BY Dev_ID, Score_Rank LIMIT n;
END
DELIMITER ;
	

