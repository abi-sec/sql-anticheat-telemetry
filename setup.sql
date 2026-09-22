-- Mock anti-cheat telemetry database
-- Simulates what a game studio's data pipeline might look like
--
-- Setup:
--   psql -U postgres -c "CREATE DATABASE anticheat;"
--   psql -U postgres -d anticheat -f setup.sql

-- tables (drop + recreate for clean reruns)

DROP TABLE IF EXISTS login_history CASCADE;
DROP TABLE IF EXISTS hardware_fingerprints CASCADE;
DROP TABLE IF EXISTS player_reports CASCADE;
DROP TABLE IF EXISTS match_telemetry CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
    account_id    SERIAL PRIMARY KEY,
    username      VARCHAR(50) UNIQUE NOT NULL,
    email         VARCHAR(100),
    created_at    TIMESTAMP NOT NULL,
    account_status VARCHAR(20) DEFAULT 'active',   -- active, banned, suspended, under_review
    account_level  INT DEFAULT 1,
    total_playtime_hours DECIMAL(8,1) DEFAULT 0
);

CREATE TABLE match_telemetry (
    match_id           SERIAL PRIMARY KEY,
    player_id          INT REFERENCES accounts(account_id),
    map_name           VARCHAR(30) NOT NULL,
    weapon_primary     VARCHAR(30) NOT NULL,
    kills              INT DEFAULT 0,
    deaths             INT DEFAULT 0,
    headshots          INT DEFAULT 0,
    shots_fired        INT DEFAULT 0,
    shots_hit          INT DEFAULT 0,
    avg_reaction_time_ms INT,
    distance_traveled_m  DECIMAL(8,1),
    match_duration_sec   INT,
    got_first_blood      BOOLEAN DEFAULT FALSE,
    match_date           TIMESTAMP NOT NULL
);

CREATE TABLE player_reports (
    report_id           SERIAL PRIMARY KEY,
    reported_player_id  INT REFERENCES accounts(account_id),
    reporter_player_id  INT REFERENCES accounts(account_id),
    reason              VARCHAR(30) NOT NULL,  -- aimbot, wallhack, speedhack, boosting, griefing, other
    description         TEXT,
    report_date         TIMESTAMP NOT NULL
);

CREATE TABLE hardware_fingerprints (
    fingerprint_id SERIAL PRIMARY KEY,
    account_id     INT REFERENCES accounts(account_id),
    hardware_id    VARCHAR(64) NOT NULL,
    first_seen     TIMESTAMP NOT NULL,
    last_seen      TIMESTAMP NOT NULL
);

CREATE TABLE login_history (
    login_id          SERIAL PRIMARY KEY,
    account_id        INT REFERENCES accounts(account_id),
    ip_address        VARCHAR(45) NOT NULL,
    login_time        TIMESTAMP NOT NULL,
    session_duration_min INT,
    region            VARCHAR(30)
);


-- accounts


INSERT INTO accounts (username, email, created_at, account_status, account_level, total_playtime_hours) VALUES
('NoviceNinja',    'novice@email.com',         '2026-03-15 10:00:00', 'active',       12,  85.5),
('CasualCarl',     'carl.casual@email.com',    '2025-11-20 14:30:00', 'active',       28,  312.0),
('TacticalTina',   'tina.t@email.com',         '2025-08-10 09:15:00', 'active',       45,  520.3),
('FragMaster',     'frag.master@email.com',    '2025-06-01 18:00:00', 'active',       67,  890.2),
('HeadshotQueen',  'hsqueen@email.com',        '2025-04-22 11:45:00', 'active',       78, 1105.0),
('RunNGun_Rick',   'rick.rng@email.com',       '2026-01-05 20:00:00', 'active',       22,  195.5),
('CampKing',       'campking@email.com',       '2025-09-14 16:30:00', 'active',       38,  445.0),
('SniperElite',    'sniper.e@email.com',       '2025-07-30 12:00:00', 'active',       55,  720.8),
('SprayNPray',     'spray@email.com',          '2026-02-18 08:45:00', 'active',       15,  120.0),
('MidTierMike',    'mike.mid@email.com',       '2025-12-01 19:20:00', 'active',       30,  340.5),
('VeteranVic',     'vet.vic@email.com',        '2024-06-15 07:00:00', 'active',       95, 2450.0),
('RookieRoss',     'ross.r@email.com',         '2026-07-01 15:10:00', 'active',        5,   35.0),
('StealthSam',     'sam.stealth@email.com',    '2025-10-10 22:00:00', 'active',       35,  410.2),
('BombDefuser',    'defuser@email.com',        '2025-05-20 13:30:00', 'active',       50,  650.0),

