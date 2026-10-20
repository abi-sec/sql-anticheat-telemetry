-- Phase 4: Time Analysis & Advanced Detection
-- temporal patterns, progression tracking, and composite investigations


-- 1. readable evidence board (CTE refactor of Phase 3 Boss Challenge)
WITH suspect_stats AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS total_matches,
           ROUND(AVG(kills), 2) AS avg_kills,
           CASE
               WHEN ROUND(AVG(kills), 2) >= 25 THEN 'inhuman'
               WHEN ROUND(AVG(kills), 2) < 20 THEN 'suspicious'
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


