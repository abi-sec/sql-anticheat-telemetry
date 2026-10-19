# Phase 4 - Time Analysis & Advanced Detection

Temporal pattern detection, player progression tracking, and composite investigations. This is where you move from "this player has suspicious stats" to "here's exactly when things changed and here's the timeline proving it."

---

## CTEs (Common Table Expressions)

Named temporary result sets that make complex queries readable. Think of them as building blocks you define before the main query.

```sql
-- break a complex query into steps
WITH suspect_stats AS (
    SELECT player_id,
           ROUND(AVG(kills), 2) AS avg_kills,
           COUNT(match_id) AS total_matches
    FROM match_telemetry
    GROUP BY player_id
    HAVING AVG(kills) > 20
)
SELECT s.player_id, a.username, s.avg_kills, s.total_matches
FROM suspect_stats s
JOIN accounts a ON s.player_id = a.account_id;
```

You can chain multiple CTEs:

```sql
WITH step_one AS (
    -- first calculation
),
step_two AS (
    -- uses step_one
    SELECT * FROM step_one WHERE ...
)
SELECT * FROM step_two;
```

Rules:
- Starts with `WITH`, each CTE gets a name and `AS (...)`
- Multiple CTEs separated by commas
- The final `SELECT` runs against the CTEs
- Makes debugging way easier - you can test each CTE independently

## Window Functions

Perform calculations across rows **without collapsing them** like GROUP BY does. Each row keeps its identity while also seeing neighboring rows.

```sql
SELECT player_id, match_date, kills,
       AVG(kills) OVER (PARTITION BY player_id) AS player_avg_kills
FROM match_telemetry;
```

The `OVER()` clause is what makes it a window function. Every row gets the result, but the rows don't collapse.

### PARTITION BY

Divides rows into groups (like GROUP BY) but keeps every row:

```sql
-- each row shows the match kills AND that player's average
SELECT player_id, match_date, kills,
       AVG(kills) OVER (PARTITION BY player_id) AS player_avg
FROM match_telemetry;
```

Without PARTITION BY, the window is the entire result set.

### LAG and LEAD

Look at previous or next rows within a partition:

```sql
-- LAG: get the previous row's value
SELECT player_id, match_date, kills,
       LAG(kills) OVER (PARTITION BY player_id ORDER BY match_date) AS prev_kills
FROM match_telemetry;

-- LEAD: get the next row's value
SELECT player_id, match_date, kills,
       LEAD(kills) OVER (PARTITION BY player_id ORDER BY match_date) AS next_kills
FROM match_telemetry;
```

- `LAG(column, offset, default)` - offset defaults to 1, default is NULL
- First row in each partition gets NULL for LAG (no previous row)
- Last row gets NULL for LEAD

### ROW_NUMBER, RANK, DENSE_RANK

Assign rankings within partitions:

```sql
-- ROW_NUMBER: unique sequential number, no ties
SELECT player_id, kills,
       ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY kills DESC) AS match_rank
FROM match_telemetry;

-- RANK: same rank for ties, gaps after ties (1, 2, 2, 4)
-- DENSE_RANK: same rank for ties, no gaps (1, 2, 2, 3)
```

### Window Aggregates (Running Totals)

SUM, AVG, COUNT, etc. work as window functions too:

```sql
-- running total of kills over time per player
SELECT player_id, match_date, kills,
       SUM(kills) OVER (
           PARTITION BY player_id
           ORDER BY match_date
           ROWS UNBOUNDED PRECEDING
       ) AS cumulative_kills
FROM match_telemetry;
```

### Frame Clauses

Control which rows the window function considers:

```
ROWS UNBOUNDED PRECEDING          -- from partition start to current row
ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING  -- sliding window of 3 rows
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- entire partition
```

Default frame when ORDER BY is specified: `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`

## Date Arithmetic

### AGE()

Returns the interval between two timestamps:

```sql
-- how old was each account when it was last seen?
SELECT username, AGE(now(), created_at) AS account_age
FROM accounts;

-- age between two specific timestamps
SELECT AGE('2026-09-15'::TIMESTAMP, created_at) AS age_at_date
FROM accounts;
```

### Timestamp Subtraction

Subtracting timestamps gives an interval directly:

```sql
-- time between two events
SELECT match_date - created_at AS time_since_creation
FROM match_telemetry m
JOIN accounts a ON m.player_id = a.account_id;
```

### EXTRACT from Intervals

Pull specific parts from intervals:

```sql
-- get days from an interval
SELECT EXTRACT(DAY FROM AGE(now(), created_at)) AS days_old
FROM accounts;

-- get hours between two timestamps
SELECT EXTRACT(EPOCH FROM (login_time - LAG(login_time) OVER (...))) / 3600 AS hours_between
FROM login_history;
```

`EXTRACT(EPOCH FROM interval)` gives total seconds - divide by 3600 for hours, 86400 for days.

## Subqueries

A query nested inside another query. Useful for one-off lookups and filtering without restructuring everything.

```sql
-- filter using a subquery
SELECT * FROM match_telemetry
WHERE player_id IN (
    SELECT account_id FROM accounts WHERE account_status = 'banned'
);

-- subquery in SELECT (scalar)
SELECT username,
       (SELECT COUNT(*) FROM player_reports WHERE reported_player_id = a.account_id) AS report_count
FROM accounts a;
```

Correlated subqueries reference the outer query and run once per row. Regular subqueries run once total.

---

## Execution order (updated)

`FROM → JOIN → WHERE → GROUP BY → HAVING → WINDOW FUNCTIONS → SELECT → DISTINCT → ORDER BY → LIMIT`

Window functions run after GROUP BY/HAVING but before ORDER BY. This means you can window over grouped results.