('xX_Shadow_Xx',   'shadow.xx@proton.me',      '2026-08-01 03:20:00', 'under_review', 18,   95.0),
('ProGamer2024',   'progamer@email.com',       '2025-10-15 17:00:00', 'active',       42,  480.5),
('freshstart_01',  'fresh1@tempmail.net',      '2026-09-10 08:00:00', 'active',        2,    8.0),
('freshstart_02',  'fresh2@tempmail.net',      '2026-09-10 10:30:00', 'active',        2,    6.5),
('freshstart_03',  'fresh3@tempmail.net',      '2026-09-10 11:15:00', 'banned',        1,    4.0),
('SilentStrike',   'silent.s@email.com',       '2026-04-01 21:00:00', 'active',       25,  210.0),
('BannedBandit',   'bandit@email.com',         '2026-06-01 04:00:00', 'banned',       30,  200.0);

-- match data

INSERT INTO match_telemetry (player_id, map_name, weapon_primary, kills, deaths, headshots, shots_fired, shots_hit, avg_reaction_time_ms, distance_traveled_m, match_duration_sec, got_first_blood, match_date) VALUES

-- player 1
(1, 'Dust_II',  'AK-47',   3,  8, 0, 155, 30, 320, 4200.5, 1850, FALSE, '2026-08-05 14:00:00'),
(1, 'Mirage',   'M4A1-S',  2,  7, 1, 130, 22, 335, 3800.0, 1720, FALSE, '2026-08-08 15:30:00'),
(1, 'Inferno',  'FAMAS',   4,  9, 0, 180, 35, 305, 4500.2, 1900, FALSE, '2026-08-12 20:00:00'),
(1, 'Nuke',     'AK-47',   1,  6, 0, 110, 18, 345, 3500.0, 1650, FALSE, '2026-08-20 18:45:00'),
(1, 'Dust_II',  'P90',     5,  8, 1, 210, 55, 290, 5100.3, 1800, FALSE, '2026-08-25 21:00:00'),
(1, 'Overpass', 'AK-47',   2,  7, 0, 140, 25, 330, 4000.0, 1780, FALSE, '2026-09-01 14:00:00'),

-- player 2
(2, 'Mirage',   'AK-47',   8, 10, 1, 200, 52, 275, 5500.0, 1820, FALSE, '2026-08-03 19:00:00'),
(2, 'Dust_II',  'M4A1-S',  6,  8, 1, 175, 45, 285, 5200.5, 1750, FALSE, '2026-08-07 20:30:00'),
(2, 'Inferno',  'AK-47',  10,  9, 2, 230, 60, 260, 5800.0, 1880, TRUE,  '2026-08-14 18:00:00'),
(2, 'Nuke',     'P90',     5,  7, 0, 195, 58, 295, 5000.0, 1700, FALSE, '2026-08-22 21:15:00'),
(2, 'Mirage',   'AK-47',   7,  8, 1, 185, 48, 280, 5300.0, 1790, FALSE, '2026-09-02 19:00:00'),
(2, 'Vertigo',  'M4A1-S',  9,  9, 1, 215, 55, 270, 5600.0, 1850, FALSE, '2026-09-10 20:00:00'),

-- player 3
(3, 'Inferno',  'M4A1-S', 12, 10, 2, 210, 62, 240, 5400.0, 1860, TRUE,  '2026-08-02 16:00:00'),
(3, 'Dust_II',  'AK-47',  10, 11, 2, 225, 58, 250, 5700.0, 1820, FALSE, '2026-08-09 17:30:00'),
(3, 'Mirage',   'M4A1-S', 14,  9, 3, 245, 72, 235, 5200.5, 1900, TRUE,  '2026-08-15 15:00:00'),
(3, 'Overpass', 'AK-47',   8, 10, 1, 190, 50, 255, 5500.0, 1780, FALSE, '2026-08-23 19:45:00'),
(3, 'Nuke',     'M4A1-S', 11,  8, 2, 200, 60, 242, 5100.0, 1840, FALSE, '2026-09-05 16:00:00'),
(3, 'Inferno',  'AK-47',  13, 11, 2, 235, 65, 248, 5600.0, 1870, TRUE,  '2026-09-12 18:30:00'),

