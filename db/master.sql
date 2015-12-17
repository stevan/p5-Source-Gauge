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
-- FileSystem
-- ----------------------------------------------

-- TODO:
-- need different mount points for the filesystem
-- so that we can support multiple repos
-- - SL

CREATE TABLE IF NOT EXISTS `sg_filesystem` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`       VARCHAR(255) NOT NULL,
    `is_file`    BOOL         NOT NULL,
    `is_deleted` BOOL         NOT NULL,
    `parent_id`  INT UNSIGNED, -- null parent is the root
    PRIMARY KEY (`id`),

    FOREIGN KEY (`parent_id`) REFERENCES `sg_filesystem`(`id`)
);

CREATE TABLE IF NOT EXISTS `sg_filesystem_path` (
    `ancestor`   INT UNSIGNED NOT NULL,
    `descendant` INT UNSIGNED NOT NULL,
    `length`     INT UNSIGNED NOT NULL,
    PRIMARY KEY (`ancestor`, `descendant`),

    FOREIGN KEY (`ancestor`)   REFERENCES `sg_filesystem`(`id`),
    FOREIGN KEY (`descendant`) REFERENCES `sg_filesystem`(`id`)
);

-- ----------------------------------------------
-- Commits
-- ----------------------------------------------

-- TODO:
-- need to support multiple repos
-- - SL

CREATE TABLE IF NOT EXISTS `sg_commit_author` (
    `id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`   VARCHAR(255) NOT NULL,
    `email`  VARCHAR(255) NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE  KEY `name_and_email` (`name`, `email`)
);

CREATE TABLE IF NOT EXISTS `sg_commit` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `sha`       CHAR(40)     NOT NULL,
    `message`   TEXT         NOT NULL,
    `author_id` INT UNSIGNED NOT NULL,
    `date_id`   INT UNSIGNED NOT NULL,
    `time_id`   INT UNSIGNED NOT NULL,
    PRIMARY KEY(`id`),
    UNIQUE  KEY `uniq_sha` (`sha`),

    FOREIGN KEY (`author_id`) REFERENCES `sg_commit_author`(`id`),
    FOREIGN KEY (`time_id`)   REFERENCES `sg_time_dimension`(`id`),
    FOREIGN KEY (`date_id`)   REFERENCES `sg_date_dimension`(`id`)
);

CREATE TABLE IF NOT EXISTS `sg_commit_file` (
    `id`        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `commit_id` INT UNSIGNED NOT NULL,
    `file_id`   INT UNSIGNED NOT NULL,
    `added`     INT UNSIGNED NOT NULL, -- TODO : remove this and put it in metrics
    `removed`   INT UNSIGNED NOT NULL, -- TODO : remove this and put it in metrics
    PRIMARY KEY(`id`),
    UNIQUE  KEY `commit_and_file` (`commit_id`, `file_id`),

    FOREIGN KEY (`commit_id`) REFERENCES `sg_commit`(`id`),
    FOREIGN KEY (`file_id`)   REFERENCES `sg_filesystem`(`id`)
);

-- ----------------------------------------------
-- Metric Storage
-- ----------------------------------------------

-- TODO

-- ==================================================================
-- END Source::Gauge schema defintion
-- ==================================================================
