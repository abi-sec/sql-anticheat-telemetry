# Phase 4 - Investigation Notes & Walkthrough

My notes, experiments, and challenge solutions for Phase 4.

---

## Part 1: Testing the Reference Chart & Initial Experiments

Tested queries from `reference.md` in psql before tackling the challenge problems.

### 1. Basic CTE
Tested a CTE to pull suspect stats (avg kills > 20):
```sql
WITH suspect_stats AS (
    SELECT player_id, ROUND(AVG(kills), 2) AS avg_kills,
    COUNT(match_id) AS total_matches
    FROM match_telemetry
    GROUP BY player_id
    HAVING AVG(kills) > 20
)
SELECT m.player_id, a.username, m.avg_kills, m.total_matches
FROM suspect_stats m
JOIN accounts a ON m.player_id = a.account_id;
```
- The CTE acts like a temporary table - define it with `WITH ... AS (...)`, then query it in the final SELECT like any regular table.
- The final SELECT can JOIN the CTE with other tables. Here, joining `suspect_stats` with `accounts` to get usernames.
- 4 suspects returned: HeadshotQueen (20.17), freshstart_03 (24.00), BannedBandit (29.50), xX_Shadow_Xx (32.75).

### 2. PARTITION BY (Window Function Basics)
Tested `AVG(kills) OVER (PARTITION BY player_id)` to see each match row alongside the player's overall average:
```sql
SELECT player_id, match_date, kills,
       AVG(kills) OVER (PARTITION BY player_id) AS player_avg_kills
FROM match_telemetry;
```
- Core difference from GROUP BY: window functions keep all 116 individual rows while attaching the aggregate. GROUP BY would collapse them into 21 rows (one per player).
- No GROUP BY clause needed at all. The `OVER (PARTITION BY ...)` does the grouping logic without collapsing.
- Player 16 stands out: average is 16.92 which looks moderate, but individual matches swing from 2-5 kills to 28-35 kills. The average masks the split personality. Player 15 by contrast is tightly clustered around 32.75 every match. Consistent cheater vs toggle cheater.

### 3. LAG and LEAD
Tested LAG and LEAD to see previous/next match kills per player:
```sql
SELECT player_id, match_date, kills,
       LAG(kills) OVER (PARTITION BY player_id ORDER BY match_date) AS prev_kills,
       LEAD(kills) OVER (PARTITION BY player_id ORDER BY match_date) AS next_kills
FROM match_telemetry;
```
- `ORDER BY` inside `OVER()` is required for LAG/LEAD - without it, there's no concept of "previous" or "next."
- Each partition is independent. First row per player gets NULL for LAG, last row gets NULL for LEAD. The window resets at partition boundaries.
- LAG and LEAD can both be used in the same query. Each gets its own `OVER()` clause.

### 4. ROW_NUMBER
Tested ranking each player's matches by kills:
```sql
SELECT player_id, kills,
       ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY kills DESC) AS match_rank
FROM match_telemetry;
```
- `ROW_NUMBER()` takes no arguments - it generates the sequence purely based on the `OVER()` clause.
- Assigns unique sequential numbers within each partition. No ties - even if two matches have the same kills, they get different rank numbers.

### 5. Running Totals (SUM OVER)
Tested cumulative kill totals over time per player:
```sql
SELECT player_id, match_date, kills,
       SUM(kills) OVER (PARTITION BY player_id ORDER BY match_date ROWS UNBOUNDED PRECEDING) AS cumulative_kills
FROM match_telemetry;
```
- `ROWS UNBOUNDED PRECEDING` means "from the start of the partition up to the current row." This is what makes it a running total instead of a full partition sum.
- The running total resets per player partition and accumulates chronologically based on the `ORDER BY match_date`.
- Without the frame clause, `ORDER BY` in the window defaults to `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` anyway - same behavior. But being explicit is clearer.

### 6. Date Arithmetic & AGE()
Tested timestamp subtraction and `AGE()` behavior:
```sql
SELECT a.username, MIN(m.match_date) - a.created_at AS time_to_first_match
FROM match_telemetry m
JOIN accounts a ON a.account_id = m.player_id
GROUP BY a.username, a.created_at
ORDER BY time_to_first_match ASC;
```
- `AGE(a, b)` computes `a - b`. Argument order controls positive vs negative signs. Single-argument `AGE(ts)` uses midnight (`current_date`), which can introduce small unexpected offsets.
- Simple timestamp subtraction (`match_date - created_at`) produces a clean day/time interval directly without compound year/month grouping.
- Finding: `freshstart_01`, `02`, and `03` all jumped into matches within 3.5 to 5 hours of account creation. Legitimate accounts averaged 40 to 700+ days before their first recorded match.