-- player 4
(4, 'Dust_II',  'AK-47',  18, 10, 5, 240, 78, 210, 6200.0, 1880, TRUE,  '2026-08-01 20:00:00'),
(4, 'Mirage',   'AK-47',  20,  9, 5, 255, 85, 205, 6500.0, 1920, TRUE,  '2026-08-06 21:00:00'),
(4, 'Inferno',  'M4A1-S', 15, 11, 3, 220, 70, 218, 5800.0, 1850, FALSE, '2026-08-13 19:30:00'),
(4, 'Nuke',     'AK-47',  22,  8, 6, 270, 92, 200, 6800.0, 1900, TRUE,  '2026-08-19 22:00:00'),
(4, 'Overpass', 'M4A1-S', 16, 12, 4, 230, 75, 215, 6000.0, 1870, FALSE, '2026-08-28 20:30:00'),
(4, 'Dust_II',  'AK-47',  19, 10, 5, 250, 82, 208, 6400.0, 1910, TRUE,  '2026-09-08 21:00:00'),

-- player 5
(5, 'Dust_II',  'AK-47',  22, 10, 6, 230, 80, 195, 6600.0, 1900, TRUE,  '2026-08-02 22:00:00'),
(5, 'Mirage',   'AK-47',  19, 11, 5, 220, 75, 200, 6200.0, 1880, TRUE,  '2026-08-10 21:30:00'),
(5, 'Inferno',  'M4A1-S', 24,  9, 7, 250, 88, 190, 6800.0, 1950, TRUE,  '2026-08-16 20:00:00'),
(5, 'Nuke',     'AK-47',  17, 10, 5, 210, 72, 205, 6000.0, 1860, FALSE, '2026-08-24 19:00:00'),
(5, 'Overpass', 'AK-47',  21,  8, 6, 235, 82, 192, 6500.0, 1920, TRUE,  '2026-09-03 22:00:00'),
(5, 'Dust_II',  'Desert_Eagle', 18, 12, 5, 195, 68, 198, 6100.0, 1870, FALSE, '2026-09-11 20:30:00'),

-- player 6
(6, 'Dust_II',  'P90',    10, 11, 1, 320, 90, 260, 7800.0, 1800, FALSE, '2026-08-04 18:00:00'),
(6, 'Mirage',   'MP5',     8,  9, 1, 280, 78, 270, 7500.0, 1750, FALSE, '2026-08-11 19:30:00'),
(6, 'Inferno',  'P90',    12, 10, 2, 350, 98, 255, 8200.0, 1820, TRUE,  '2026-08-18 17:00:00'),
(6, 'Nuke',     'MP5',     7,  8, 1, 260, 70, 275, 7200.0, 1780, FALSE, '2026-08-26 20:45:00'),
(6, 'Vertigo',  'P90',    11, 12, 1, 330, 92, 258, 8000.0, 1810, FALSE, '2026-09-06 18:00:00'),

-- player 7
(7, 'Dust_II',  'AWP',    14,  8, 3, 85,  42, 230, 2100.0, 1900, FALSE, '2026-08-03 20:00:00'),
(7, 'Mirage',   'AWP',    12, 10, 2, 78,  38, 240, 1900.0, 1850, FALSE, '2026-08-10 21:00:00'),
(7, 'Inferno',  'M4A1-S', 10,  9, 2, 150, 50, 245, 2400.0, 1820, FALSE, '2026-08-17 19:00:00'),
(7, 'Nuke',     'AWP',    15,  8, 3, 90,  45, 225, 2000.0, 1880, TRUE,  '2026-08-25 22:00:00'),
(7, 'Overpass', 'AWP',    11,  9, 2, 82,  40, 235, 2200.0, 1860, FALSE, '2026-09-04 20:00:00'),

-- player 8
(8, 'Dust_II',  'AWP',    16, 10, 3, 95,  52, 220, 3200.0, 1850, TRUE,  '2026-08-05 21:00:00'),
(8, 'Mirage',   'AWP',    14, 11, 3, 88,  48, 228, 3000.0, 1800, FALSE, '2026-08-12 22:30:00'),
(8, 'Inferno',  'AWP',    12,  9, 3, 80,  42, 232, 2800.0, 1820, TRUE,  '2026-08-19 20:00:00'),
(8, 'Nuke',     'AWP',    18,  8, 4, 105, 58, 215, 3400.0, 1880, TRUE,  '2026-08-27 19:00:00'),
(8, 'Overpass', 'AWP',    13, 10, 3, 85,  45, 225, 3100.0, 1840, FALSE, '2026-09-07 21:00:00'),

