-- Phase 3: Joining Evidence
-- cross-referencing tables to build actual cases


-- 1. named stat profiles: join telemetry with accounts for usernames
SELECT a.username,
       ROUND(AVG(m.kills), 2) AS avg_kills,
       ROUND(AVG(m.deaths), 2) AS avg_deaths,
       COUNT(m.match_id) AS total_matches
FROM accounts a
LEFT JOIN match_telemetry m ON m.player_id = a.account_id
GROUP BY a.username;

-- 2. report details with reported player's username
SELECT a.username, p.reason, p.report_date
FROM player_reports p
LEFT JOIN accounts a ON p.reported_player_id = a.account_id
ORDER BY report_date DESC;

-- 3. who reported who? join accounts twice for both reporter and reported names
SELECT a.username AS abuser, b.username AS reporter, p.reason, p.report_date
FROM player_reports p
LEFT JOIN accounts a ON p.reported_player_id = a.account_id
LEFT JOIN accounts b ON p.reporter_player_id = b.account_id
ORDER BY report_date DESC;


-- 4. hardware sharing: find hardware IDs linked to multiple accounts
SELECT hardware_id, ARRAY_AGG(account_id) AS accounts, COUNT(account_id)
FROM hardware_fingerprints
GROUP BY hardware_id
HAVING COUNT(account_id) > 1;

-- 5. hardware to username: map shared hardware to actual player names
SELECT h.hardware_id, ARRAY_AGG(h.account_id) AS accounts,
       ARRAY_AGG(a.username) AS usernames, COUNT(h.account_id)
FROM hardware_fingerprints h
LEFT JOIN accounts a ON h.account_id = a.account_id
GROUP BY h.hardware_id
HAVING COUNT(h.account_id) > 1;

-- 6. shared IP detection: IPs used by multiple accounts with usernames
SELECT i.ip_address, i.region, ARRAY_AGG(DISTINCT a.username) AS usernames
FROM login_history i
LEFT JOIN accounts a ON i.account_id = a.account_id
GROUP BY i.ip_address, i.region
HAVING COUNT(DISTINCT i.account_id) > 1;


-- 7. threat level classification using CASE WHEN


-- 8. report count with zero-report players using LEFT JOIN + COALESCE


-- 9. player 16's before/after stat split using CASE WHEN


-- 10. THE EVIDENCE BOARD
--     full suspect report: username, status, matches, avg kills, K/D,
--     HS%, hardware ID, report count, threat level
--     join accounts + telemetry + hardware + reports