### 7. EXTRACT & Session Velocity (LAG with EPOCH)
Tested login velocity across shared IP addresses using `LAG` and `EXTRACT(EPOCH ...)`:
```sql
SELECT ip_address, login_time,
       ROUND(EXTRACT(EPOCH FROM (login_time - LAG(login_time) OVER (
           PARTITION BY ip_address ORDER BY login_time
       ))) / 3600, 2) AS hours_between
FROM login_history;
```
- `EXTRACT(DAY FROM interval)` only pulls the day component, not total days. For true elapsed time, `EXTRACT(EPOCH FROM interval)` gives total seconds (divide by 3600 for hours, 86400 for days).
- Normal players log in once every 120 to 200+ hours.
- Bot farm (`91.198.174.50`) churns logins in 2.5 hours and 45 minutes (0.75 hours) across multiple accounts.
- Evasion IP (`185.220.101.42`) shows a 961-hour gap (~40 days) marking the exact downtime between BannedBandit getting banned and xX_Shadow_Xx launching.

### 8. Subqueries vs LEFT JOINs (Master List Anchor)
Compared scalar subqueries against `LEFT JOIN` aggregations:
```sql
SELECT a.username, COUNT(p.report_id) AS report_count
FROM accounts a
LEFT JOIN player_reports p ON a.account_id = p.reported_player_id
GROUP BY a.username;
```
- Whatever table is placed in `FROM` acts as the master anchor. Starting `FROM accounts` keeps all 21 accounts (even those with 0 reports). Starting `FROM player_reports` drops un-reported accounts entirely.
- The `ON a.account_id = p.reported_player_id` condition matches the exact role of the subquery's `WHERE p.reported_player_id = a.account_id`.

---

## Part 2: Phase 4 Challenges

### Challenge 1: Readable Evidence Board (CTE refactor)
- **Question**: Take the Phase 3 Evidence Board query (Challenge 10) and rewrite it using CTEs. Break it into named steps: one CTE for player stats (avg kills, K/D, headshot %, accuracy), one for report counts, and one for hardware IDs. Join them in the final SELECT.
- **Why this matters**: Real investigations have 200+ line queries. CTEs make them debuggable - you can test each step alone.
- **Approach / Notes**:
  - Major architectural shift from Phase 3: instead of one massive multi-table join with a monster GROUP BY, the problem splits into three standalone modular blocks (`suspect_stats`, `hardware`, `reports`).
  - The linking column rule: each CTE acts like its own isolated table, so it must explicitly SELECT the ID (`player_id` / `account_id`) to be joinable later.
  - Aggregation elimination at the final step: because each CTE pre-aggregates its own metrics (matches counted, averages calculated, reports totaled), the final SELECT no longer needs any `GROUP BY` clause. It simply stitches pre-calculated rows together.
  - Anchor selection: starting `FROM suspect_stats` ensures the final output focuses strictly on suspect accounts, rather than pulling in all 21 accounts and sorting through NULLs.
- **Query**:
```sql
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
```

---

### Challenge 2: Match-to-match kill deltas (LAG)
- **Question**: For every player, show each match in chronological order alongside the **previous match's kills** and the **delta** (current kills minus previous kills). Use `LAG` partitioned by player and ordered by match date. Join with accounts for usernames.
- **Why this matters**: Stat deltas reveal toggling behavior. A legit player's kills fluctuate +/- 5. A cheater toggling on shows +20 jumps.
- **Approach / Notes**:
- **Query**:

---

### Challenge 3: Pinpointing the toggle match (ProGamer2024)
- **Question**: Focus on Player 16 (`ProGamer2024`). Using `LAG`, find the **exact match** where kills spiked. Show: match_date, kills, previous kills, delta, map, and reaction time. Order chronologically. Which single match is the inflection point?
- **Why this matters**: In Phase 3 you used a rough before/after bucket. This gives you the precise moment of behavior change - the difference between "stats changed sometime" and "stats changed on September 1st at 10 PM on Dust_II."
- **Approach / Notes**:
- **Query**:

