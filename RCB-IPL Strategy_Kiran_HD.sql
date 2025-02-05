-- SUBMISSION BY: KIRAN H D
-- PROJECT: IPL Strategy for RCB
-- BATCH: DATA SCIENCE COURSE OCTOBER 2024

use ipl ;

/*Objective Questions*/

-- 1.	List the different dtypes of columns in table “ball_by_ball” (using information schema)

SELECT  COLUMN_NAME, DATA_TYPE 
FROM  INFORMATION_SCHEMA.COLUMNS 
WHERE  TABLE_NAME = 'ball_by_ball';
    
-- 2.	What is the total number of runs scored in 1st season by RCB 
--      (bonus: also include the extra runs using the extra runs table)

with Total_Run as(
select m.Match_Id, bb.Runs_Scored, er.Extra_Runs
from matches m
join team t on t.Team_Id=m.Team_1 or t.Team_Id=m.Team_2
join ball_by_ball bb on m.Match_Id= bb.Match_Id
left join extra_runs er on bb.Match_Id=er.Match_Id and bb.Over_Id=er.Over_Id and bb.Ball_Id=er.Ball_Id
where t.Team_Id=2 and m.Season_Id=6 and bb.Team_Batting=t.Team_Id)
select sum(COALESCE(Runs_Scored,0))+sum(COALESCE(Extra_Runs,0)) as Total_Run_By_RCB
from Total_Run

select * from extra_runs
select * from ball_by_ball 
select*from season
select * from matches 
select * from team 
select * from extra_runs



-- 3.  How many players were more than the age of 25 during season 2014? 

SELECT COUNT(DISTINCT pm.Player_Id) AS Players_Over_25
FROM player_match pm
JOIN matches m ON pm.Match_Id = m.Match_Id
JOIN player p ON pm.Player_Id = p.Player_Id
WHERE m.Match_Date like '2014%' 
&& TIMESTAMPDIFF(YEAR, p.DOB, m.Match_Date) > 25;


-- 4.	How many matches did RCB win in 2013? 

SELECT COUNT(*) AS RCB_Wins
FROM  matches m
JOIN team t on m.match_winner= t.team_id
WHERE m.Match_Date like '2013%'
 && t.team_name ='Royal Challengers Bangalore'; 

-- 5.	List the top 10 players according to their strike rate in the last 4 seasons
SELECT p.Player_Name, SUM(bb.Runs_Scored) AS Total_runs,
       COUNT(bb.Ball_Id) AS Balls_Faced,
       (SUM(bb.Runs_Scored) / COUNT(bb.Ball_Id))*100 AS Strike_rate
FROM player p
INNER JOIN ball_by_ball bb ON bb.Striker = p.Player_Id
INNER JOIN matches m ON m.Match_Id = bb.Match_Id
INNER JOIN season s ON s.Season_Id = m.Season_Id
WHERE s.Season_Id IN (SELECT Season_Id 
					  FROM ( SELECT Season_Id 
							 FROM season
							 ORDER BY Season_Year DESC
							 LIMIT 4 ) AS XYZ
						)
GROUP BY Player_Id, Player_Name
HAVING COUNT(bb.Ball_Id) > 0
ORDER BY Strike_rate DESC
LIMIT 10;

-- 6.	What are the average runs scored by each batsman considering all the seasons?

SELECT p.Player_Name, SUM(bb.Runs_Scored) AS Total_Runs, 
    COUNT(DISTINCT CONCAT(bb.Match_Id, bb.Innings_No)) AS Innings_Played,
    ROUND(SUM(bb.Runs_Scored) / COUNT(DISTINCT CONCAT(bb.Match_Id, bb.Innings_No)), 2) AS Average_Runs
FROM ball_by_ball bb 
JOIN player p ON bb.Striker = p.Player_Id
GROUP BY p.Player_Name
ORDER BY Average_Runs DESC;

-- 7.	What are the average wickets taken by each bowler considering all the seasons?

SELECT p.Player_Name,
    COUNT(bb.Bowler) AS Wickets,  
    COUNT(bb.Bowler) / NULLIF(COUNT(DISTINCT bb.Match_Id), 0) AS Average_Wickets
FROM ball_by_ball bb
 JOIN player p ON bb.Bowler = p.Player_Id
 WHERE bb.Runs_Scored = 0  
