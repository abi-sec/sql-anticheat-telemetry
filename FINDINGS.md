# Anti-Cheat Investigation Findings

## Identified Anomalies

### 1. Account Farming / Bot Ring
- **Suspects**: Player IDs 17, 18, 19 (`freshstart_01`, `freshstart_02`, `freshstart_03`)
- **Found via**: Phase 1 (Challenges 6 & 7)
- **Evidence**: 
  - All registered on the exact same day (Sept 10, 2026).
  - Used disposable `tempmail` domains.
  - Low level accounts (1-2) with barely any playtime. Textbook burner account pattern.

### 2. High-Performance / Aimbot or Smurfing
- **Suspects**: Player IDs 15 (`xX_Shadow_Xx`), 16 (`ProGamer2024`), 21 (`BannedBandit`)
- **Found via**: Phase 1 (Challenges 8, 9, 11) and Phase 2 (Challenges 4-10)
- **Evidence**:
  - Dropping 25+ kill games consistently while keeping deaths at 3 or lower.
  - IDs 15 and 21 play off-hours habitually (1 AM to 4:30 AM).
  - Crazy high kill averages and headshot rates, coupled with super low deaths in their stat profiles.
  - Shot accuracy: Players 15 (92.51%) and 21 (93.35%) are the only ones above 80%. Normal human range is 20-35%.
  - Headshot ratio: Players 15 (86.26%) and 21 (85.59%) land headshots on almost every kill. Player 16 (60.10%) and 19 (54.17%) also above the 50% threshold.
  - Reaction times: Players 15 (35ms min) and 21 (40ms min) are way below the 150ms human limit. Player 20 also sub-100ms (52ms min). Player 16 averages 188ms but has a 72ms minimum, which could mean toggling cheats on/off.
  - K/D ratios: Player 15 (11.91), 19 (9.60), 21 (8.43) are insane. Player 16 (3.08) also above 3.0.
  - Reports: Player 15 has 8 reports filed against them, Player 16 has 4. Community is clearly noticing.
  - Player 21 is already banned, Player 15 is currently "under review", and Player 16 is weirdly active with highly suspicious performance spikes.
  - Full dossier flagged 8 players total. Players 15 and 21 light up every category. Others like Player 20 and Player 5 only flag for one thing each (reaction time and avg kills).

### 3. Suspicious Reaction Time Only
- **Suspect**: Player ID 20
- **Found via**: Phase 2 (Challenges 7, 10)
- **Evidence**:
  - 52ms minimum reaction time, 59ms average. Well below human limits.
  - Other stats look normal (13.4 avg kills, 9.8 avg deaths, 29.35% accuracy, 18.69% headshot ratio, 1.37 K/D).
  - Could be a triggerbot user who isn't using aim assist, or could be a data anomaly. Needs further investigation in Phase 3 with hardware/login data.

## False Positives
- **Players**: IDs 7 (`CampKing`) and 8 (`SniperElite`)
- **Found via**: Phase 1 (Challenge 3)
- **Reasoning**: Popped up a lot when filtering for primary AWP (sniper) users. Looked into them and their stats just line up with being legitimate dedicated sniper mains.

