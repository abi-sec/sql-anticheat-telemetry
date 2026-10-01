# Phase 3 - Investigation Notes & Walkthrough

My notes, experiments, and challenge solutions for Phase 3.

---

## Part 1: Testing the Reference Chart & Initial Experiments

Tested queries from `reference.md` in psql before tackling the challenge problems.

### 1. Basic INNER JOIN
Joined `match_telemetry` with `accounts` to get usernames alongside match stats:
```sql
SELECT a.username, m.kills, m.deaths
FROM match_telemetry m INNER JOIN accounts a
ON m.player_id = a.account_id;
```
- Forgot the `ON` keyword on first try, got a syntax error. `ON` is required to tell Postgres which columns link the tables.
- Got 116 rows back (one per match), each now showing the player's username instead of just their ID.
- Tried adding `GROUP BY` to this but it doesn't make sense without aggregate functions. If you just want individual rows with usernames attached, no GROUP BY needed.

### 2. LEFT JOIN vs INNER JOIN
Tested LEFT JOIN with report counts:
```sql
SELECT a.username, COUNT(r.report_id) AS report_count
FROM accounts a
LEFT JOIN player_reports r ON a.account_id = r.reported_player_id
GROUP BY a.username;
```
- LEFT JOIN keeps all accounts even if they have 0 reports. INNER JOIN would drop them.
- Also discovered that `ProGamer2024` (Player 16) has **no hardware fingerprint** on file. INNER JOIN with `hardware_fingerprints` drops them (20 rows), LEFT JOIN keeps them with NULL hardware_id (21 rows). Suspicious for the most active player.

### 3. Multiple JOINs and Chaining
Chained three tables together:
```sql
SELECT a.username, ROUND(AVG(m.kills), 2) AS avg_kills, h.hardware_id
FROM accounts a
INNER JOIN match_telemetry m ON a.account_id = m.player_id
INNER JOIN hardware_fingerprints h ON m.player_id = h.account_id
GROUP BY a.username, h.hardware_id;
```
- Tried chaining A->B, B->C instead of A->B, A->C. Both work since `a.account_id = m.player_id` and `m.player_id = h.account_id` are transitive.
- Had to add `h.hardware_id` to GROUP BY since it's not an aggregate. Any column in SELECT that's not inside an aggregate function goes in GROUP BY, regardless of type.
- Spotted shared hardware: `xX_Shadow_Xx` and `BannedBandit` both on `HW-DEAD...BEEF...`. All three `freshstart_` accounts on `HW-CAFE...BABE...`.