---

### Challenge 4: Best game ranking (ROW_NUMBER)
- **Question**: Use `ROW_NUMBER()` with `PARTITION BY player_id ORDER BY kills DESC` to rank each player's matches from best to worst. Then filter for only each player's **#1 best game**. Show username, kills, map, and match date. Who has the highest single-game kill count?
- **Why this matters**: Leaderboard analysis. If a player's #1 game is 3x their average, it could indicate a one-time cheat toggle or a boosted match.
- **Approach / Notes**:
- **Query**:

---

### Challenge 5: Account age at first match
- **Question**: For each player, calculate how many **days old** their account was when they played their first match. Use `AGE()` or timestamp subtraction between `accounts.created_at` and `MIN(match_telemetry.match_date)`. Flag anyone whose account was less than 7 days old at first match.
- **Why this matters**: Brand new accounts dropping 20+ kills are either smurfs, bought accounts, or bots. Account age vs skill level is a core Trust & Safety signal.
- **Approach / Notes**:
- **Query**:

---

### Challenge 6: Session velocity (bot farm timing)
- **Question**: For IP addresses shared by multiple accounts (from Phase 3 Challenge 6), use `LAG` on `login_time` to calculate the **time gap in hours** between consecutive logins from different accounts on the same IP. Use `EXTRACT(EPOCH FROM ...)` to convert the interval to hours. Flag gaps under 1 hour.
- **Why this matters**: Bot farms cycle accounts rapidly. If account A logs out and account B logs in from the same IP 30 minutes later, that's automation. Human account-switching takes longer and is less consistent.
- **Approach / Notes**:
- **Query**:

---

### Challenge 7: Report burst detection
- **Question**: For players with 3+ reports, use `LAG` on `report_date` (partitioned by reported player, ordered by date) to calculate the **hours between consecutive reports**. Which player has the tightest burst of reports? Join with accounts for the reporter's username too.
- **Why this matters**: A single salty report means nothing. 4 reports within 2 hours from different players in the same session = the community is reacting to live cheating. Report velocity is a stronger signal than report count.
- **Approach / Notes**:
- **Query**:

---

### Challenge 8: Running cumulative kill curve
- **Question**: For ProGamer2024 and xX_Shadow_Xx, build a **running total of kills** over time using `SUM(kills) OVER (PARTITION BY player_id ORDER BY match_date)`. Also include a running average using `AVG(kills) OVER (...)`. Show match_date, match kills, cumulative kills, and running average per match.
- **Why this matters**: Legit players show a smooth, gradually increasing curve. A cheater shows a "hockey stick" - flat early, then suddenly steep. The running average makes the breakpoint obvious.
- **Approach / Notes**:
- **Query**:

---

### Challenge 9: Toggle detection (match vs own average)
- **Question**: For each match, calculate the player's **overall average kills** using a window function (`AVG(kills) OVER (PARTITION BY player_id)`). Then flag any match where kills exceeded **2x their own average**. Show username, match_date, kills, player_avg, and a "toggle_flag" column using CASE WHEN.
- **Why this matters**: Comparing against the server baseline (Phase 2) misses players who are normally decent but occasionally toggle on. Comparing against their *own* average catches toggling behavior regardless of baseline skill level.
- **Approach / Notes**:
- **Query**:

---

### Challenge 10: The Timeline (Boss Challenge)
- **Question**: Build a full temporal investigation report using a CTE pipeline. For each suspect from the Phase 3 Evidence Board:
  1. CTE 1: Pull each suspect's matches with `LAG` kill deltas and running cumulative kills
  2. CTE 2: Pull their login sessions with `LAG` time gaps
  3. CTE 3: Pull their report timeline with `LAG` time gaps between reports
  4. Final SELECT: Join everything together. Show username, account status, account age in days, each match chronologically with: kills, kill delta from previous match, running avg kills, cumulative kills, and a CASE WHEN threat flag.

  Filter for the same suspects as the Evidence Board (avg kills > 20, K/D > 3.0, or headshot % > 50).
- **Why this matters**: This is the deliverable. In a real game security role, this is the investigation packet you'd hand to a senior analyst or attach to a ban wave ticket. It tells the complete story: when the account was created, when behavior changed, how fast reports came in, and what the progression curve looks like.
- **Approach / Notes**:
- **Query**:
