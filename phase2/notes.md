# Phase 2 - Investigation Notes & Walkthrough

My notes, experiments, and challenge solutions for Phase 2.

---

## Part 1: Testing the Reference Chart & Initial Experiments

Tested queries from `reference.md` in psql before tackling the challenge problems.

### 1. Basic Aggregations Across Whole Table
Started with global counts to get a feel for the dataset size:
```sql
SELECT COUNT(*) FROM match_telemetry;    -- 116 matches
SELECT AVG(kills) FROM match_telemetry;  -- 14.51 average kills
SELECT MAX(kills) FROM match_telemetry;  -- 38 highest single-game kill count
```

### 2. GROUP BY - The Column Rule
Tried selecting `player_id` alongside `AVG(kills)` without GROUP BY:
```sql
SELECT player_id, AVG(kills) FROM match_telemetry;
```
Error: `column "match_telemetry.player_id" must appear in the GROUP BY clause or be used in an aggregate function`

Every column in SELECT that isn't inside an aggregate function needs to be in GROUP BY:
```sql
SELECT player_id, AVG(kills)
FROM match_telemetry
GROUP BY player_id;
```

Also tried adding `map_name` to the SELECT without adding it to GROUP BY - same error. If you select it, you group by it.

### 3. Alias Naming
Tried `AVG(kills) AS avg kills` - syntax error because of the space. Aliases can't have spaces unless quoted. Underscores work fine:
```sql
SELECT player_id,
       COUNT(*) AS total_matches,
       AVG(kills) AS avg_kills,
       MAX(kills) AS best_game
FROM match_telemetry
GROUP BY player_id;
```

### 4. WHERE vs HAVING
Tried using `HAVING kills >= 20` to filter high-kill players. Error - HAVING only works with aggregated values, not raw columns.

`WHERE` filters individual rows before grouping. `HAVING` filters the grouped results after aggregation:
```sql
SELECT player_id, AVG(kills) AS avg_kills
FROM match_telemetry
WHERE map_name = 'Dust_II'
GROUP BY player_id
HAVING AVG(kills) >= 20;
```
Only 5 players average 20+ kills on Dust_II: IDs 19, 21, 17, 5, 15.

### 5. ROUND for Clean Output
Without ROUND, AVG gives ugly decimals like `15.5000000000000000`. Tested both precision levels:
```sql
-- 2 decimal places
SELECT player_id, ROUND(AVG(kills), 2) AS avg_kills
FROM match_telemetry
GROUP BY player_id;

-- nearest whole number
SELECT player_id, ROUND(AVG(kills), 0) AS avg_kills
FROM match_telemetry
GROUP BY player_id;
```

---

## Part 2: Phase 2 Challenges

### Challenge 1: Total volume check
- **Question**: How many total matches are recorded in telemetry, and how many distinct accounts exist?
- **Approach / Notes**:
  - First tried `FROM accounts AND match_telemetry`. `AND` is a logical operator, so it doesn't work in `FROM`. Combining tables comes later in Phase 3 (JOINs).
  - Tried `COUNT(DISTINCT (match_id, player_id))` but this counts distinct *pairs* as a tuple, not each column separately.
  - Googled and learned `COUNT(DISTINCT col)` which wasn't in the reference chart but fits perfectly.
  - Two separate queries is the way to go for Phase 2.
- **Query**:
```sql
SELECT COUNT(DISTINCT match_id) AS total_matches, 
       COUNT(DISTINCT player_id) AS total_players 
FROM match_telemetry;
-- 116 matches, 21 players
```

---

### Challenge 2: Match activity per player
- **Question**: Count the total number of matches played per player, sorted by most active first.
- **Approach / Notes**:
  - Initially tried `SUM(match_id)` which was wrong. That just adds up the ID numbers. `COUNT(match_id)` is what actually counts the rows.
- **Query**:
```sql
SELECT player_id, COUNT(match_id) AS most_matches 
FROM match_telemetry 
GROUP BY player_id 
ORDER BY most_matches DESC;
-- Player 16 is most active with 12 matches. Player 19 has only 2.
```

---

### Challenge 3: Global baseline stats
- **Question**: Calculate the overall average kills, deaths, and headshots across all matches to establish the server baseline.
- **Approach / Notes**:
  - No `GROUP BY` needed here. Aggregate functions without grouping just return one row for the whole table.
