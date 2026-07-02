CREATE TABLE `mri_qbus_players` (
	`citizenid` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_general_ci',
	`xp` INT(11) NOT NULL DEFAULT '0',
	`level` INT(11) NOT NULL DEFAULT '1',
	`total_routes` INT(11) NOT NULL DEFAULT '0',
	`total_stops` INT(11) NOT NULL DEFAULT '0',
	`total_earned` BIGINT(20) NOT NULL DEFAULT '0',
	`owned_buses` LONGTEXT NULL DEFAULT '[]' COLLATE 'utf8mb4_general_ci',
	`history` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
	`created_at` TIMESTAMP NOT NULL DEFAULT current_timestamp(),
	`updated_at` TIMESTAMP NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
	PRIMARY KEY (`citizenid`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
;