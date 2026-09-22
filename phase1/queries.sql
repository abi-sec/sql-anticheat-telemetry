-- Phase 1: Core Filters
-- Solutions for Phase 1 challenges

-- 1. Quick look at the first 10 rows of match telemetry
SELECT * FROM match_telemetry LIMIT 10;

-- 2. All matches played on Dust_II
SELECT * FROM match_telemetry WHERE map_name = 'Dust_II';

-- 3. All matches where players used the AWP
SELECT * FROM match_telemetry WHERE weapon_primary = 'AWP';

-- 4. Accounts that are not currently active
SELECT * FROM accounts WHERE account_status != 'active';

-- 5. Matches played between midnight and 5:00 AM
SELECT * FROM match_telemetry 
WHERE EXTRACT(HOUR FROM match_date) BETWEEN 0 AND 4;

-- 6. Accounts created in September 2026
SELECT * FROM accounts 
WHERE created_at >= '2026-09-01' AND created_at < '2026-10-01';

-- 7. Accounts registered with disposable tempmail domains
SELECT * FROM accounts WHERE email LIKE '%tempmail%';

-- 8. Matches with 25+ kills, sorted highest first
SELECT * FROM match_telemetry 
WHERE kills >= 25 
ORDER BY kills DESC;

-- 9. Matches with 25+ kills AND 3 or fewer deaths
SELECT * FROM match_telemetry 
WHERE kills >= 25 AND deaths <= 3;

-- 10. Account details for suspect shortlist (player IDs 15, 16, 17, 18, 19)
SELECT * FROM accounts 
WHERE account_id IN (15, 16, 17, 18, 19);

-- 11. Suspect filter: 20+ kills, <= 5 deaths, got first blood, top 15 by kills
SELECT * FROM match_telemetry 
WHERE kills >= 20 
  AND deaths <= 5 
  AND got_first_blood = true 
ORDER BY kills DESC 
LIMIT 15;
