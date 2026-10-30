# SQL Anti-Cheat Telemetry Investigation

A PostgreSQL investigation project that applies anti-cheat analyst workflows (lead-driven triage, account linking, behavioral anomaly detection, and false-positive review) to a mock game telemetry database.

**Status:** All 4 phases complete. See [FINDINGS.md](FINDINGS.md) for the investigation write-up.

## Background

I spent 3+ years as a Cheat Operations Analyst in the AAA games space, running lead-driven investigations in Splunk (SPL): correlating logs, pivoting on indicators to uncover linked accounts, and building cases on cheating and account abuse. This project takes the same investigative approach into relational SQL, working through progressively harder questions an anti-cheat or trust and safety analyst would ask of player data.

## Headline Findings

- **Ban evasion**: a banned account and a new account share a hardware ID, were never active at the same time, and the new account appeared on that hardware at the minute it was created. Very likely the same operator.
- **Mid-history behavior change**: pinpointed the exact match where one account went from 3 kills to 28 and from 302ms to 85ms reaction time, after six ordinary matches.
- **Burner ring**: three disposable-email accounts created within hours of each other, sharing one hardware ID and IP, with overlapping sessions.
- **False positive ruled out**: a high-kill player flagged on one metric was cleared after every other signal came back within normal range.

## Data

> **The dataset is synthetic.** The schema, records, and cheater archetypes were AI-generated to simulate a studio's anti-cheat data. All queries and investigation logic are my own.

Five linked tables:

| Table | Contents |
|---|---|
| `accounts` | Player profiles, account status, level, playtime |
| `match_telemetry` | Per-match kills, deaths, headshots, accuracy, reaction times |
| `player_reports` | Cheat reports filed by other players |
| `hardware_fingerprints` | Hardware IDs linked to accounts, with first and last seen times |
| `login_history` | IP addresses, login times, session lengths, regions |

The data contains planted archetypes (aimbots, a mid-history behavior change, a burner account ring, ban evasion, and a legitimate high performer) that get progressively harder to surface.

## Phases

| Phase | Investigation focus | SQL concepts |
|---|---|---|
| **1** | Initial triage: filter for off-hours play, disposable emails, extreme stat lines | `WHERE`, `IN`, `LIKE`, `BETWEEN`, `ORDER BY`, `LIMIT` |
| **2** | Player stat profiles and outlier thresholds (accuracy, headshot ratio, reaction time, K/D) | `GROUP BY`, `HAVING`, aggregates, numeric casting, `NULLIF` |
| **3** | Joining evidence: shared hardware and IPs, report history, evidence board | `INNER JOIN`, `LEFT JOIN`, joining `accounts` twice (reporter and reported), `CASE WHEN`, `COALESCE`, `ARRAY_AGG` |
| **4** | Time-based detection: match-to-match changes, account age, session timing, report bursts, suspect dossier | CTEs, window functions (`LAG`, `LEAD`, `ROW_NUMBER`, running `SUM`/`AVG`), `WINDOW` clause, interval math, `EXTRACT(EPOCH ...)` |

Each phase folder contains:
- `queries.sql`: the query for each challenge
- `notes.md`: the question, approach, errors hit along the way, and what the results showed
- `reference.md`: the syntax reference used for that phase

## How to Read This Repo

The queries are kept as I originally wrote them, so the progression from Phase 1 to Phase 4 is visible, including early mistakes. Issues I identified on review are listed under **Known Limitations** in [FINDINGS.md](FINDINGS.md) rather than silently fixed.

Suggested path: read [FINDINGS.md](FINDINGS.md) first, then `phase4/notes.md` (Challenges 3, 9, and 10) for the most involved queries.

## Setup

Requires PostgreSQL.

```bash
psql -U postgres -c "CREATE DATABASE anticheat;"
psql -U postgres -d anticheat -f setup.sql
psql -U postgres -d anticheat
```

> `setup.sql` drops and recreates all five tables, so rerunning it resets the database.

Notes:
- Times in the data are server time; no timezone is specified.
- Queries that use `CURRENT_DATE` (Phase 4 Challenge 10) return different account ages depending on the day they are run.
