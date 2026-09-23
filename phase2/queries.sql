-- Phase 2: Aggregation & Outlier Hunting
-- building stat profiles for every player, looking for the outliers


-- 1. how many total matches? how many accounts?
SELECT COUNT(DISTINCT match_id) AS total_matches, 
       COUNT(DISTINCT player_id) AS total_players 
FROM match_telemetry;

-- 2. match count per player, sorted by most active
SELECT player_id, COUNT(match_id) AS most_matches 
FROM match_telemetry 
GROUP BY player_id 
ORDER BY most_matches DESC;

-- 3. global baseline - avg kills, deaths, headshots across all matches
--    (need these numbers to know what "normal" looks like)
SELECT AVG(kills) AS avg_kills,
       AVG(deaths) AS avg_deaths,
       AVG(headshots) AS avg_headshots
FROM match_telemetry;

-- 4. full player profile: matches played, avg kills, avg deaths, avg headshots
SELECT player_id, COUNT(match_id) AS total_matches,
       ROUND(AVG(kills), 1) AS avg_kills,
       ROUND(AVG(deaths), 1) AS avg_deaths,
       ROUND(AVG(headshots), 1) AS avg_headshots
FROM match_telemetry
GROUP BY player_id
ORDER BY total_matches DESC;


-- 5. accuracy percentage per player - (shots_hit / shots_fired) * 100
--    normal human accuracy is 20-35%, anything above 80% is sketchy


-- 6. headshot percentage per player - (headshots / kills) * 100
--    pros sit around 25-35%, filter for anyone above 50%


-- 7. reaction time check - avg and min per player
--    human limit is ~150ms, anything below 100ms is basically impossible


-- 8. report count per player - who's getting reported the most?
--    only care about players with 3+ reports


-- 9. average K/D ratio per player
--    K/D above 3.0 is already elite, above 5.0 is suspicious


-- 10. THE FULL DOSSIER
--     everything in one query: matches, avg kills, avg deaths, avg K/D,
--     avg HS%, avg accuracy%, avg reaction time, min reaction time
--     filter for anyone with suspicious numbers in ANY category
