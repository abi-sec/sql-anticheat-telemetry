# Phase 3 - Joining Evidence

Connecting the tables together. This is where you cross-reference accounts, telemetry, hardware, logins, and reports to build actual cases instead of just stat profiles.

---

## INNER JOIN

Returns only rows that have a match in **both** tables. If there's no match, that row gets dropped.

```sql
-- get username alongside match stats
SELECT a.username, m.kills, m.deaths
FROM match_telemetry m
INNER JOIN accounts a ON m.player_id = a.account_id;
```

The `ON` clause tells Postgres which columns link the two tables. Think of it as: "match rows where this column in table A equals this column in table B."

Table aliases (`m`, `a`) are shorthand so you don't have to type the full table name every time.

## LEFT JOIN

Returns **all** rows from the left table, even if there's no match in the right table. Unmatched columns from the right table come back as `NULL`.

```sql
-- all accounts, with report count (even if they have 0 reports)
SELECT a.username, COUNT(r.report_id) AS report_count
FROM accounts a
LEFT JOIN player_reports r ON a.account_id = r.reported_player_id
GROUP BY a.username;
```

Use LEFT JOIN when you want to keep rows even if they don't have matching data in the other table. INNER JOIN would drop accounts with no reports entirely.

## Multiple JOINs

You can chain JOINs to connect more than two tables:

```sql
SELECT a.username, m.kills, h.hardware_id
FROM accounts a
INNER JOIN match_telemetry m ON a.account_id = m.player_id
INNER JOIN hardware_fingerprints h ON a.account_id = h.account_id;
```

## CASE WHEN

Conditional logic inside a query. Like an if/else that creates a new column:

```sql
SELECT player_id,
       AVG(kills) AS avg_kills,
       CASE
           WHEN AVG(kills) > 25 THEN 'high_risk'
           WHEN AVG(kills) > 15 THEN 'watch_list'
           ELSE 'normal'
       END AS threat_level
FROM match_telemetry
GROUP BY player_id;
```

Rules:
- Goes through conditions top to bottom, uses the first one that's true
- `ELSE` is the fallback if nothing matches
- `END` closes the CASE block
- You can put it in SELECT, WHERE, ORDER BY, etc.

## COALESCE

Returns the first non-NULL value from a list. Useful for replacing NULLs with a default:

```sql
-- if no reports exist, show 0 instead of NULL
SELECT a.username, COALESCE(COUNT(r.report_id), 0) AS report_count
FROM accounts a
LEFT JOIN player_reports r ON a.account_id = r.reported_player_id
GROUP BY a.username;
```

Also works with multiple fallbacks: `COALESCE(col1, col2, 'default')`

## Table Relationships (what connects to what)

```
accounts.account_id  <-->  match_telemetry.player_id
accounts.account_id  <-->  player_reports.reported_player_id
accounts.account_id  <-->  player_reports.reporter_player_id
accounts.account_id  <-->  hardware_fingerprints.account_id
accounts.account_id  <-->  login_history.account_id
```

---

## Execution order (updated)

`FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`

JOIN happens right after FROM, before everything else.