GROUP BY p.Player_Name
ORDER BY Average_Wickets DESC;
    
    
-- 8.	List all the players who have average runs scored greater than the overall average 
--            and who have taken wickets greater than the overall average.
WITH OverallAverages AS (
    SELECT AVG(Runs_Scored) AS Overall_Avg_Runs, AVG(Wickets_Taken) AS Overall_Avg_Wickets
    FROM ( SELECT AVG(bb.Runs_Scored) AS Runs_Scored, COUNT(wt.Player_Out) AS Wickets_Taken
		   FROM player p
		   LEFT JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
           LEFT JOIN wicket_taken wt ON wt.Match_Id = bb.Match_Id AND wt.Over_Id = bb.Over_Id AND wt.Ball_Id = bb.Ball_Id
           GROUP BY p.Player_Id ) AS PlayerAverages
)
SELECT p.Player_Name, pa.Avg_Runs, pa.Total_Wickets
FROM player p
INNER JOIN ( SELECT p.Player_Id, AVG(bb.Runs_Scored) AS Avg_Runs, COUNT(wt.Player_Out) AS Total_Wickets
			 FROM player p
             LEFT JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
			 LEFT JOIN wicket_taken wt ON wt.Match_Id = bb.Match_Id AND wt.Over_Id = bb.Over_Id AND wt.Ball_Id = bb.Ball_Id
             GROUP BY p.Player_Id ) pa ON p.Player_Id = pa.Player_Id
INNER JOIN OverallAverages oa ON pa.Avg_Runs > oa.Overall_Avg_Runs AND pa.Total_Wickets > oa.Overall_Avg_Wickets;
    

-- 9.	Create a table rcb_record table that shows the wins and losses of RCB in an individual venue.

create table rcb_record 
		(venue_name varchar(100),
		 wins int,
		 losses int);
        insert into rcb_record (venue_name,wins,losses)
               (select v.venue_name,
			   count(case when m.match_winner=t.team_id then 1 end) as wins,
               count(case when m.match_winner<>t.team_id then 1 end) as losses
		from venue v join matches m on v.venue_id=m.venue_id 
		join team t on m.team_1=t.team_id or m.team_2=t.team_id 
		where t.team_name='Royal Challengers Bangalore'
		group by v.venue_name);
   
   select * from rcb_record;
    


-- 10.	What is the impact of bowling style on wickets taken? 

SELECT bs.Bowling_skill, COUNT(wt.Player_Out) AS Wickets_Taken
FROM player p
INNER JOIN bowling_style bs ON p.Bowling_skill = bs.Bowling_Id
INNER JOIN ball_by_ball bbb ON p.Player_Id = bbb.Bowler
INNER JOIN wicket_taken wt ON bbb.Match_Id = wt.Match_Id 
AND bbb.Over_Id = wt.Over_Id AND bbb.Ball_Id = wt.Ball_Id
GROUP BY bs.Bowling_skill
ORDER BY Wickets_Taken DESC;

-- 11.	Write the SQL query to provide a status of whether the performance of the team is better than the previous year's performance on the basis of the number of runs scored by the team in the season and the number of wickets taken

WITH TeamPerformance AS ( SELECT t.Team_Name, s.Season_Year, SUM(bb.Runs_Scored) AS TotalRuns, COUNT(wt.Player_Out) AS TotalWickets
    FROM team t
    LEFT JOIN player_match pm ON t.Team_Id = pm.Team_Id
     JOIN matches m ON pm.Match_Id = m.Match_Id
     JOIN season s ON m.Season_Id = s.Season_Id
     JOIN (SELECT Match_Id, SUM(Runs_Scored) AS Runs_Scored FROM ball_by_ball GROUP BY Match_Id) bb ON m.Match_Id = bb.Match_Id
     JOIN (SELECT Match_Id, COUNT(Player_Out) AS Player_Out FROM wicket_taken GROUP BY Match_Id) wt ON m.Match_Id = wt.Match_Id
    GROUP BY t.Team_Name, s.Season_Year
    
)
,TeamPerformanceStatus AS (SELECT t1.Team_Name,t1.Season_Year AS Previous_Year,t1.TotalRuns AS Previous_Runs,t2.Season_Year AS Current_Year,
           t2.TotalRuns AS Current_Runs,t1.TotalWickets AS Previous_Wickets,t2.TotalWickets AS Current_Wickets,
           CASE
               WHEN t2.TotalRuns > t1.TotalRuns AND t2.TotalWickets > t1.TotalWickets THEN 'Better'
               WHEN t2.TotalRuns = t1.TotalRuns AND t2.TotalWickets = t1.TotalWickets THEN 'Same'
               WHEN t2.TotalRuns > t1.TotalRuns AND t2.TotalWickets < t1.TotalWickets THEN 'Mixed'
               WHEN t2.TotalRuns < t1.TotalRuns AND t2.TotalWickets > t1.TotalWickets THEN 'Mixed'
               ELSE 'Worse'
           END AS Performance_Status
    FROM TeamPerformance t1
    INNER JOIN TeamPerformance t2 ON t1.Team_Name = t2.Team_Name  AND t1.Season_Year = t2.Season_Year - 1
)
SELECT *
FROM TeamPerformanceStatus
ORDER BY t1.Team_Name; 

