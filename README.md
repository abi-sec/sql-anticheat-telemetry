# SQL Anti-Cheat Analysis Practice

Brushing up on my SQL by working through a realistic anti-cheat investigation scenario. 

Coming from a background as a Cheat Operations Analyst in the AAA games space, I previously spent a lot of time working in Splunk (SPL) for telemetry analysis, behavioral anomaly detection, threat intelligence, and account security. The logic of querying datasets and hunting suspicious patterns isn't unfamiliar territory for me, but I wanted a dedicated hands-on project to sharpen my relational SQL (PostgreSQL) workflow.

To do that, I set up a mock telemetry database with player stats, match events, hardware fingerprints, and login history, then wrote queries across four phases to hunt down various cheater profiles hiding in the data.

## What's in here

**5 interconnected tables** simulating a game studio's anti-cheat data pipeline:
- `accounts` - player profiles, account status, playtime
- `match_telemetry` - per-match stats: kills, deaths, headshots, accuracy, reaction times
- `player_reports` - cheat reports filed by other players
- `hardware_fingerprints` - hardware IDs linked to accounts
- `login_history` - IP addresses, session times, regions

There are several cheater archetypes buried in the data (aimbots, sudden skill spikes, account farming rings, ban evasion, etc.) that get progressively harder to detect.

## Phases

| Phase | Focus | What I practiced |
|-------|-------|-----------------|
| **1** | Core Filters | `SELECT`, `WHERE`, `IN`, `LIKE`, `BETWEEN`, `ORDER BY`, `LIMIT` |
| **2** | Aggregation & Outliers | `GROUP BY`, `HAVING`, `COUNT`, `AVG`, `SUM`, `MIN`, `MAX` |
| **3** | Joining Evidence | `INNER JOIN`, `LEFT JOIN`, `CASE WHEN`, `COALESCE` |
| **4** | Time Analysis | CTEs, Window Functions (`LAG`, `LEAD`, `ROW_NUMBER`), date arithmetic |

Each phase has:
- `reference.md` - quick syntax reference chart
- `notes.md` - walkthrough of challenges, experiments, and investigation findings
- `queries.sql` - clean SQL queries for each challenge

## Setup

Requires PostgreSQL.

```bash
psql -U postgres -c "CREATE DATABASE anticheat;"
psql -U postgres -d anticheat -f setup.sql
psql -U postgres -d anticheat
```

## Why anti-cheat telemetry?

Standard textbook SQL tutorials focus on retail orders or employee tables. Anti-cheat analysis, on the other hand, mirrors real security engineering: behavioral anomaly detection, tracking statistical outliers, identifying account farming networks, and correlating identity artifacts like hardware IDs and IP addresses. Practicing in this environment maps directly to detection engineering, Trust & Safety, and security operations roles.