- **Query**:
```sql
SELECT AVG(kills) AS avg_kills,
       AVG(deaths) AS avg_deaths,
       AVG(headshots) AS avg_headshots
FROM match_telemetry;
-- Baseline: ~14.5 kills, ~7.8 deaths, ~6.2 headshots per match
```

---

### Challenge 4: Per-player stat profiles
- **Question**: For each player, calculate total matches played, average kills, average deaths, and average headshots (rounded to 1 decimal place).
- **Approach / Notes**:
  - Used `COUNT` along with `ROUND(AVG(...), 1)` to get clean decimal outputs.
  - Players 15, 21, and 19 immediately stand out with crazy high kill/headshot numbers and very low deaths.
- **Query**:
```sql
SELECT player_id, COUNT(match_id) AS total_matches,
       ROUND(AVG(kills), 1) AS avg_kills,
       ROUND(AVG(deaths), 1) AS avg_deaths,
       ROUND(AVG(headshots), 1) AS avg_headshots
FROM match_telemetry
GROUP BY player_id
ORDER BY total_matches DESC;
```

---

### Challenge 5: Accuracy percentage
- **Question**: Calculate each player's average shooting accuracy percentage `(shots_hit / shots_fired * 100)`. Filter for players with unusually high accuracy.
- **Approach / Notes**: Human averages sit around 20-35%. Anything consistently over 70-80% is suspicious.
  - Started with `shots_fired / shots_hit` which was backwards. Accuracy is hits divided by total shots, not the other way around. Getting 300-500% values was the giveaway.
  - Flipped the division to `shots_hit / shots_fired` but got all zeros. Integer division strikes again: `30 / 150 = 0` in integer math.
  - Added `::NUMERIC` cast and finally got real percentages.
  - Tried using the alias `shot_accuracy` in `HAVING` but that doesn't work because `HAVING` runs before `SELECT` in the execution order. Had to repeat the full expression.
  - Also tried `WHERE` after `GROUP BY` which is a syntax error. `WHERE` filters rows before grouping, `HAVING` filters after.
- **Query**:
```sql
SELECT player_id,
       ROUND((SUM(shots_hit)::NUMERIC / SUM(shots_fired)::NUMERIC) * 100, 2) AS shot_accuracy
FROM match_telemetry
GROUP BY player_id
HAVING ROUND((SUM(shots_hit)::NUMERIC / SUM(shots_fired)::NUMERIC) * 100, 2) > 80
ORDER BY shot_accuracy DESC;
-- Players 21 (93.35%) and 15 (92.51%) are the only ones above 80%. Same suspects.
```

---

### Challenge 6: Headshot percentage
- **Question**: Calculate headshot ratio `(headshots / kills * 100)` per player. Identify anyone exceeding 50%.
- **Approach / Notes**:
  - Same pattern as Challenge 5. Used `SUM` with `::NUMERIC` cast and repeated the expression in `HAVING`.
  - Players 15 and 21 at 85%+ headshot ratio, meaning practically every kill is a headshot. Players 16 and 19 also above 50%.
- **Query**:
```sql
SELECT player_id,
       ROUND((SUM(headshots)::NUMERIC / SUM(kills)::NUMERIC) * 100, 2) AS headshot_ratio
FROM match_telemetry
GROUP BY player_id
HAVING ROUND((SUM(headshots)::NUMERIC / SUM(kills)::NUMERIC) * 100, 2) > 50
ORDER BY headshot_ratio DESC;
-- 15 (86.26%), 21 (85.59%), 16 (60.10%), 19 (54.17%)
```

---

### Challenge 7: Reaction time audit
- **Question**: Calculate the average and minimum reaction time (`avg_reaction_time_ms`) per player. Sort by lowest reaction time.
- **Approach / Notes**: Human visual reaction limits are typically 150ms+. Sub-100ms indicates automated triggerbots or memory-based aimbot injection.
  - First attempt only had `AVG`, missed that the challenge asks for both average and minimum.
  - Players 15 (35ms min, 39ms avg) and 21 (40ms min, 45ms avg) are way below human limits.
  - Player 20 also sub-100ms (52ms min, 59ms avg) which is new.
  - Player 16 has a 188ms average but a 72ms minimum. Could be toggling cheats on and off between matches.
