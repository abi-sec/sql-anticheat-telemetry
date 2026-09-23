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
- **Query**:
```sql

```

---

### Challenge 6: Headshot percentage
- **Question**: Calculate headshot ratio `(headshots / kills * 100)` per player. Identify anyone exceeding 50%.
- **Approach / Notes**:
- **Query**:
```sql

```

---

### Challenge 7: Reaction time audit
- **Question**: Calculate the average and minimum reaction time (`avg_reaction_time_ms`) per player. Sort by lowest reaction time.
- **Approach / Notes**: Human visual reaction limits are typically 150ms+. Sub-100ms indicates automated triggerbots or memory-based aimbot injection.
- **Query**:
```sql

```

---

### Challenge 8: High report volume
- **Question**: Count the number of player reports per target from `player_reports`. Filter for players with 3 or more reports.
- **Approach / Notes**:
- **Query**:
```sql

```

---

### Challenge 9: Kill/Death ratio (K/D)
- **Question**: Calculate the average K/D ratio per player `(SUM(kills) / NULLIF(SUM(deaths), 0))`. Find players with K/D above 3.0.
- **Approach / Notes**:
- **Query**:
```sql

```

---

### Challenge 10: The Full Dossier (Boss Challenge)
- **Question**: Build a single comprehensive query summarizing player profiles: total matches, avg kills, avg deaths, overall K/D, headshot %, accuracy %, and min reaction time. Filter for players showing statistical anomalies in any category.
- **Approach / Notes**:
- **Query**:
```sql

```
