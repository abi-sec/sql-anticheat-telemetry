-- Phase 2: Aggregation & Outlier Hunting
-- building stat profiles for every player, looking for the outliers


-- 1. how many total matches? how many accounts?


-- 2. match count per player, sorted by most active


-- 3. global baseline - avg kills, deaths, headshots across all matches
--    (need these numbers to know what "normal" looks like)


-- 4. full player profile: matches played, avg kills, avg deaths, avg headshots


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
