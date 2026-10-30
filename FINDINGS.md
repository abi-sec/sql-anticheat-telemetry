# Investigation Findings

> **About the data:** The dataset is synthetic. The schema, records, and cheater archetypes were AI-generated to simulate a game studio's anti-cheat telemetry. The queries and investigation logic are my own. The goal of this write-up is to show how each pattern was found and how confident the evidence allows me to be, not to make claims about real players.

Confidence language used below:
- **Very likely**: multiple independent signals point the same way.
- **Likely / consistent with**: the signals fit, but other explanations remain open.
- **Open lead**: worth a closer look, not enough to act on.

**Population baseline** (all players except the seven flagged accounts, IDs 15-21): 28.39% shot accuracy, 19.78% headshot ratio, and a fastest recorded reaction time of 190ms. Thresholds in the queries (80% accuracy, 50% headshots, sub-100ms reaction) sit well outside this baseline.

---

## 1. Ban evasion: BannedBandit to xX_Shadow_Xx

- **Accounts**: 21 (`BannedBandit`, banned) and 15 (`xX_Shadow_Xx`, under review)
- **Found via**: Phase 1 (Challenge 5), Phase 3 (Challenges 4-6), Phase 4 (Part 1, experiment 7)
- **Evidence**:
  - Both accounts share hardware ID `HW-DEAD0000BEEF0000DEAD0000BEEF0000`.
  - The two accounts were never active at the same time. BannedBandit's hardware was last seen on July 5. `xX_Shadow_Xx` was created on August 1 at 03:20, and the same hardware ID was first seen on that account at that exact minute.
  - Login gap on the shared IP: 961 hours (about 40 days) between BannedBandit's last login and xX_Shadow_Xx's first.
  - Near-identical stat profiles: 93.35% vs 92.51% accuracy, 85.59% vs 86.26% headshot ratio, 40ms vs 35ms minimum reaction time.
  - Both play almost exclusively between 1:00 AM and 4:30 AM (server time; timezone not specified in the data).
  - Shared IP `185.220.101.42` (EU-East). xX_Shadow_Xx's latest login came from `23.129.64.100` (NA-East). Both addresses fall in ranges publicly associated with Tor exit relays, so the IP overlap on its own is weak evidence. Many unrelated users share exit nodes. The hardware ID and timeline carry this finding; the IP only supports it.
- **Assessment**: Very likely the same operator returning on a new account after the ban.

## 2. Burner account ring: freshstart_01, 02, 03

- **Accounts**: 17, 18, 19
- **Found via**: Phase 1 (Challenges 6-7), Phase 3 (Challenges 4-6), Phase 4 (Challenges 5-6)
- **Evidence**:
  - All three registered on September 10 between 08:00 and 11:15, using disposable `tempmail.net` addresses.
  - Account levels 1-2 with 4 to 8 hours of total playtime.
  - All three share hardware ID `HW-CAFE0000BABE0000CAFE0000BABE0000` and IP `91.198.174.50`.
  - Each played its first match 3.5 to 4.75 hours after account creation.
  - Sessions on September 10 overlap: all three accounts were logged in at the same time between 11:20 and 12:05, on the same hardware ID and IP. That points to multiple game clients running on one machine rather than one person switching accounts.
  - K/D ratios of 4.39, 3.53, and 9.60 on brand-new accounts. `freshstart_03` received two reports (boosting, then aimbot) 2.5 hours apart on its first day and is already banned.
- **Assessment**: Likely a single operator running a burner or boosting ring, with `freshstart_03` as the most aggressive account.

## 3. Blatant aim assistance: xX_Shadow_Xx

- **Account**: 15
- **Found via**: Phase 1 (Challenges 8-9, 11), Phase 2 (Challenges 5-10), Phase 4 (Challenges 7-8)
- **Evidence**:
  - 92.51% shot accuracy, 86.26% headshot ratio, 35ms minimum reaction time, 11.91 K/D, 32.75 average kills.
  - Stats are flat from the first recorded match (running average stays between 32 and 33.5 kills), so there is no visible ramp-up.
  - 8 reports from 8 different players, all filed between 01:30 and 04:20, the same hours this account plays. That is consistent with players reporting during live matches.
- **Assessment**: Consistent with an aimbot active from the first match. Combined with Finding 1, this is the strongest case in the dataset.

## 4. Mid-history behavior change: ProGamer2024

- **Account**: 16
- **Found via**: Phase 3 (Challenge 9), Phase 4 (Challenges 2-3, 8-9)
- **Evidence**:
  - First six matches (July 5 to August 20): 3.50 average kills, 285-310ms reaction times.
  - On September 1 at 22:00 on Dust_II, kills jumped from 3 to 28 (+25) and reaction time dropped from 302ms to 85ms.
  - Every match from that point: 30.33 average kills, 72-85ms reaction times. Career headshot ratio 60.10%.
  - First report filed September 3, two days after the change. 4 reports total.
  - No hardware fingerprint and no login history on file, despite being the most active account (12 matches). The missing telemetry is a signal in itself, either evasion of fingerprinting or a data gap worth escalating.