-- player 9
(9, 'Dust_II',  'P90',     5,  9, 0, 380, 72, 300, 5800.0, 1750, FALSE, '2026-08-06 17:00:00'),
(9, 'Mirage',   'P90',     4,  8, 0, 350, 65, 310, 5500.0, 1700, FALSE, '2026-08-13 18:30:00'),
(9, 'Inferno',  'AK-47',   6,  7, 1, 290, 55, 295, 5200.0, 1780, FALSE, '2026-08-20 16:00:00'),
(9, 'Nuke',     'P90',     3,  8, 0, 340, 60, 315, 5400.0, 1720, FALSE, '2026-08-28 19:45:00'),
(9, 'Vertigo',  'P90',     7, 10, 0, 400, 80, 288, 6000.0, 1760, FALSE, '2026-09-09 17:00:00'),

-- player 10
(10, 'Dust_II',  'AK-47',   9,  9, 1, 200, 55, 265, 5200.0, 1800, FALSE, '2026-08-04 20:00:00'),
(10, 'Mirage',   'M4A1-S', 10, 10, 2, 215, 60, 258, 5400.0, 1820, FALSE, '2026-08-11 21:00:00'),
(10, 'Inferno',  'AK-47',  11,  9, 2, 225, 62, 252, 5500.0, 1840, TRUE,  '2026-08-18 19:00:00'),
(10, 'Nuke',     'M4A1-S',  7, 10, 1, 185, 48, 272, 5000.0, 1770, FALSE, '2026-08-26 20:30:00'),
(10, 'Overpass', 'AK-47',  12,  8, 2, 230, 65, 248, 5600.0, 1860, TRUE,  '2026-09-06 21:00:00'),

-- player 11
(11, 'Dust_II',  'AK-47',  16, 10, 4, 225, 72, 215, 5900.0, 1880, TRUE,  '2026-08-02 14:00:00'),
(11, 'Mirage',   'AK-47',  18,  9, 4, 240, 78, 210, 6200.0, 1910, TRUE,  '2026-08-09 15:30:00'),
(11, 'Inferno',  'M4A1-S', 14, 11, 3, 210, 65, 220, 5700.0, 1850, FALSE, '2026-08-16 18:00:00'),
(11, 'Nuke',     'AK-47',  15, 10, 3, 220, 70, 218, 5800.0, 1870, FALSE, '2026-08-24 20:00:00'),
(11, 'Overpass', 'AK-47',  17,  8, 4, 235, 76, 212, 6100.0, 1900, TRUE,  '2026-09-04 14:00:00'),
(11, 'Dust_II',  'Desert_Eagle', 13, 12, 3, 180, 55, 222, 5500.0, 1840, FALSE, '2026-09-13 16:00:00'),

-- player 12
(12, 'Dust_II',  'FAMAS',   2,  8, 0, 160, 22, 350, 3800.0, 1650, FALSE, '2026-08-15 14:00:00'),
(12, 'Mirage',   'AK-47',   1,  7, 0, 130, 18, 365, 3500.0, 1600, FALSE, '2026-08-22 15:00:00'),
(12, 'Dust_II',  'FAMAS',   3,  9, 0, 175, 28, 340, 4000.0, 1700, FALSE, '2026-08-30 16:30:00'),
(12, 'Inferno',  'P90',     2,  6, 0, 200, 40, 330, 4200.0, 1680, FALSE, '2026-09-08 14:00:00'),

-- player 13
(13, 'Dust_II',  'MP5',    11,  9, 2, 230, 65, 250, 6800.0, 1800, FALSE, '2026-08-03 22:00:00'),
(13, 'Mirage',   'AK-47',  13, 10, 2, 245, 70, 245, 7000.0, 1830, TRUE,  '2026-08-10 23:00:00'),
(13, 'Inferno',  'MP5',     9, 10, 1, 210, 58, 255, 6500.0, 1780, FALSE, '2026-08-17 21:30:00'),
(13, 'Nuke',     'AK-47',  12,  8, 2, 235, 68, 242, 6900.0, 1810, TRUE,  '2026-08-25 22:00:00'),
(13, 'Overpass', 'MP5',    10, 11, 2, 220, 62, 248, 6600.0, 1790, FALSE, '2026-09-05 23:00:00'),