-- 12.	Can you derive more KPIs for the team strategy? 
  
            -- 1. Top Order Contribution 
    
  WITH Top_Order_Stats AS (
    SELECT m.Match_Id, t.Team_Name, SUM(bb.Runs_Scored) AS Top_Order_Runs, TotalRuns.Match_Total_Runs
    FROM matches m
    INNER JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
    INNER JOIN team t ON t.Team_Id = bb.Team_Batting
    INNER JOIN (SELECT Match_Id, SUM(Runs_Scored) AS Match_Total_Runs 
                FROM ball_by_ball GROUP BY Match_Id) AS TotalRuns ON m.Match_Id = TotalRuns.Match_Id
    WHERE bb.Striker_Batting_Position <= 3
    GROUP BY m.Match_Id, t.Team_Name, TotalRuns.Match_Total_Runs
)
SELECT Team_Name, AVG((Top_Order_Runs / Match_Total_Runs) * 100) AS Avg_Top_Order_Contribution
FROM Top_Order_Stats
GROUP BY Team_Name
ORDER BY Avg_Top_Order_Contribution DESC;
 
             -- 2. Boundary Frequency 
  
  SELECT p.Player_Name,
       ROUND(SUM(CASE WHEN bb.Runs_Scored IN (4, 6) THEN 1 ELSE 0 END) / COUNT(bb.Ball_Id) * 100, 2) AS Player_Boundary_Frequency
FROM player p
INNER JOIN ball_by_ball bb ON p.Player_Id = bb.Striker
GROUP BY p.Player_Name
ORDER BY Player_Boundary_Frequency DESC
LIMIT 10;
 
               -- 3. Powerplay Performance 
               
WITH Powerplay_Data AS (
    SELECT m.Match_Id,bb.Team_Batting,SUM(bb.Runs_Scored) AS Powerplay_Runs,COUNT(wt.Player_Out) AS Wickets_Lost
    FROM matches m
    INNER JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
    LEFT JOIN wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id
    WHERE bb.Over_Id <= 6
    GROUP BY m.Match_Id,bb.Team_Batting
)
SELECT t.Team_Name,AVG(pd.Powerplay_Runs) AS Avg_Powerplay_Runs,AVG(pd.Wickets_Lost) AS Avg_Wickets_Lost,
    AVG(pd.Powerplay_Runs) / AVG(pd.Wickets_Lost) AS Run_to_Wicket_Ratio
FROM Powerplay_Data pd
INNER JOIN team t ON pd.Team_Batting = t.Team_Id
GROUP BY t.Team_Name
ORDER BY Avg_Powerplay_Runs DESC;
               
      -- 4. Death Over Efficiency
      
      WITH Death_Over_Player_Data AS (
    SELECT p.Player_Name, t.Team_Name, SUM(bb.Runs_Scored + COALESCE(er.Extra_Runs, 0)) AS Runs_In_Death,
        COUNT(wt.Player_Out) AS Wickets_Taken
    FROM matches m
    INNER JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
    LEFT JOIN extra_runs er ON bb.Match_Id = er.Match_Id AND bb.Over_Id = er.Over_Id AND bb.Ball_Id = er.Ball_Id
    LEFT JOIN wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id
    INNER JOIN player p ON p.Player_Id = bb.Striker
    INNER JOIN team t ON t.Team_Id = bb.Team_Batting
    WHERE bb.Over_Id > (SELECT MAX(Over_Id) FROM ball_by_ball WHERE Match_Id = m.Match_Id) - 4
    GROUP BY p.Player_Name, t.Team_Name
)

SELECT Player_Name, Team_Name, Runs_In_Death, Wickets_Taken
FROM Death_Over_Player_Data
ORDER BY Runs_In_Death DESC, Wickets_Taken DESC
LIMIT 10;
      
      -- 5. Win/Loss Ratio by Venue

SELECT t.Team_Name,v.Venue_Name,SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Wins,
    SUM(CASE WHEN m.Match_Winner != t.Team_Id AND (m.Team_1 = t.Team_Id OR m.Team_2 = t.Team_Id) THEN 1 ELSE 0 END) AS Losses,
    (SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) / COUNT(*)) AS Win_Loss_Ratio
FROM matches m
JOIN team t ON t.Team_Id IN (m.Team_1, m.Team_2)
JOIN venue v ON m.Venue_Id = v.Venue_Id
GROUP BY t.Team_Name,v.Venue_Name
ORDER BY Wins DESC,Losses ASC
LIMIT 20;
      
-- 13.	Using SQL, write a query to find out the average wickets taken by each bowler in each venue. 
--      Also, rank the gender according to the average value. 