- **Assessment**: Consistent with a cheat being enabled, an account sale, or account sharing starting September 1. The available data cannot distinguish between these. Without login history, account takeover cannot be checked.
- **Lesson learned**: Phase 4 Challenge 9 compared each match against the player's career average and flagged only 1 of the 6 post-change matches, because those matches inflate the career average. Comparing each match only against the player's earlier matches flags all 6. Baselines should exclude the behavior being tested.

## 5. Open lead: SilentStrike

- **Account**: 20
- **Found via**: Phase 2 (Challenges 7, 10)
- **Evidence**:
  - 52ms minimum and 59ms average reaction time across 8 matches, far below the 190ms population floor.
  - Every other stat is ordinary: 13.4 average kills, 29.35% accuracy, 18.69% headshot ratio, 1.37 K/D.
  - Unique hardware ID and IP, with no links to any other account.
  - One report (August 26): "Something feels off about their reaction..."
- **Assessment**: Open lead. The profile fits a reaction-only assist such as a triggerbot, but a telemetry or instrumentation issue is also possible. Needs match-level review before any action.

---

## False Positives

- **HeadshotQueen (ID 5)**: flagged by the Evidence Board on average kills alone (20.17). Every other signal is normal: 28.10% headshot ratio, 34.70% accuracy, 2.02 K/D, 190ms minimum reaction time, level 78 with 1,105 hours played. She received one aimbot report claiming "too many headshots", yet her headshot ratio is close to the population baseline. Assessment: a skilled long-term player, not a cheater.
- **CampKing (ID 7) and SniperElite (ID 8)**: surfaced repeatedly when filtering for AWP usage. Their stats are consistent with legitimate sniper mains.

---

## Phase 4 Challenge 10 Dossier: Recorded Output

The dossier was run on October 26, 2026. Account age is calculated with `CURRENT_DATE`, so the values change every day the query is rerun. The values below are as recorded on that date.

| Suspect | Account age (days, as of Oct 26, 2026) | Peak kills | Avg kills | K/D | Headshot % | Reports |
|---|---|---|---|---|---|---|
| xX_Shadow_Xx | 86 | 38 | 32.75 | 11.91 | 86.26 | 8 |
| BannedBandit | 147 | 33 | 29.50 | 8.43 | 85.59 | blank (0) |
| ProGamer2024 | 376 | 35 | 16.92 | 3.08 | 60.10 | 4 |
| freshstart_03 | 46 | 25 | 24.00 | 9.60 | 54.17 | 2 |
| freshstart_01 | 46 | 22 | 19.75 | 4.39 | 49.37 | 1 |
| freshstart_02 | 46 | 21 | 17.67 | 3.53 | 47.17 | blank (0) |

For reference, account ages anchored to the last match in the dataset (September 15, 2026) are: burners 5 days, xX_Shadow_Xx 45 days, BannedBandit 106 days, ProGamer2024 335 days.

---

## Known Limitations

The queries are kept as originally written to show how the work progressed. These are the issues I would fix in a revision:

- **Phase 2 Challenges 6 and 10**: headshot and accuracy divisions have no `NULLIF` guard. No account in this data has zero kills or zero shots, but one would break the query.
- **Phase 3 Challenge 9**: splits ProGamer2024's matches into before and after by kill count rather than by date. It produces the same 3.50 vs 30.33 result here only because of how this data falls. A date split (`match_date < '2026-09-01'`) is the correct approach.
- **Phase 3 Challenge 10**: the `CASE` labels are inverted (`< 20` should be `> 20`), so some suspects appear as "baseline" and HeadshotQueen appears as "baseline" instead of "suspicious".
- **Phase 4 Challenge 1**: the kills-only label shows ProGamer2024 as "baseline" because his average hides the behavior change. Players with no reports show blank instead of 0 (`COALESCE` needed).
- **Phase 4 Challenge 6**: measures login-to-login gaps, not the gap from the end of one session to the next login. Measuring from session end reveals the concurrent sessions described in Finding 2.
- **Phase 4 Challenge 7**: measures gaps between consecutive reports. A rolling 24-hour window and a distinct-reporter count would fit the idea of a report burst better.
- **Phase 4 Challenge 9**: the career-average baseline is diluted by the matches being tested. Using `ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING` fixes it (see Finding 4).
- **Phase 4 Challenge 10**:
  - `ROUND(AVG(kills)) > 20` rounds HeadshotQueen's 20.17 down to 20 and drops her from the dossier (6 rows instead of 7).
  - The final join multiplies match, report, and login rows. Results are correct only because the outer query uses `MIN` and `MAX`; any `COUNT` or `SUM` would be wrong. Each CTE should be reduced to one row per player before joining.
  - `CURRENT_DATE` makes account age drift between runs. Anchoring to `MAX(match_date)` makes it reproducible.
  - `tightest_burst_count` is measured in hours; a clearer name would be `min_report_gap_hrs`.
- **Thresholds are hard-coded** (80% accuracy, 50% headshots, 100ms reaction). With a larger dataset, `PERCENTILE_CONT` or z-scores with a minimum match count would set them from the data.
- **Scale**: 21 accounts and 116 matches with planted archetypes. The logic is the point; the numbers would not generalize.
