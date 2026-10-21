-- Phase 4: Time Analysis & Advanced Detection
-- temporal patterns, progression tracking, and composite investigations


-- 1. readable evidence board (CTE refactor of Phase 3 Boss Challenge)
WITH suspect_stats AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS total_matches,
           ROUND(AVG(kills), 2) AS avg_kills,
           CASE
               WHEN ROUND(AVG(kills), 2) >= 25 THEN 'inhuman'
               WHEN ROUND(AVG(kills), 2) > 20 THEN 'suspicious'
               ELSE 'baseline'
           END AS kills_suspicion,
           ROUND((SUM(kills)::NUMERIC / NULLIF(SUM(deaths), 0)), 2) AS kd_ratio,
           ROUND((SUM(headshots)::NUMERIC / SUM(kills)::NUMERIC) * 100, 2) AS headshot_ratio
    FROM match_telemetry
    GROUP BY player_id
    HAVING ROUND(AVG(kills), 2) > 20
        OR ROUND((SUM(kills)::NUMERIC / NULLIF(SUM(deaths), 0)), 2) > 3.0
        OR ROUND((SUM(headshots)::NUMERIC / SUM(kills)::NUMERIC) * 100, 2) > 50
),
hardware AS (
    SELECT account_id, hardware_id
    FROM hardware_fingerprints
    GROUP BY account_id, hardware_id
),
reports AS (
    SELECT reported_player_id, COUNT(DISTINCT report_id) AS report_count
    FROM player_reports
    GROUP BY reported_player_id
)
SELECT a.username, a.account_status, s.total_matches, s.kills_suspicion,
       s.avg_kills, s.kd_ratio, s.headshot_ratio, h.hardware_id, r.report_count
FROM suspect_stats s
LEFT JOIN accounts a ON s.player_id = a.account_id
LEFT JOIN hardware h ON a.account_id = h.account_id
LEFT JOIN reports r ON r.reported_player_id = s.player_id;


-- 2. match-to-match kill deltas using LAG
-- standard inline window version:
SELECT a.username, m.player_id, m.match_date, m.kills,
       LAG(m.kills) OVER (PARTITION BY m.player_id ORDER BY m.match_date) AS previous_kills,
       m.kills - LAG(m.kills) OVER (PARTITION BY m.player_id ORDER BY m.match_date) AS delta
FROM match_telemetry m
LEFT JOIN accounts a ON a.account_id = m.player_id;

-- named WINDOW clause version (cleaner, avoids repeating OVER definitions):
SELECT a.username, m.player_id, m.match_date, m.kills,
       LAG(m.kills) OVER w AS previous_kills,
       m.kills - LAG(m.kills) OVER w AS delta
FROM match_telemetry m
LEFT JOIN accounts a ON a.account_id = m.player_id
WINDOW w AS (PARTITION BY m.player_id ORDER BY m.match_date);


-- 3. pinpointing ProGamer2024's toggle inflection match
SELECT a.username, m.match_date, m.kills,
       LAG(m.kills) OVER w AS previous_kills,
       m.kills - LAG(m.kills) OVER w AS delta,
       m.map_name, m.avg_reaction_time_ms
FROM match_telemetry m
LEFT JOIN accounts a ON a.account_id = m.player_id
WHERE a.username = 'ProGamer2024'
WINDOW w AS (ORDER BY m.match_date);


-- 4. best game ranking per player using ROW_NUMBER and CTE wrapper
WITH ranked_matches AS (
    SELECT a.username, m.kills, m.map_name, m.match_date,
           ROW_NUMBER() OVER (PARTITION BY m.player_id ORDER BY m.kills DESC) AS match_rank
    FROM match_telemetry m
    LEFT JOIN accounts a ON a.account_id = m.player_id
)
SELECT username, kills, map_name, match_date, match_rank
FROM ranked_matches
WHERE match_rank = 1
ORDER BY kills DESC;


-- 5. account age at first match (burner account detection under 7 days)
SELECT a.username, a.created_at,
       MIN(m.match_date) AS first_match_date,
       MIN(m.match_date) - a.created_at AS time_to_first_match
FROM match_telemetry m
JOIN accounts a ON a.account_id = m.player_id
GROUP BY a.username, a.created_at
HAVING MIN(m.match_date) - a.created_at < INTERVAL '7 days'
ORDER BY time_to_first_match ASC;


-- 6. session velocity (bot farm timing and account cycling under 1 hour)
WITH logs AS (
    SELECT ip_address, region, username,
           ROUND(EXTRACT(EPOCH FROM (login_time - LAG(login_time) OVER (PARTITION BY ip_address ORDER BY login_time))) / 3600, 2) AS hours_between
    FROM login_history i
    LEFT JOIN accounts a ON i.account_id = a.account_id
)
SELECT ip_address, region, username, hours_between
FROM logs
WHERE hours_between < 1;


-- 7. report burst detection (hours between consecutive reports for 3+ reported players)
WITH reports AS (
    SELECT a.username AS reporter, b.username AS reported,
           ROUND(EXTRACT(EPOCH FROM (report_date - LAG(report_date) OVER (PARTITION BY reported_player_id ORDER BY report_date))) / 3600, 2) AS reports_time_diff,
           COUNT(*) OVER (PARTITION BY reported_player_id) AS total_reports
    FROM player_reports p
    LEFT JOIN accounts b ON p.reported_player_id = b.account_id
    LEFT JOIN accounts a ON p.reporter_player_id = a.account_id
)
SELECT reporter, reported, total_reports, reports_time_diff
FROM reports
WHERE total_reports >= 3;