WITH each_venue_BowlerWickets AS (
    SELECT bb.Bowler, p.Player_Name,v.venue_name,
        COUNT(DISTINCT bb.Match_Id, bb.Over_Id, bb.Ball_Id, bb.Innings_No) AS Total_Wickets,
        COUNT(DISTINCT bb.Match_Id, bb.Innings_No) AS Matches_Played
    FROM player p 
    JOIN player_match pm ON p.Player_Id = pm.Player_Id 
    JOIN matches m ON pm.Match_Id = m.Match_Id
    JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Bowler
    JOIN wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id 
                          AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY bb.Bowler, p.Player_Name, v.Venue_Name
)
SELECT Bowler AS Player_Id,Player_Name,Venue_Name,
    ROUND(Total_Wickets / Matches_Played, 1) AS Average_Wickets,
    DENSE_RANK() OVER (ORDER BY ROUND(Total_Wickets / Matches_Played, 1) DESC) AS 'Rank'
FROM each_venue_BowlerWickets
ORDER BY  Average_Wickets DESC, 'Rank' DESC;


-- 14.	Which of the given players have consistently performed well in past seasons? (will you use any visualization to solve the problem) 

SELECT p.Player_Id,p.Player_Name,s.Season_Year,SUM(bb.Runs_Scored) AS Total_Runs
FROM player p
JOIN player_match pm ON p.Player_Id = pm.Player_Id
JOIN matches m ON pm.Match_Id = m.Match_Id
JOIN ball_by_ball bb ON m.Match_Id = bb.Match_Id
JOIN season s ON m.Season_Id = s.Season_Id  -- Join with season table
WHERE pm.Role_Id = 1  -- Assuming Role_Id for batsmen is 1; adjust if necessary
GROUP BY p.Player_Id, p.Player_Name, s.Season_Year
ORDER BY p.Player_Name, s.Season_Year DESC;
 

-- 15.	Are there players whose performance is more suited to specific venues or conditions? (how would you present this using charts?) 

                -- The top 3 players in each venue scored the highest runs.

WITH result AS (
    SELECT p.Player_Id, p.Player_Name, v.Venue_Name, SUM(bb.Runs_Scored) AS Total_Runs
    FROM player p 
    JOIN player_match pm ON p.Player_Id = pm.Player_Id
    JOIN ball_by_ball bb ON pm.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Striker
    JOIN matches m ON bb.Match_Id = m.Match_Id
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN city c ON v.City_Id = c.City_Id
    JOIN country cc ON c.Country_Id = cc.Country_Id
    WHERE cc.Country_Name = 'India'
    GROUP BY p.Player_Id, p.Player_Name, v.Venue_Name
    ORDER BY Total_Runs DESC ),
rank_player AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY Venue_Name ORDER BY Total_Runs DESC) AS Top_Rank
    FROM result )
SELECT  * 
FROM rank_player
WHERE Top_Rank BETWEEN 1 AND 3
ORDER BY Top_Rank, Total_Runs DESC;


                 -- top 3 players in each venue taken highest wicket.
                 
WITH result AS (
    SELECT p.Player_Id,p.Player_Name,v.Venue_Name, COUNT(DISTINCT wt.Match_Id, wt.Innings_No, wt.Over_Id, wt.Ball_Id) AS Total_Wickets
    FROM player p
    JOIN player_match pm ON p.Player_Id = pm.Player_Id
    JOIN ball_by_ball bb ON pm.Match_Id = bb.Match_Id AND pm.Player_Id = bb.Bowler
    JOIN wicket_taken wt ON bb.Match_Id = wt.Match_Id AND bb.Over_Id = wt.Over_Id AND bb.Ball_Id = wt.Ball_Id AND bb.Innings_No = wt.Innings_No
    JOIN matches m ON wt.Match_Id = m.Match_Id
    JOIN venue v ON m.Venue_Id = v.Venue_Id
    JOIN season s ON m.Season_Id = s.Season_Id
    JOIN city c ON v.City_Id = c.City_Id
    JOIN country cc ON c.Country_Id = cc.Country_Id
    WHERE cc.Country_Name = 'India'
    GROUP BY p.Player_Id, p.Player_Name, v.Venue_Name
    ORDER BY Total_Wickets DESC ),
rank_player AS (
    SELECT *,DENSE_RANK() OVER (PARTITION BY Venue_Name ORDER BY Total_Wickets DESC) AS Top_Rank
    FROM Result )
SELECT  * 
FROM rank_player
WHERE Top_Rank BETWEEN 1 AND 3
ORDER BY Top_Rank, Total_Wickets DESC;




                                                    /*Subjective Questions*/
-- 1.	How does the toss decision affect the result of the match? (which visualizations could be used to present your answer better) And is the impact limited to only specific venues?