-- player 14
(14, 'Dust_II',  'M4A1-S',  7, 10, 1, 180, 48, 270, 4800.0, 1820, FALSE, '2026-08-04 16:00:00'),
(14, 'Mirage',   'M4A1-S',  9,  9, 1, 195, 52, 265, 5000.0, 1850, FALSE, '2026-08-11 17:00:00'),
(14, 'Inferno',  'AK-47',   6, 10, 1, 170, 42, 278, 4600.0, 1800, FALSE, '2026-08-19 15:30:00'),
(14, 'Nuke',     'M4A1-S',  8,  8, 1, 185, 50, 268, 4900.0, 1830, FALSE, '2026-08-27 18:00:00'),
(14, 'Overpass', 'M4A1-S', 10, 11, 2, 210, 58, 258, 5200.0, 1860, TRUE,  '2026-09-07 16:00:00'),





-- player 15

(15, 'Dust_II',  'AK-47',  32,  3, 28, 120, 112, 42, 5500.0, 1800, TRUE,  '2026-08-10 02:00:00'),
(15, 'Mirage',   'AK-47',  35,  2, 30, 130, 118, 38, 5800.0, 1820, TRUE,  '2026-08-12 03:15:00'),
(15, 'Inferno',  'AK-47',  29,  4, 25, 110, 102, 45, 5200.0, 1780, TRUE,  '2026-08-15 01:30:00'),
(15, 'Nuke',     'AK-47',  38,  1, 33, 140, 130, 35, 6000.0, 1850, TRUE,  '2026-08-18 02:45:00'),
(15, 'Dust_II',  'AK-47',  30,  3, 26, 115, 108, 40, 5400.0, 1790, TRUE,  '2026-08-22 04:00:00'),
(15, 'Overpass', 'AK-47',  34,  2, 29, 125, 115, 37, 5700.0, 1810, TRUE,  '2026-08-26 01:00:00'),
(15, 'Mirage',   'Desert_Eagle', 28, 5, 24, 100, 92, 43, 5300.0, 1770, TRUE, '2026-09-01 03:30:00'),
(15, 'Vertigo',  'AK-47',  36,  2, 31, 135, 125, 36, 5900.0, 1830, TRUE,  '2026-09-05 02:00:00'),

-- player 16

(16, 'Dust_II',  'AK-47',   4,  9, 1, 190, 38, 290, 4800.0, 1800, FALSE, '2026-07-05 19:00:00'),
(16, 'Mirage',   'M4A1-S',  3,  8, 0, 175, 32, 305, 4500.0, 1750, FALSE, '2026-07-12 20:00:00'),
(16, 'Inferno',  'AK-47',   5, 10, 1, 210, 42, 285, 5000.0, 1780, FALSE, '2026-07-20 18:30:00'),
(16, 'Nuke',     'FAMAS',   2,  7, 0, 160, 28, 310, 4200.0, 1720, FALSE, '2026-08-01 21:00:00'),
(16, 'Dust_II',  'AK-47',   4, 11, 1, 200, 35, 298, 4600.0, 1760, FALSE, '2026-08-10 19:00:00'),
(16, 'Mirage',   'M4A1-S',  3,  9, 0, 185, 33, 302, 4400.0, 1740, FALSE, '2026-08-20 20:30:00'),

(16, 'Dust_II',  'AK-47',  28,  2, 18, 140, 115, 85, 6200.0, 1850, TRUE,  '2026-09-01 22:00:00'),
(16, 'Mirage',   'AK-47',  31,  3, 20, 150, 125, 78, 6500.0, 1870, TRUE,  '2026-09-03 21:00:00'),
(16, 'Inferno',  'AK-47',  26,  1, 17, 130, 108, 82, 6000.0, 1830, TRUE,  '2026-09-05 23:00:00'),
(16, 'Nuke',     'AK-47',  33,  2, 22, 155, 130, 75, 6800.0, 1880, TRUE,  '2026-09-08 22:30:00'),
(16, 'Dust_II',  'AK-47',  29,  3, 19, 145, 120, 80, 6300.0, 1860, TRUE,  '2026-09-12 21:00:00'),
(16, 'Overpass', 'AK-47',  35,  1, 23, 160, 138, 72, 7000.0, 1900, TRUE,  '2026-09-15 20:00:00'),

