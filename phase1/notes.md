# Phase 1 - Investigation Notes & Walkthrough

My notes, experiments, and challenge solutions for Phase 1. 

---

## Part 1: Testing the Reference Chart & Initial Experiments

Before jumping into the challenge questions, I tested queries in psql using the reference chart to get comfortable with the schema and syntax.

### 1. Database and Table Inspection
First verified what tables exist and what columns are inside:
```sql
\dt
\du
SELECT * FROM accounts;
SELECT * FROM match_telemetry;
SELECT * FROM login_history;
```

### 2. Syntax Gotchas Discovered
- **Column names**: Tripped on naming conventions early on.
  - Tried `total_playtime` instead of `total_playtime_hours`.
  - Tried `map` instead of `map_name`.
  - Tried `primary_weapon` instead of `weapon_primary`.
  - Tried `death` instead of `deaths`.
- **Single vs double quotes**:
  - `WHERE account_status = banned` -> syntax error (Postgres expects a column named banned).
  - `WHERE account_status = "banned"` -> same error, double quotes are for identifier/column names.
  - `WHERE account_status = 'banned'` -> correct, string literals must use single quotes.
- **Case sensitivity**:
  - `WHERE map_name = 'dust_ii'` returned 0 rows.
  - `WHERE map_name = 'Dust_II'` returned the actual data.
- **LIKE wildcard tests**:
  - Tested how `%` behaves in different positions across the `email` column:
    - `LIKE '%email.com'` -> matches strings ending in email.com.
    - `LIKE '%email'` -> 0 rows (nothing ends with plain "email").
    - `LIKE 'email%'` -> 0 rows (nothing starts with "email").
    - `LIKE '%email%'` -> matches anything containing "email".
- **ORDER BY and LIMIT order of execution**:
  - Tried `SELECT * FROM accounts LIMIT DESC 5;` and `DESC LIMIT 5;` -> syntax error.
  - `DESC` attaches to `ORDER BY`, and `ORDER BY` must always precede `LIMIT`:
    ```sql
    SELECT * FROM accounts ORDER BY total_playtime_hours DESC LIMIT 5;
    ```
- **EXTRACT gotcha**:
  - Tried `WHERE EXTRACT(MONTH FROM created_at) AS month = 9;` -> syntax error.
  - Aliases (`AS`) belong in `SELECT`, not in `WHERE`. The correct check is `WHERE EXTRACT(MONTH FROM created_at) = 9`.

---

## Part 2: Phase 1 Challenge Solutions

### Challenge 1: Quick telemetry peek
- **Question**: Take a quick look at the first 10 rows of match telemetry.
- **Approach**: Verify column names and check what stats exist (kills, deaths, reaction times, distance traveled).
```sql
SELECT * FROM match_telemetry LIMIT 10;
```
- **Findings**: 116 total match rows. Captures tactical metrics like `avg_reaction_time_ms`, `got_first_blood`, and shot accuracy stats.

---

### Challenge 2: Dust_II match filter
- **Question**: Find all matches played on Dust_II.
- **Approach**: Filter by `map_name = 'Dust_II'`.
```sql
SELECT * FROM match_telemetry WHERE map_name = 'Dust_II';
```

---

### Challenge 3: AWP sniper check
- **Question**: Find all matches where players used the AWP as their primary weapon.
- **Approach**: Filter by `weapon_primary = 'AWP'`.
```sql
SELECT * FROM match_telemetry WHERE weapon_primary = 'AWP';
```
- **Findings**: Player IDs 7 and 8 show up repeatedly. Checking `accounts` shows these are `CampKing` and `SniperElite`. Both look like legitimate sniper mains.

---

### Challenge 4: Inactive accounts
- **Question**: Find all accounts that are not currently active (e.g. banned, under review).
- **Approach**: Can use `<>` or `IN ('banned', 'under_review')`.
```sql
SELECT * FROM accounts WHERE account_status != 'active';
```
- **Findings**:
  - ID 15 (`xX_Shadow_Xx`) is `under_review`.
  - ID 19 (`freshstart_03`) is `banned`.
  - ID 21 (`BannedBandit`) is `banned`.