### 4. CASE WHEN
Tested threat level classification:
```sql
SELECT player_id, AVG(kills) AS avg_kills,
       CASE
           WHEN AVG(kills) > 25 THEN 'high_risk'
           WHEN AVG(kills) > 15 THEN 'watch_list'
           ELSE 'normal'
       END AS threat_level
FROM match_telemetry
GROUP BY player_id;
```
- Typo'd `ABG` instead of `AVG` on first try.
- Then built a more complex version combining JOINs + CASE WHEN for headshot classification:
```sql
SELECT a.username,
       ROUND((SUM(m.headshots)::NUMERIC / SUM(m.kills)::NUMERIC) * 100, 2) AS headshot_pct,
       CASE
           WHEN ROUND((SUM(m.headshots)::NUMERIC / SUM(m.kills)::NUMERIC) * 100, 2) > 80 THEN 'inhuman'
           WHEN ROUND((SUM(m.headshots)::NUMERIC / SUM(m.kills)::NUMERIC) * 100, 2) > 45 THEN 'watch_list'
           ELSE 'normal'
       END AS inhuman_stats
FROM accounts a
LEFT JOIN match_telemetry m ON a.account_id = m.player_id
GROUP BY a.username;
```
- Missing comma before CASE (it's just another column in SELECT).
- Used `a.accounts` instead of `a.account_id` for the JOIN condition.
- Had `m.player_id` in SELECT without adding it to GROUP BY. Removed it to fix.
- Results: xX_Shadow_Xx and BannedBandit flagged "inhuman", all three freshstart accounts + ProGamer2024 on watch list.

---

## Part 2: Phase 3 Challenges

### Challenge 1: Named stat profiles
- **Question**: Join `match_telemetry` with `accounts` to show player **usernames** alongside their avg kills, avg deaths, and total matches. No more working with just player IDs.
- **Approach / Notes**:
  - Used LEFT JOIN to connect telemetry to accounts.
  - Had a few minor typos early on (like `a.usernames` and using a dot for `m.player.id`), but got it working.
  - Nice to finally see the stats attached to actual names instead of just numbers.
- **Query**:
```sql
SELECT a.username,
       ROUND(AVG(m.kills), 2) AS avg_kills,
       ROUND(AVG(m.deaths), 2) AS avg_deaths,
       COUNT(m.match_id) AS total_matches
FROM accounts a
LEFT JOIN match_telemetry m ON m.player_id = a.account_id
GROUP BY a.username;
```

---

### Challenge 2: Report details with names
- **Question**: Join `player_reports` with `accounts` to show the **username** of the reported player, the reason for the report, and the report date. Sort by most recent reports first.
- **Approach / Notes**:
  - Proved out why table order matters for LEFT JOIN. 
  - Starting with `FROM accounts` gave 33 rows with a bunch of empty blanks for players with zero reports.
  - Switching to `FROM player_reports` pulled exactly the 21 actual reports we cared about. 
  - `ORDER BY report_date DESC` worked perfectly to sort the timestamps.
- **Query**:
```sql
SELECT a.username, p.reason, p.report_date
FROM player_reports p
LEFT JOIN accounts a ON p.reported_player_id = a.account_id
ORDER BY report_date DESC;
```

---

### Challenge 3: Who reported who?
- **Question**: Extend Challenge 2 by also joining the **reporter's** username. You'll need to join `accounts` twice (once for the reported player, once for the reporter).
- **Approach / Notes**:
  - Initially got a "table name specified more than once" error.
  - Learned about dual aliases. You can join the exact same table twice as long as you give it two different nicknames (like `a` and `b`).
  - Pulled `a.username AS abuser` and `b.username AS reporter`. The report log is completely readable now.
- **Query**:
```sql
SELECT a.username AS abuser, b.username AS reporter, p.reason, p.report_date
FROM player_reports p
LEFT JOIN accounts a ON p.reported_player_id = a.account_id
LEFT JOIN accounts b ON p.reporter_player_id = b.account_id
ORDER BY report_date DESC;
```

---

### Challenge 4: Hardware sharing detection
- **Question**: Find any `hardware_id` from `hardware_fingerprints` that is linked to **more than one** account. Show the hardware ID and the list of account IDs sharing it.
- **Approach / Notes**:
  - Initially tried grouping by `account_id` which was backwards - that shows how many hardware IDs each account has, not how many accounts share a hardware ID.
  - Then tried `GROUP BY hardware_id, account_id` which split every account into its own group (all counts = 1). Had to remove `account_id` from GROUP BY.
  - Used `ARRAY_AGG(account_id)` to collect all account IDs into a list per hardware ID. Same type of aggregate as COUNT or SUM but it bundles values into an array instead of computing a number.
  - Didn't even need a JOIN for the basic version - it's all in the `hardware_fingerprints` table.
- **Query**:
```sql
SELECT hardware_id, ARRAY_AGG(account_id) AS accounts, COUNT(account_id)
FROM hardware_fingerprints
GROUP BY hardware_id
HAVING COUNT(account_id) > 1;
```

---

### Challenge 5: Hardware to username mapping
- **Question**: Take the shared hardware IDs from Challenge 4 and join with `accounts` to show the actual **usernames** sharing hardware. This is how you catch ban evasion and multi-accounting.
- **Approach / Notes**:
  - Combined Challenges 4 and 5 into one query by joining `accounts` and using `ARRAY_AGG` on both account IDs and usernames.
  - Results: `HW-DEAD...BEEF...` shared by xX_Shadow_Xx and BannedBandit. `HW-CAFE...BABE...` shared by freshstart_01, 02, and 03. Confirmed ban evasion and a farming ring.
- **Query**:
```sql
SELECT h.hardware_id, ARRAY_AGG(h.account_id) AS accounts,
       ARRAY_AGG(a.username) AS usernames, COUNT(h.account_id)
FROM hardware_fingerprints h
LEFT JOIN accounts a ON h.account_id = a.account_id
GROUP BY h.hardware_id
HAVING COUNT(h.account_id) > 1;
```

---

### Challenge 6: Shared IP detection
- **Question**: Find any IP addresses in `login_history` used by **more than one** account. Show the IP, region, and the usernames sharing it.
- **Approach / Notes**:
  - Same pattern as Challenge 4/5 but with `login_history` and `ip_address`.
  - Got duplicate usernames in `ARRAY_AGG` because each login is a separate row. Used `DISTINCT` inside `ARRAY_AGG` to fix.
  - The tricky part: `DISTINCT` in `ARRAY_AGG` and `DISTINCT` in `COUNT` are independent. Adding DISTINCT to one aggregate doesn't affect the other. Each aggregate function does its own separate calculation.
  - Without `COUNT(DISTINCT i.account_id)`, players who logged in multiple times from the same IP showed up as "shared" even though it was just one person.
  - Same two groups flagged: `185.220.101.42` shared by BannedBandit and xX_Shadow_Xx, `91.198.174.50` shared by all three freshstart accounts.
- **Query**:
```sql
SELECT i.ip_address, i.region, ARRAY_AGG(DISTINCT a.username) AS usernames
FROM login_history i
LEFT JOIN accounts a ON i.account_id = a.account_id
GROUP BY i.ip_address, i.region
HAVING COUNT(DISTINCT i.account_id) > 1;
```

---

### Challenge 7: Threat level classification
- **Question**: Using `CASE WHEN`, assign a threat level to each player based on their avg kills: 'high_risk' (> 25), 'watch_list' (> 15), 'normal' (everyone else). Join with `accounts` to show usernames.
- **Approach / Notes**:
- **Query**:
```sql

```

---

### Challenge 8: Report count with zero-report players
- **Question**: Using `LEFT JOIN`, show every account's username alongside their total report count. Players with no reports should show 0, not disappear from results. Use `COALESCE` if needed.
- **Approach / Notes**:
- **Query**:
```sql

```

---

### Challenge 9: Player 16's before/after split
- **Question**: Player 16 (`ProGamer2024`) has a suspicious stat spike. Join their telemetry with `accounts` and use `CASE WHEN` to label each match as 'before' (kills < 10) or 'after' (kills >= 10). Compare the averages of each period.
- **Approach / Notes**:
- **Query**:
```sql

```

---

### Challenge 10: The Evidence Board (Boss Challenge)
- **Question**: Build a comprehensive suspect report joining `accounts`, `match_telemetry`, `hardware_fingerprints`, and `player_reports`. For each player, show: username, account status, total matches, avg kills, K/D ratio, headshot %, hardware ID, and report count. Use `LEFT JOIN` for reports (not every suspect has reports) and `CASE WHEN` for threat classification. Filter for players who appear in any suspicious category from Phase 2.
- **Approach / Notes**:
- **Query**:
```sql

```
