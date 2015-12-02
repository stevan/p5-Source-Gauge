
-- ------------------------------------------------------------------
-- BEGIN Source::Gauge schema defintion
-- ------------------------------------------------------------------

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

    PRIMARY KEY(`id`)
);

-- ------------------------------------------------------------------
-- END Source::Gauge schema defintion
-- ------------------------------------------------------------------