---

### Challenge 5: Off-hours matches (Midnight to 5 AM)
- **Question**: Find matches played between midnight and 5:00 AM.
- **Approach**: Use `EXTRACT(HOUR FROM match_date)` with `BETWEEN 0 AND 4`.
```sql
SELECT * FROM match_telemetry 
WHERE EXTRACT(HOUR FROM match_date) BETWEEN 0 AND 4;
```
- **Findings**: Player IDs 15 and 21 play almost exclusively between 1:00 AM and 4:30 AM. In cheat ops, habitual off-hours play can indicate automated farming or trying to avoid active moderation lobbies.

---

### Challenge 6: Fresh September 2026 accounts
- **Question**: Find accounts created in September 2026.
- **Approach**: Compare timestamps for the month of September.
```sql
SELECT * FROM accounts 
WHERE created_at >= '2026-09-01' AND created_at < '2026-10-01';
```
- **Findings**: Accounts 17, 18, and 19 (`freshstart_01`, `freshstart_02`, `freshstart_03`) were all registered on September 10 within hours of each other. Low levels (1-2), minimal playtime. Strong indicator of a multi-account booster or bot ring.

---

### Challenge 7: Disposable tempmail check
- **Question**: Identify accounts registered with temporary or burner email services.
- **Approach**: Search for `tempmail` using `LIKE '%tempmail%'`.
```sql
SELECT * FROM accounts WHERE email LIKE '%tempmail%';
```
- **Findings**: The exact same three accounts (IDs 17, 18, 19). Disposable emails combined with clustered creation dates is a textbook burner account pattern.

---

### Challenge 8: High kill games (25+ kills)
- **Question**: List all matches with 25 or more kills, ordered highest first.
- **Approach**: Filter `kills >= 25` and sort with `ORDER BY kills DESC`.
```sql
SELECT * FROM match_telemetry 
WHERE kills >= 25 
ORDER BY kills DESC;
```
- **Findings**: Player 15 dominates the top spots with 38, 36, 35 kills. Player 16 suddenly appears at the top as well with 35 and 33 kill games.

---

### Challenge 9: High kill, low death games (25+ kills, <= 3 deaths)
- **Question**: Find matches where a player had 25+ kills and 3 or fewer deaths.
- **Approach**: Combine both conditions with `AND`.
```sql
SELECT * FROM match_telemetry 
WHERE kills >= 25 AND deaths <= 3;
```
- **Findings**: Only four player IDs ever achieve this stat line: 15, 16, 19, and 21. A 25/3 line in standard matches is nearly impossible without cheats or heavy smurfing.

---

### Challenge 10: Suspect shortlist lookup
- **Question**: Pull account details for the recurring suspect IDs: 15, 16, 17, 18, 19.
- **Approach**: Use `IN` to check the list of IDs in a single query.
```sql
SELECT * FROM accounts 
WHERE account_id IN (15, 16, 17, 18, 19);
```
- **Findings**:
  - 15: `xX_Shadow_Xx` (under review, level 18, 95h played).
  - 16: `ProGamer2024` (active status, level 42, 480h played - suspicious jump in kills).
  - 17, 18, 19: The `freshstart` cluster.

---

### Challenge 11: The Suspect Filter (Boss Challenge)
- **Question**: Pull all matches where kills >= 20, deaths <= 5, and the player secured first blood (`got_first_blood = true`). Order by kills descending, limit to 15.
- **Approach**: Solved directly without hints:
```sql
SELECT * FROM match_telemetry 
WHERE kills >= 20 
  AND deaths <= 5 
  AND got_first_blood = true 
ORDER BY kills DESC 
LIMIT 15;
```
- **Findings**: The suspect pool is consistent: IDs 15, 16, 17, 18, 19, 21.
  - Player 15: Drops 30+ bombs with 1 to 3 deaths regularly.
  - Player 16: Multiple 30+ kill games.
  - Player 21: `BannedBandit` was doing the same before getting banned.
  - This sets up Phase 2: we need `GROUP BY`, `AVG`, headshot percentages, accuracy calculations, and reaction times to prove these anomalies with statistical profiles.
