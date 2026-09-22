# Phase 2 - Aggregations & Outlier Hunting

Turning raw rows into player profiles. This is where you actually prove someone is cheating with numbers.

---

## Aggregate functions

| Function | Does | Example |
|----------|------|---------|
| `COUNT(*)` | count rows | total matches played |
| `SUM(col)` | add up values | total kills across all matches |
| `AVG(col)` | average | avg kills per match |
| `MIN(col)` | smallest | fastest reaction time |
| `MAX(col)` | largest | best single-game kill count |

```sql
SELECT COUNT(*) FROM match_telemetry;    -- how many matches total?
SELECT MAX(kills) FROM match_telemetry;  -- highest kill game ever?
```

Without GROUP BY these give you one number for the whole table.

## GROUP BY

Split the aggregation per group:

```sql
-- avg kills PER PLAYER instead of overall
SELECT player_id, AVG(kills)
FROM match_telemetry
GROUP BY player_id;
```

Rule: every non-aggregate column in SELECT must be in GROUP BY.

## AS (aliases)

Name your output columns so they're readable:

```sql
SELECT player_id,
       COUNT(*) AS total_matches,
       AVG(kills) AS avg_kills
FROM match_telemetry
GROUP BY player_id;
```

## HAVING

WHERE filters rows *before* grouping. HAVING filters *after* aggregation.

```sql
-- only show players averaging 20+ kills (the outliers)
SELECT player_id, AVG(kills) AS avg_kills
FROM match_telemetry
GROUP BY player_id
HAVING AVG(kills) > 20;
```

Can combine both:
```sql
-- look at only Dust_II matches, then find players averaging 15+ kills there
SELECT player_id, AVG(kills) AS avg_kills
FROM match_telemetry
WHERE map_name = 'Dust_II'
GROUP BY player_id
HAVING AVG(kills) > 15;
```

## ROUND

Clean up ugly decimals:

```sql
ROUND(AVG(kills)::NUMERIC, 2)   -- 2 decimal places
```

The `::NUMERIC` cast is a postgres thing - ROUND needs numeric type, not float.

## Calculated columns / division gotchas

```sql
-- headshot percentage
ROUND((headshots::NUMERIC / NULLIF(kills, 0)) * 100, 1) AS hs_pct
```

- `::NUMERIC` - otherwise integer division gives 0 (3/10 = 0 not 0.3)
- `NULLIF(kills, 0)` - returns NULL instead of 0, prevents division by zero crash

---

## Execution order (updated)

`FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`
