-- Phase 3: Joining Evidence
-- cross-referencing tables to build actual cases


-- 1. named stat profiles: join telemetry with accounts for usernames


-- 2. report details with reported player's username


-- 3. who reported who? join accounts twice for both reporter and reported names


-- 4. hardware sharing: find hardware IDs linked to multiple accounts


-- 5. hardware to username: map shared hardware to actual player names


-- 6. shared IP detection: IPs used by multiple accounts with usernames


-- 7. threat level classification using CASE WHEN


-- 8. report count with zero-report players using LEFT JOIN + COALESCE


-- 9. player 16's before/after stat split using CASE WHEN


-- 10. THE EVIDENCE BOARD
--     full suspect report: username, status, matches, avg kills, K/D,
--     HS%, hardware ID, report count, threat level
--     join accounts + telemetry + hardware + reports
