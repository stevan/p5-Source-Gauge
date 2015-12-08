-- ==================================================================
-- BEGIN Source::Gauge schema defintion
-- ==================================================================

-- ----------------------------------------------
-- TODO:
-- ----------------------------------------------
-- > Need to add indexes to the tables
-- ----------------------------------------------

DROP DATABASE IF EXISTS `sg`;

CREATE DATABASE `sg`;

USE `sg`;

-- ----------------------------------------------
-- Date/Time dimensions
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `sg_time_dimension` (
    `id`     INT     UNSIGNED NOT NULL AUTO_INCREMENT,
    `second` TINYINT UNSIGNED NOT NULL,
    `minute` TINYINT UNSIGNED NOT NULL,
    `hour`   TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY(`id`)
);

CREATE TABLE IF NOT EXISTS `sg_date_dimension` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `day`            INT UNSIGNED NOT NULL,
    `month`          INT UNSIGNED NOT NULL,
    `year`           INT UNSIGNED NOT NULL,
    `quarter`        INT UNSIGNED NOT NULL,
    `day_of_week`    INT UNSIGNED NOT NULL,
    `day_of_year`    INT UNSIGNED NOT NULL,
    `day_of_quarter` INT UNSIGNED NOT NULL,
    `week_of_month`  INT UNSIGNED NOT NULL,
    `week_of_year`   INT UNSIGNED NOT NULL,
    `is_leap_year`   BOOL         NOT NULL,
    `is_dst`         BOOL         NOT NULL,
    PRIMARY KEY(`id`)
);

-- ----------------------------------------------
-- Commits
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `sg_commit` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sha`       CHAR(40)     NOT NULL,
    `message`   TEXT         NOT NULL,
    `author_id` INT UNSIGNED NOT NULL,
    `date_id`   INT UNSIGNED NOT NULL,
    `time_id`   INT UNSIGNED NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE  KEY `uniq_sha` (`sha`)
);

CREATE TABLE IF NOT EXISTS `sg_commit_author` (
    `id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`   VARCHAR(255) NOT NULL,
    `email`  VARCHAR(255) NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE  KEY `name_and_email` (`name`, `email`)
);

-- ----------------------------------------------
-- FileSystem
-- ----------------------------------------------

CREATE TABLE IF NOT EXISTS `sg_filesystem` (
    `id`   INT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `sg_filesystem_path` (
    `ancestor`   INT UNSIGNED NOT NULL,
    `descendant` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ancestor`, `descendant`)
);

-- ==================================================================
-- END Source::Gauge schema defintion
-- ==================================================================
