# Phase 2 - Aggregations & Outlier Hunting

Working notes, syntax testing, and statistical profiling challenges for Phase 2.

---

## Part 1: Testing the Reference Chart & Initial Experiments

Tested queries from `reference.md` in psql before tackling the challenge problems.

### 1. Basic Aggregations Across Whole Table
```sql
SELECT COUNT(*) FROM match_telemetry;    -- 116 matches
SELECT AVG(kills) FROM match_telemetry;  -- 14.51 average kills
SELECT MAX(kills) FROM match_telemetry;  -- 38 highest single-game kill count
```

### 2. GROUP BY Gotchas & Rules
- **Non-aggregate column rule**:
  - Tried: `SELECT player_id, AVG(kills) FROM match_telemetry;`
  - Error: `column "match_telemetry.player_id" must appear in the GROUP BY clause or be used in an aggregate function`
  - Rule: Every column in `SELECT` that isn't wrapped in an aggregate function must be listed in `GROUP BY`:
    ```sql
    SELECT player_id, AVG(kills)
    FROM match_telemetry
    GROUP BY player_id;
    ```
- **Adding unaggregated dimensions**:
  - Tried: `SELECT player_id, map_name, AVG(kills), MAX(kills) FROM match_telemetry GROUP BY player_id;`
  - Error on `map_name`. If `map_name` is selected, it must also be in `GROUP BY`.

### 3. Column Aliases & Multiple Aggregates
- **Alias naming**:
  - Tried: `SELECT player_id, AVG(kills) as avg kills ...` -> syntax error on spaces.
  - Underscores needed: `AS avg_kills`.
- **Multi-aggregate query**:
  ```sql
  SELECT player_id, 
         COUNT(*) AS total_matches,
         AVG(kills) AS avg_kills,
         MAX(kills) AS best_game
  FROM match_telemetry
  GROUP BY player_id;
  ```

### 4. WHERE vs HAVING Filtering
- **Filtering order**:
  - Filtered Dust_II matches first with `WHERE map_name = 'Dust_II'`.
  - Tried: `HAVING kills >= 20` -> Error: raw column `kills` cannot be evaluated in `HAVING`.
  - Fix: `HAVING` filters aggregated values, so use `HAVING AVG(kills) >= 20`:
    ```sql
    SELECT player_id, AVG(kills) AS avg_kills
    FROM match_telemetry
    WHERE map_name = 'Dust_II'
    GROUP BY player_id
    HAVING AVG(kills) >= 20;
    ```
  - Output: Only 5 players average 20+ kills on Dust_II (IDs 19, 21, 17, 5, 15).

### 5. Decimal Formatting with ROUND
```sql
-- 2 decimal places
SELECT player_id, ROUND(AVG(kills), 2) AS avg_kills
FROM match_telemetry
GROUP BY player_id;

-- nearest integer
SELECT player_id, ROUND(AVG(kills), 0) AS avg_kills
FROM match_telemetry
GROUP BY player_id;
```

---

## Part 2: Phase 2 Challenges

### Challenge 1: Total volume check
- **Question**: How many total matches are recorded in telemetry, and how many distinct accounts exist?
- **Approach / Notes**: 
- **Query**:
```sql

```

---

### Challenge 2: Match activity per player
- **Question**: Count the total number of matches played per player, sorted by most active first.
- **Approach / Notes**: 
- **Query**:
```sql

```

---

### Challenge 3: Global baseline stats
- **Question**: Calculate the overall average kills, deaths, and headshots across all matches to establish the server baseline.
- **Approach / Notes**: 
- **Query**:
```sql

```

---

### Challenge 4: Per-player stat profiles
- **Question**: For each player, calculate total matches played, average kills, average deaths, and average headshots (rounded to 1 decimal place).
- **Approach / Notes**: 
- **Query**:
```sql

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