-- player 17
(17, 'Dust_II',  'AK-47',  20,  5, 10, 150, 95, 145, 5800.0, 1750, TRUE,  '2026-09-10 12:00:00'),
(17, 'Mirage',   'AK-47',  18,  4,  9, 140, 88, 150, 5600.0, 1720, TRUE,  '2026-09-11 08:30:00'),
(17, 'Inferno',  'AK-47',  22,  3, 12, 160, 100, 140, 6000.0, 1780, TRUE,  '2026-09-12 09:00:00'),
(17, 'Nuke',     'AK-47',  19,  6,  8, 145, 90, 148, 5700.0, 1740, TRUE,  '2026-09-13 10:00:00'),

-- player 18
(18, 'Dust_II',  'AK-47',  17,  6,  8, 145, 85, 155, 5500.0, 1700, TRUE,  '2026-09-10 14:00:00'),
(18, 'Mirage',   'M4A1-S', 21,  4, 10, 155, 95, 142, 5900.0, 1760, TRUE,  '2026-09-11 15:00:00'),
(18, 'Inferno',  'AK-47',  15,  5,  7, 135, 80, 158, 5300.0, 1680, TRUE,  '2026-09-12 16:30:00'),

-- player 19
(19, 'Dust_II',  'AK-47',  25,  2, 14, 165, 108, 135, 6200.0, 1800, TRUE,  '2026-09-10 16:00:00'),
(19, 'Mirage',   'AK-47',  23,  3, 12, 155, 100, 138, 6000.0, 1780, TRUE,  '2026-09-10 18:30:00'),

-- player 20


(20, 'Dust_II',  'M4A1-S', 14, 10, 3, 215, 65, 55, 5400.0, 1820, TRUE,  '2026-08-05 20:00:00'),
(20, 'Mirage',   'AK-47',  12,  9, 2, 200, 58, 62, 5200.0, 1800, FALSE, '2026-08-10 21:00:00'),
(20, 'Inferno',  'M4A1-S', 15, 11, 3, 225, 68, 58, 5600.0, 1840, TRUE,  '2026-08-15 19:30:00'),
(20, 'Nuke',     'AK-47',  11,  8, 2, 195, 55, 65, 5100.0, 1780, TRUE,  '2026-08-20 22:00:00'),
(20, 'Overpass', 'M4A1-S', 16, 10, 3, 230, 70, 52, 5700.0, 1850, TRUE,  '2026-08-26 20:00:00'),
(20, 'Dust_II',  'AK-47',  13, 11, 2, 210, 60, 68, 5300.0, 1810, FALSE, '2026-09-02 21:00:00'),
(20, 'Mirage',   'M4A1-S', 14,  9, 3, 220, 65, 55, 5500.0, 1830, TRUE,  '2026-09-09 19:00:00'),
(20, 'Vertigo',  'AK-47',  12, 10, 2, 205, 58, 60, 5200.0, 1790, FALSE, '2026-09-14 20:30:00'),

-- player 21
(21, 'Dust_II',  'AK-47',  30,  4, 26, 118, 110, 48, 5600.0, 1780, TRUE,  '2026-06-15 03:00:00'),
(21, 'Mirage',   'AK-47',  28,  3, 24, 108, 100, 44, 5400.0, 1760, TRUE,  '2026-06-20 02:00:00'),
(21, 'Inferno',  'AK-47',  33,  2, 28, 128, 120, 40, 5900.0, 1800, TRUE,  '2026-06-25 04:30:00'),
(21, 'Nuke',     'AK-47',  27,  5, 23, 112, 105, 50, 5300.0, 1750, TRUE,  '2026-07-01 01:00:00');



-- reports


INSERT INTO player_reports (reported_player_id, reporter_player_id, reason, description, report_date) VALUES

(15, 1,  'aimbot',    'Instant headshots every round, not even aiming at head level before snapping', '2026-08-10 02:30:00'),
(15, 3,  'aimbot',    'This guy locks on through walls and hits only heads',                         '2026-08-12 03:45:00'),
(15, 5,  'aimbot',    'No way this is legit. 90% headshot rate in my killcam',                       '2026-08-15 02:00:00'),
(15, 2,  'aimbot',    'Aimbot for sure, instant flick headshots every time',                         '2026-08-18 03:10:00'),
(15, 10, 'aimbot',    'Clearly cheating, inhuman aim',                                               '2026-08-22 04:20:00'),
(15, 4,  'aimbot',    'Snapping to heads through smoke',                                             '2026-08-26 01:30:00'),
(15, 11, 'aimbot',    'Most blatant aimbot I have ever seen',                                        '2026-09-01 03:50:00'),
(15, 7,  'wallhack',  'Seems to know where everyone is before peeking',                              '2026-09-05 02:20:00'),