-- toss win match_win vs toss win match loss of all team
WITH union_table_1 AS (
    SELECT 1 AS number,COUNT(CASE WHEN team_1 = toss_winner AND toss_winner = match_winner THEN 1 END) AS toss_win_match_win
    FROM matches
    UNION ALL
    SELECT 1 AS number,COUNT(CASE WHEN team_2 = toss_winner AND toss_winner = match_winner THEN 1 END) AS toss_win_match_win
    FROM matches
),
rs1 AS (
    SELECT number,SUM(toss_win_match_win) AS toss_win_match_win
    FROM union_table_1
    GROUP BY number
),
union_table_2 AS (
    SELECT 1 AS number,COUNT(CASE WHEN team_1 = toss_winner AND toss_winner <> match_winner THEN 1 END) AS toss_win_match_loss
    FROM matches
    UNION ALL
    SELECT 1 AS number,COUNT(CASE WHEN team_2 = toss_winner AND toss_winner <> match_winner THEN 1 END) AS toss_win_match_loss
    FROM matches
),
rs2 AS (
    SELECT number,SUM(toss_win_match_loss) AS toss_win_match_loss
    FROM union_table_2
    GROUP BY number
)
SELECT rs1.*, rs2.toss_win_match_loss
FROM rs1
JOIN rs2 ON rs1.number = rs2.number;

 	-- Query: Toss wins and match win percentage of each team.
    
WITH match_winner_count AS (
    SELECT toss_winner,COUNT(*) AS match_win_count
    FROM matches
    WHERE toss_winner = match_winner
    GROUP BY toss_winner
    ORDER BY match_win_count DESC
),
toss_winner_count AS (
    SELECT toss_winner,COUNT(*) AS total_toss_win_count
    FROM matches
    GROUP BY toss_winner
)
SELECT t.team_name,mwc.match_win_count,twc.total_toss_win_count,
    ROUND((mwc.match_win_count / twc.total_toss_win_count) * 100, 1) AS toss_win_match_win_percentage
FROM match_winner_count mwc
JOIN toss_winner_count twc ON mwc.toss_winner = twc.toss_winner
JOIN team t ON mwc.toss_winner = t.team_id
ORDER BY toss_win_match_win_percentage DESC;

-- Query: match win percentage  after won toss in each venue 

WITH Toss_Win_Stats AS (
    SELECT v.Venue_Name, td.Toss_Name AS Toss_Decision, COUNT(*) AS Total_Matches,
        SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) AS Matches_Won_After_Toss,
        (SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN toss_decision td ON m.Toss_Decide = td.Toss_Id
    INNER JOIN venue v ON m.Venue_Id = v.Venue_Id
    GROUP BY v.Venue_Name, td.Toss_Name
)
SELECT Venue_Name, Toss_Decision, Total_Matches, Matches_Won_After_Toss, Win_Percentage
FROM Toss_Win_Stats
WHERE Total_Matches >= 10;

-- 2.	Suggest some of the players who would be best fit for the team 

 -- Query: Top 5 score rank in each season--players and number of times they are in the top 5 in the last 3 seasons.
WITH player_match_runs AS (SELECT bb.match_id,bb. striker,SUM(runs_scored) AS total_runs
    FROM ball_by_ball bb
    GROUP BY bb.match_id, bb.striker ),
result AS ( SELECT pmr. striker AS player_id,s.season_year,SUM(pmr.total_runs) AS runs_scored,
        DENSE_RANK() OVER (PARTITION BY season_year ORDER BY SUM(pmr.total_runs) DESC) AS season_runs_rank
    FROM player_match_runs pmr
    JOIN matches m ON pmr.match_id = m.match_id
    JOIN season s ON m.season_id = s.season_id
    GROUP BY pmr. striker, s.season_year ),
top_run_rank_player AS ( SELECT *
    FROM result
    WHERE season_runs_rank BETWEEN 1 AND 5 AND season_year BETWEEN 2014 AND 2016
    ORDER BY season_year, season_runs_rank )
SELECT trp.player_id,p.player_name,COUNT(trp.player_id) AS no_of_times_in_top5
FROM top_run_rank_player trp
JOIN player p ON trp.player_id = p.player_id
GROUP BY trp.player_id, p.player_name
ORDER BY COUNT(trp.player_id) DESC
LIMIT 10;

-- Query: Top 10 players with the highest strike rate and minimum 1500 runs scored.

with runs_scored as (select bb.striker,p.player_name,sum(bb.runs_scored) as total_runs
					from player p join player_match pm on p.player_id=pm.player_id
					join ball_by_ball bb on pm.player_id=bb.striker and pm.match_id=bb.match_id
					group by bb. striker,p.player_name having(sum(bb.runs_scored))>= 1500
                    order by total_runs desc),
