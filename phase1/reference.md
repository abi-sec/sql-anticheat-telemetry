# Phase 1 - Core Filters

Quick refresher on the basics. Stuff I know but haven't typed in a while.

---

## SELECT / FROM

```sql
SELECT * FROM accounts;              -- everything
SELECT username, account_status FROM accounts;  -- just these columns
```

## WHERE + comparisons

```sql
SELECT * FROM accounts WHERE account_status = 'banned';
SELECT * FROM match_telemetry WHERE kills > 20;
```

`=`, `!=` (or `<>`), `>`, `<`, `>=`, `<=` - all work as expected.

## AND / OR

```sql
-- both must be true
WHERE kills > 20 AND deaths < 5

-- either can be true
WHERE account_status = 'banned' OR account_status = 'under_review'

-- group with parentheses when mixing
WHERE (account_status = 'banned' OR account_status = 'under_review')
  AND account_level > 10
```

## IN

Cleaner than chaining OR:

```sql
WHERE account_id IN (15, 16, 17, 18, 19)
WHERE account_status IN ('banned', 'under_review')
```

## LIKE

Pattern matching. `%` = wildcard for any characters.

```sql
WHERE email LIKE '%tempmail%'    -- contains "tempmail"
WHERE username LIKE 'fresh%'     -- starts with "fresh"
```

## BETWEEN

Shorthand for `>= AND <=` (inclusive both sides):

```sql
WHERE kills BETWEEN 10 AND 20
WHERE match_date BETWEEN '2026-09-01' AND '2026-09-15'
```

## ORDER BY

```sql
ORDER BY kills DESC    -- highest first
ORDER BY kills ASC     -- lowest first (default)
ORDER BY player_id, kills DESC   -- sort by player, then kills within each
```

## LIMIT

```sql
SELECT * FROM accounts LIMIT 5;   -- just peek at 5 rows
```

## IS NULL / IS NOT NULL

Can't use `= NULL`, has to be `IS NULL`:

```sql
WHERE avg_reaction_time_ms IS NULL
WHERE avg_reaction_time_ms IS NOT NULL
```

## EXTRACT

Pull parts out of timestamps:

```sql
WHERE EXTRACT(HOUR FROM match_date) BETWEEN 0 AND 4   -- midnight to 4am
WHERE EXTRACT(MONTH FROM created_at) = 9               -- September
```

Fields: `YEAR`, `MONTH`, `DAY`, `HOUR`, `MINUTE`.

---

## Execution order

Written as: `SELECT → FROM → WHERE → ORDER BY → LIMIT`

Actually runs as: `FROM → WHERE → SELECT → ORDER BY → LIMIT`