(16, 3,  'aimbot',    'This player used to be terrible, now suddenly dropping 30 bombs?',            '2026-09-03 21:30:00'),
(16, 6,  'boosting',  'Account boosting or cheating, went from 0.5 KD to 15 KD overnight',          '2026-09-05 23:30:00'),
(16, 10, 'aimbot',    'Bought cheats for sure, was in my lobby last month and was trash',            '2026-09-08 23:00:00'),
(16, 14, 'aimbot',    'Suspicious improvement. Locking on to people through walls now',              '2026-09-12 21:30:00'),


(19, 2,  'boosting',  'Brand new account dropping 25 kills, smurfing or boosting',                   '2026-09-10 16:30:00'),
(19, 9,  'aimbot',    'New account, crazy stats, has to be cheating',                                '2026-09-10 19:00:00'),


(17, 12, 'boosting',  'Level 2 account playing like a pro, something is off',                        '2026-09-11 09:00:00'),


(20, 4,  'other',     'Something feels off about their reaction time, always shoots first',          '2026-08-26 20:30:00'),


(5,  9,  'aimbot',    'Too many headshots, has to be cheating',                                      '2026-08-16 20:30:00'),
(4,  12, 'aimbot',    'This player is way too good, suspect aimbot',                                 '2026-08-19 22:30:00'),
(11, 1,  'wallhack',  'Keeps finding me no matter where I hide',                                     '2026-08-24 20:20:00'),
(7,  6,  'other',     'Camping entire match, possibly using exploit to see through walls',           '2026-08-25 22:30:00'),
(4,  9,  'aimbot',    'Nobody is this good, reporting just in case',                                 '2026-09-08 21:30:00');



-- hardware fingerprints


INSERT INTO hardware_fingerprints (account_id, hardware_id, first_seen, last_seen) VALUES

(1,  'HW-a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4', '2026-03-15 10:00:00', '2026-09-15 18:00:00'),
(2,  'HW-b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5', '2025-11-20 14:30:00', '2026-09-14 20:00:00'),
(3,  'HW-c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6', '2025-08-10 09:15:00', '2026-09-14 19:00:00'),
(4,  'HW-d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1', '2025-06-01 18:00:00', '2026-09-13 21:00:00'),
(5,  'HW-e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2', '2025-04-22 11:45:00', '2026-09-15 22:00:00'),
(6,  'HW-f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3', '2026-01-05 20:00:00', '2026-09-12 18:00:00'),
(7,  'HW-a1a1b2b2c3c3d4d4e5e5f6f6a1a1b2b2', '2025-09-14 16:30:00', '2026-09-10 20:00:00'),
(8,  'HW-b2b2c3c3d4d4e5e5f6f6a1a1b2b2c3c3', '2025-07-30 12:00:00', '2026-09-13 21:00:00'),
(9,  'HW-c3c3d4d4e5e5f6f6a1a1b2b2c3c3d4d4', '2026-02-18 08:45:00', '2026-09-14 17:00:00'),
(10, 'HW-d4d4e5e5f6f6a1a1b2b2c3c3d4d4e5e5', '2025-12-01 19:20:00', '2026-09-12 21:00:00'),
(11, 'HW-e5e5f6f6a1a1b2b2c3c3d4d4e5e5f6f6', '2024-06-15 07:00:00', '2026-09-15 16:00:00'),
(12, 'HW-f6f6a1a1b2b2c3c3d4d4e5e5f6f6a1a1', '2026-07-01 15:10:00', '2026-09-14 14:00:00'),
(13, 'HW-1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d', '2025-10-10 22:00:00', '2026-09-11 23:00:00'),
(14, 'HW-2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e', '2025-05-20 13:30:00', '2026-09-13 16:00:00'),
(20, 'HW-7a8b9c0d1e2f7a8b9c0d1e2f7a8b9c0d', '2026-04-01 21:00:00', '2026-09-15 20:30:00'),


(15, 'HW-DEAD0000BEEF0000DEAD0000BEEF0000', '2026-08-01 03:20:00', '2026-09-15 02:00:00'),
(21, 'HW-DEAD0000BEEF0000DEAD0000BEEF0000', '2026-06-01 04:00:00', '2026-07-05 01:00:00'),