balls_faced as (select bb.striker,p.player_name,count(bb.runs_scored)total_ball_faced
					from player p join player_match pm on p.player_id=pm.player_id
					join ball_by_ball bb on pm.player_id=bb.striker and pm.match_id=bb.match_id
					group by bb. striker,p.player_name order by total_ball_faced desc)
select rs.striker as player_id,rs.player_name,rs.total_runs,
       bf.total_ball_faced,(rs.total_runs/bf.total_ball_faced)*100 as strike_rate
from runs_scored rs join balls_faced bf on rs.striker=bf.striker
order by strike_rate desc
limit 10;

 	-- Query: Top 10 bowlers taken highest wicket.

select bb.bowler,p.player_name,count(wt.player_out) as number_of_wickets
from player p join player_match pm on p.player_id=pm.player_id
join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id
join wicket_taken wt on bb.match_id=wt.match_id and bb.over_id=wt.over_id
						and bb.ball_id=wt.ball_id and bb.innings_no=wt.innings_no
group by bb. bowler,p.player_name order by number_of_wickets desc
limit 10;

  -- Query: Top 10 bowlers with best economy, minimum 100 overs bowled.

with total_runs_conceeded as (select bb.bowler as player_id,p.player_name,sum(bb.runs_scored) as runs_conceeded 
							from player p join player_match pm on p.player_id=pm.player_id 
							join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id 
							group by bb.bowler,p.player_name order by runs_conceeded desc),
total_overs_bowled as (select bb.bowler as player_id,count(distinct bb.match_id,bb.innings_no,bb.over_id) as total_overs
						from player p join player_match pm on p.player_id=pm.player_id 
						join ball_by_ball bb on pm.player_id=bb.bowler and pm.match_id=bb.match_id 
						group by bb. bowler order by total_overs desc)
select trc.*,tob.total_overs,(trc.runs_conceeded/tob.total_overs) as economy
from total_runs_conceeded  trc join total_overs_bowled tob on trc.player_id=tob.player_id
where total_overs>100
order by economy limit 10;

-- 3.	What are some of the parameters that should be focused on while selecting the players? 

-- 4.	Which players offer versatility in their skills and can contribute effectively with both bat and ball? (can you visualize the data for the same) 


WITH top_bowler AS (SELECT bb. bowler, p.player_name, COUNT(wt.player_out) AS number_of_wickets
    FROM player p
    JOIN player_match pm ON p.player_id = pm.player_id
    JOIN ball_by_ball bb ON pm.player_id = bb. bowler AND pm.match_id = bb.match_id
    JOIN wicket_taken wt ON bb.match_id = wt.match_id 
        AND bb.over_id = wt.over_id AND bb.ball_id = wt.ball_id AND bb.innings_no = wt.innings_no
    GROUP BY bb. bowler, p.player_name
    ORDER BY number_of_wickets DESC ),
top_batsman AS (
    SELECT bb.striker, p.player_name, SUM(bb.runs_scored) AS total_runs
    FROM player p
    JOIN player_match pm ON p.player_id = pm.player_id
    JOIN ball_by_ball bb ON pm.player_id = bb. striker 
        AND pm.match_id = bb.match_id
    GROUP BY bb.striker, p.player_name
    ORDER BY total_runs DESC )
SELECT tb. bowler AS player_id, tb.player_name, tb.number_of_wickets, tbs.total_runs
FROM top_bowler tb
JOIN top_batsman tbs ON tb.bowler = tbs.striker
WHERE tb.number_of_wickets >= 12 AND tbs.total_runs > 500;


-- 5.	Are there players whose presence positively influences the morale and performance of the team? (justify your answer using visualization) 

WITH PlayerWinStats AS (
    SELECT p.Player_Name, pm.Team_Id, COUNT(m.Match_Id) AS Total_Matches, 
           SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) AS Matches_Won
    FROM player p
    INNER JOIN player_match pm ON p.Player_Id = pm.Player_Id
    INNER JOIN matches m ON pm.Match_Id = m.Match_Id
    WHERE m.Outcome_type = 1 -- considering only completed matches
    GROUP BY p.Player_Name, pm.Team_Id
)
,PlayerWinPercentage AS (
    SELECT pws.Player_Name, pws.Team_Id, pws.Total_Matches, pws.Matches_Won,
           (pws.Matches_Won / pws.Total_Matches) * 100 AS Win_Percentage
    FROM PlayerWinStats pws
    WHERE pws.Total_Matches > 5 -- consider players with more than 5 matches
)
SELECT pwp.Player_Name, t.Team_Name, pwp.Total_Matches, pwp.Matches_Won,pwp.Win_Percentage
FROM PlayerWinPercentage pwp
INNER JOIN team t ON pwp.Team_Id = t.Team_Id
ORDER BY Win_Percentage DESC
LIMIT 10;

-- win rate with player presence

