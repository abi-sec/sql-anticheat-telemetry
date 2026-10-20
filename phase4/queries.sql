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