- **Query**:
```sql
SELECT player_id, AVG(avg_reaction_time_ms) AS avg_reaction_time,
       MIN(avg_reaction_time_ms) AS min_reaction_time
FROM match_telemetry
GROUP BY player_id
ORDER BY min_reaction_time ASC;
```

---

### Challenge 8: High report volume
- **Question**: Count the number of player reports per target from `player_reports`. Filter for players with 3 or more reports.
- **Approach / Notes**:
  - First query from a different table (`player_reports` instead of `match_telemetry`).
  - Initially used `> 3` instead of `>= 3`. Same results here but the logic matters - "3 or more" means `>=`.
  - Player 15 has 8 reports, Player 16 has 4.
- **Query**:
```sql
SELECT reported_player_id, COUNT(reported_player_id) AS total_reports_per_player
FROM player_reports
GROUP BY reported_player_id
HAVING COUNT(reported_player_id) >= 3;
```

---

### Challenge 9: Kill/Death ratio (K/D)
- **Question**: Calculate the average K/D ratio per player `(SUM(kills) / NULLIF(SUM(deaths), 0))`. Find players with K/D above 3.0.
- **Approach / Notes**:
  - First attempt used `ROUND` without the second argument, so K/D ratios came out as whole numbers (12, 10, 8, etc.). Adding `, 2` fixed it.
  - The rounding actually mattered here. Player 16 has a 3.08 K/D which rounded down to 3, so they didn't pass the `> 3` filter until decimals were added.
- **Query**:
```sql
SELECT player_id, ROUND((SUM(kills)::NUMERIC / NULLIF(SUM(deaths), 0)), 2) AS kd_ratio
FROM match_telemetry
GROUP BY player_id
HAVING ROUND((SUM(kills)::NUMERIC / NULLIF(SUM(deaths), 0)), 2) > 3.0
ORDER BY kd_ratio DESC;
-- 15 (11.91), 19 (9.60), 21 (8.43), 17 (4.39), 18 (3.53), 16 (3.08)
```

---

### Challenge 10: The Full Dossier (Boss Challenge)
- **Question**: Build a single comprehensive query summarizing player profiles: total matches, avg kills, avg deaths, overall K/D, headshot %, accuracy %, and min reaction time. Filter for players showing statistical anomalies in any category.
- **Approach / Notes**:
  - First attempt had `total matches` with a space in the alias. Caught it and switched to `total_matches`.
  - Forgot `GROUP BY player_id` initially. Without it Postgres doesn't know how to split the aggregates per player.
  - Used `AS` aliases inside `HAVING` (like `MIN(avg_reaction_time_ms) AS min_reaction_time < 100`) which doesn't work. `AS` is only for `SELECT`, not for conditions.
  - Wrote `(AVG(kills), 1) > 20` instead of `ROUND(AVG(kills), 1) > 20`. The parentheses with a comma creates a tuple, not a ROUND call.
  - Used `OR` in `HAVING` to flag anyone suspicious in **any** category rather than `AND` which would require all conditions to be true.
  - 8 players flagged total. Players 15 and 21 light up every single column. Players like 20 and 5 only flag for one thing each (reaction time and avg kills respectively).
- **Query**:
```sql
SELECT player_id, COUNT(match_id) AS total_matches,
       ROUND(AVG(kills), 1) AS avg_kills,
       ROUND(AVG(deaths), 1) AS avg_deaths,
       ROUND((SUM(kills)::NUMERIC / NULLIF(SUM(deaths), 0)), 2) AS kd_ratio,
       ROUND((SUM(headshots)::NUMERIC / SUM(kills)::NUMERIC) * 100, 2) AS headshot_ratio,
       ROUND((SUM(shots_hit)::NUMERIC / SUM(shots_fired)::NUMERIC) * 100, 2) AS shot_accuracy,
       MIN(avg_reaction_time_ms) AS min_reaction_time
FROM match_telemetry
GROUP BY player_id
HAVING ROUND(AVG(kills), 1) > 20 OR ROUND((SUM(kills)::NUMERIC / NULLIF(SUM(deaths), 0)), 2) > 3.0 OR
       ROUND((SUM(headshots)::NUMERIC / SUM(kills)::NUMERIC) * 100, 2) > 50.00 OR
       ROUND((SUM(shots_hit)::NUMERIC / SUM(shots_fired)::NUMERIC) * 100, 2) > 80.00 OR
       MIN(avg_reaction_time_ms) < 100;
```