SELECT pm.Player_Id, p.player_name,COUNT(DISTINCT m.Match_Id) AS Matches_Played,
       SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) AS Wins,
       (SUM(CASE WHEN m.Match_Winner = pm.Team_Id THEN 1 ELSE 0 END) / COUNT(DISTINCT m.Match_Id)) * 100 AS Win_Rate
FROM player_match pm
JOIN matches m ON pm.Match_Id = m.Match_Id
join player p on p.player_id=pm.player_id
GROUP BY pm.Player_Id,p.player_name
HAVING Matches_Played > 60
order by win_rate desc;  




-- 6.	What would you suggest to RCB before going to the mega auction? 

      -- Query- Players with the best average.
WITH player_runs AS (
    SELECT p.player_id,p.player_name,SUM(bb.runs_scored) AS total_runs
    FROM player p
    JOIN player_match pm ON p.player_id = pm.player_id
    JOIN ball_by_ball bb ON pm.match_id = bb.match_id AND pm.player_id = bb.striker
    GROUP BY p.player_id, p.player_name
    ORDER BY total_runs DESC
),
player_out AS ( SELECT p.player_id,p.player_name,COUNT(wt.player_out) AS number_of_times_out
    FROM player p
	JOIN wicket_taken wt ON p.player_id = wt.player_out
    GROUP BY p.player_id, p.player_name
)
SELECT  pr.*,po.number_of_times_out,ROUND(pr.total_runs / COALESCE(po.number_of_times_out, 1), 1) AS average_runs
FROM player_runs pr
LEFT JOIN player_out po ON pr.player_id = po.player_id
WHERE pr.total_runs >= 1500
ORDER BY average_runs DESC
LIMIT 10; 

    -- Players with the highest strike rate.

SELECT p.Player_Name, SUM(bb.Runs_Scored) AS Total_Runs,
    COUNT(bb.Ball_Id) AS Balls_Faced,
    (SUM(bb.Runs_Scored) / COUNT(bb.Ball_Id)) * 100 AS Strike_Rate
FROM player p
JOIN ball_by_ball bb ON p.Player_Id = bb.Striker  -- Assuming Striker column links to player
LEFT JOIN extra_runs er ON bb.Match_Id = er.Match_Id AND bb.Over_Id = er.Over_Id AND bb.Ball_Id = er.Ball_Id
JOIN player_match pm ON p.Player_Id = pm.Player_Id
WHERE pm.Team_Id = 1  -- Replace with actual Team_Id
    AND er.Extra_Type_Id IS NULL  -- Exclude extra deliveries like wides and no-balls
GROUP BY p.Player_Name
ORDER BY Total_Runs DESC,Balls_Faced DESC,Strike_Rate DESC ;

-- Query: Players with the best economy in bowling.

WITH rs AS (
    SELECT bb.bowler,p.player_name,
        SUM(bb.runs_scored) AS total_runs_conceded,
        COUNT(DISTINCT bb.match_id, bb.over_id) AS total_overs_bowled
    FROM ball_by_ball bb
	JOIN matches m ON bb.match_id = m.match_id
	JOIN player p ON bb.bowler = p.player_id
    GROUP BY bb.bowler, p.player_name
)
SELECT DISTINCT rs.*, total_runs_conceded / total_overs_bowled AS economy
FROM rs
JOIN player_match pm ON rs.bowler = pm.player_id
WHERE total_overs_bowled > 50
ORDER BY economy DESC;

-- top 10 bowlers taken highest wicket

select bb.bowler, p.player_name, count(wt.player_out) as number_of_wickets
from player p 
join player_match pm on p.player_id = pm.player_id
join ball_by_ball bb on pm.player_id = bb.bowler and pm.match_id = bb.match_id
join wicket_taken wt on bb.match_id = wt.match_id and bb.over_id = wt.over_id
    and bb.ball_id = wt.ball_id and bb.innings_no = wt.innings_no
group by bb.bowler, p.player_name 
order by number_of_wickets desc
limit 10;

-- 	Players with the most success rate in the team winning including the highest man of the match award.
with rs1 as (
    select m.man_of_the_match, count(m.man_of_the_match) man_of_the_match_count
    from matches m
    join player p on m.man_of_the_match=p.player_id
    where m.season_id in (9,8,7)
    group by man_of_the_match
),

rs2 as (
    select p.player_id, p.player_name, t.team_id, t.team_name
    from player p
    join player_match pm on p.player_id = pm.player_id
    join team t on pm.team_id = t.team_id
)

select distinct rs2.player_id, rs2.player_name,rs1.man_of_the_match_count	
from rs1
join rs2 on rs1.man_of_the_match = rs2.player_id
order by man_of_the_match_count desc;

-- 7.	What do you think could be the factors contributing to the high-scoring matches and the impact on viewership and team strategies 

