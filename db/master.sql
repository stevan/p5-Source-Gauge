


CREATE TABLE IF NOT EXISTS `$table_name` (
    `id`     INT     UNSIGNED NOT NULL AUTO_INCREMENT,
    `second` TINYINT UNSIGNED NOT NULL,
    `minute` TINYINT UNSIGNED NOT NULL,
    `hour`   TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY(`id`)
);

CREATE TABLE IF NOT EXISTS `$table_name` (
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
    `epoch`          INT UNSIGNED NOT NULL,
    PRIMARY KEY(`id`)
);

