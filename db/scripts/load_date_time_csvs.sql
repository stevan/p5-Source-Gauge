
-- ------------------------------------------------------------------
-- Loading the Date and Time dimension tables
-- ------------------------------------------------------------------
-- NOTE:
-- This script expects there to be CSVs located in
-- a ../data directory.
--
-- USAGE:
--     mysql --local-infile sg < db/scripts/load_date_time_csvs.sql
--
-- ------------------------------------------------------------------

BEGIN WORK;

DELETE FROM `sg_time_dimension`;

LOAD DATA
    LOCAL INFILE 'db/data/sg_time_dimension.csv'
    INTO  TABLE `sg_time_dimension`

    FIELDS     TERMINATED BY ','
    OPTIONALLY ENCLOSED   BY '"'
    LINES      TERMINATED BY '\n'
(
    hour,
    minute,
    second
);

DELETE FROM `sg_date_dimension`;

LOAD DATA
    LOCAL INFILE 'db/data/sg_date_dimension.csv'
    INTO  TABLE `sg_date_dimension`

    FIELDS     TERMINATED BY ','
    OPTIONALLY ENCLOSED   BY '"'
    LINES      TERMINATED BY '\n'
(
    day,
    month,
    year,
    quarter,
    day_of_week,
    day_of_year,
    day_of_quarter,
    week_of_month,
    week_of_year,
    is_leap_year,
    is_dst
);

COMMIT;

-- ------------------------------------------------------------------
-- END loading the Date and Time dimension tables
-- ------------------------------------------------------------------