-- i)	Comparison between Runs Scored during Power Play (1 to 6 overs) & Death Overs (17 to 20 overs) 
--       and Runs Scored during Middle Overs (7 to 16 Overs):

SELECT t3.Season_Year,
    SUM(CASE 
            WHEN t1.Over_Id BETWEEN 1 AND 6 OR t1.Over_Id BETWEEN 17 AND 20 
            THEN t1.Runs_Scored 
            ELSE 0 END) AS Runs_in_PowerPlay_DeathOvers,
    SUM(CASE 
            WHEN t1.Over_Id BETWEEN 7 AND 16 
            THEN t1.Runs_Scored 
            ELSE 0 END) AS Runs_in_MiddleOvers
FROM ball_by_ball t1
JOIN matches t2 ON t1.Match_Id = t2.Match_Id
JOIN season t3  ON t2.Season_Id = t3.Season_Id
WHERE t3.Season_Year BETWEEN 2013 AND 2016
GROUP BY t3.Season_Year
ORDER BY t3.Season_Year;

-- ii)	Analyzing High-Scoring IPL Matches: Venue Performance and Contributing Factors.

WITH match_scores AS (
    SELECT m.match_id,v.venue_name,SUM(bb.runs_scored) AS total_runs,
        COUNT(CASE WHEN bb.runs_scored = 4 THEN 1 END) AS total_fours,
        COUNT(CASE WHEN bb.runs_scored = 6 THEN 1 END) AS total_sixes
    FROM matches m
    JOIN ball_by_ball bb ON m.match_id = bb.match_id
	JOIN venue v ON m.venue_id = v.venue_id
    GROUP BY m.match_id, v.venue_name ),
venue_analysis AS (
    SELECT venue_name,COUNT(match_id) AS total_matches,AVG(total_runs) AS avg_runs_per_match,
        SUM(total_fours) AS total_fours_hit,
        SUM(total_sixes) AS total_sixes_hit
    FROM match_scores
    GROUP BY venue_name )
SELECT venue_name,total_matches,avg_runs_per_match,total_fours_hit,total_sixes_hit
FROM venue_analysis
ORDER BY avg_runs_per_match DESC
LIMIT 10;


-- 8.	Analyze the impact of home-ground advantage on team performance and identify strategies to maximize this advantage for RCB.
WITH total_win_venue AS (
    SELECT m.venue_id,v.venue_name,COUNT(*) AS total_win
    FROM matches m
    JOIN venue v ON m.venue_id = v.venue_id
    JOIN team t ON t.team_id = m.match_winner
    WHERE t.team_name = 'Royal Challengers Bangalore'
    GROUP BY m.venue_id, v.venue_name
),
total_played_venue AS (
    SELECT venue_id,COUNT(*) AS total_played_matches
    FROM matches 
    WHERE team_1 = '2' OR team_2 = '2'
    GROUP BY venue_id
)
SELECT twv.*,tpv.total_played_matches, (twv.total_win / tpv.total_played_matches) * 100 AS win_percentage
FROM total_win_venue twv
JOIN total_played_venue tpv ON twv.venue_id = tpv.venue_id
ORDER BY total_played_matches DESC;


-- 9.	Come up with a visual and analytical analysis of the RCB's past season's performance and potential reasons for them not winning a trophy.

 WITH RCB_Performance AS (
    SELECT m.Season_Id, COUNT(m.Match_Id) AS Matches_Played,
           SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) AS Matches_Won,
           SUM(CASE WHEN m.Match_Winner != t.Team_Id THEN 1 ELSE 0 END) AS Matches_Lost,
           (SUM(CASE WHEN m.Match_Winner = t.Team_Id THEN 1 ELSE 0 END) / COUNT(m.Match_Id)) * 100 AS Win_Percentage
    FROM matches m
    INNER JOIN team t ON t.Team_Id = m.Team_1 OR t.Team_Id = m.Team_2
    WHERE t.Team_Name = 'Royal Challengers Bangalore'
    GROUP BY m.Season_Id
)
SELECT s.Season_Year, rp.Matches_Played, rp.Matches_Won, rp.Matches_Lost, rp.Win_Percentage
FROM RCB_Performance rp
INNER JOIN season s ON rp.Season_Id = s.Season_Id
ORDER BY s.Season_Year;
 
 


-- 10.	How would you approach this problem, if the objective and subjective questions weren't given?
-- 11.	In the "Match" table, some entries in the "Opponent_Team" column are incorrectly spelled as "Delhi_Capitals" instead of "Delhi_Daredevils". Write an SQL query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils".

SET SQL_SAFE_UPDATES = 0;
UPDATE team
SET Team_Name = 'Delhi Daredevils'
WHERE Team_Name =  'Delhi Capitals';
 SET SQL_SAFE_UPDATES = 1; -- Re-enable safe updates if desired


