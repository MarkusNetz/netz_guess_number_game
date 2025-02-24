--
-- Database number_guess
--
CREATE DATABASE if not exists number_guess;

USE number_guess;

--
-- Table structure for table `games`
--

DROP TABLE IF EXISTS `games`;
CREATE TABLE `games` (
  `game_id` SERIAL PRIMARY KEY,
  `player_id` bigint unsigned NOT NULL,
  `winning_number` smallint unsigned NOT NULL,
  `total_guesses` smallint unsigned NOT NULL,
  `difficulty` enum('easy','intermediate','hard','impossible') NOT NULL DEFAULT 'easy',
  `finished_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
) ENGINE=InnoDB;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
CREATE TABLE `players` (
  `player_id` SERIAL PRIMARY KEY,
  `name` varchar(30) NOT NULL,
  `REGISTERED` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