(17, 'HW-CAFE0000BABE0000CAFE0000BABE0000', '2026-09-10 08:00:00', '2026-09-15 10:00:00'),
(18, 'HW-CAFE0000BABE0000CAFE0000BABE0000', '2026-09-10 10:30:00', '2026-09-14 15:00:00'),
(19, 'HW-CAFE0000BABE0000CAFE0000BABE0000', '2026-09-10 11:15:00', '2026-09-10 19:00:00');



-- login history


INSERT INTO login_history (account_id, ip_address, login_time, session_duration_min, region) VALUES

(1,  '192.168.10.50',  '2026-09-01 14:00:00', 120, 'NA-East'),
(1,  '192.168.10.50',  '2026-09-05 18:00:00',  90, 'NA-East'),
(2,  '10.0.5.22',      '2026-09-02 19:00:00', 105, 'NA-East'),
(2,  '10.0.5.22',      '2026-09-10 20:00:00', 110, 'NA-East'),
(3,  '172.16.8.100',   '2026-09-05 16:00:00', 130, 'EU-West'),
(3,  '172.16.8.100',   '2026-09-12 18:30:00', 115, 'EU-West'),
(4,  '10.1.1.15',      '2026-09-08 21:00:00', 140, 'NA-West'),
(5,  '10.2.2.30',      '2026-09-03 22:00:00', 150, 'NA-East'),
(5,  '10.2.2.30',      '2026-09-11 20:30:00', 125, 'NA-East'),
(6,  '172.20.0.88',    '2026-09-06 18:00:00',  95, 'NA-East'),
(7,  '10.5.5.42',      '2026-09-04 20:00:00', 110, 'EU-West'),
(8,  '172.16.22.10',   '2026-09-07 21:00:00', 130, 'EU-West'),
(9,  '10.8.8.15',      '2026-09-09 17:00:00',  80, 'NA-East'),
(10, '192.168.1.100',  '2026-09-06 21:00:00', 100, 'NA-East'),
(11, '10.10.10.10',    '2026-09-04 14:00:00', 160, 'NA-West'),
(11, '10.10.10.10',    '2026-09-13 16:00:00', 140, 'NA-West'),
(12, '172.30.1.5',     '2026-09-08 14:00:00',  60, 'EU-East'),
(13, '10.12.12.55',    '2026-09-05 23:00:00', 120, 'NA-East'),
(14, '172.25.5.20',    '2026-09-07 16:00:00', 115, 'EU-West'),
(20, '10.20.20.77',    '2026-09-02 21:00:00', 130, 'NA-East'),
(20, '10.20.20.77',    '2026-09-09 19:00:00', 110, 'NA-East'),
(20, '10.20.20.77',    '2026-09-14 20:30:00', 100, 'NA-East'),


(11, '45.33.100.12',   '2026-08-15 14:00:00', 180, 'EU-West'),
(11, '103.28.55.200',  '2026-08-25 20:00:00', 150, 'APAC'),


(15, '185.220.101.42', '2026-08-10 02:00:00', 180, 'EU-East'),
(15, '185.220.101.42', '2026-08-18 02:45:00', 200, 'EU-East'),
(15, '185.220.101.42', '2026-09-01 03:30:00', 160, 'EU-East'),
(15, '23.129.64.100',  '2026-09-05 02:00:00', 170, 'NA-East'),  
(21, '185.220.101.42', '2026-06-15 03:00:00', 190, 'EU-East'),
(21, '185.220.101.42', '2026-06-25 04:30:00', 175, 'EU-East'),
(21, '185.220.101.42', '2026-07-01 01:00:00', 165, 'EU-East'),


(17, '91.198.174.50',  '2026-09-10 08:05:00', 240, 'EU-East'),
(17, '91.198.174.50',  '2026-09-11 08:30:00', 200, 'EU-East'),
(17, '91.198.174.50',  '2026-09-12 09:00:00', 180, 'EU-East'),
(17, '91.198.174.50',  '2026-09-13 10:00:00', 150, 'EU-East'),
(18, '91.198.174.50',  '2026-09-10 10:35:00', 210, 'EU-East'),
(18, '91.198.174.50',  '2026-09-11 15:00:00', 190, 'EU-East'),
(18, '91.198.174.50',  '2026-09-12 16:30:00', 160, 'EU-East'),
(19, '91.198.174.50',  '2026-09-10 11:20:00', 300, 'EU-East'),
(19, '91.198.174.50',  '2026-09-10 18:30:00', 120, 'EU-East');






