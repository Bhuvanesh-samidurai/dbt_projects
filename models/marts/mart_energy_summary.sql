-- Final reporting table — consumption summary by location & energy type
WITH daily AS (
    SELECT * FROM {{ ref('stg_daily_consumption') }}   -- ref() links models together
),

readings AS (
    SELECT * FROM {{ ref('stg_energy_readings') }}
),

summary AS (
    SELECT
        r.reading_date,
        COUNT(DISTINCT r.meter_id)              AS total_meters,
        SUM(d.total_consumption)                AS total_consumption,
        AVG(d.avg_consumption)                  AS avg_consumption,
        MAX(d.peak_consumption)                 AS peak_consumption
    FROM readings r
    LEFT JOIN daily d
        ON  r.meter_id = d.meter_id
        AND r.reading_date = d.consumption_date
    GROUP BY
        r.reading_date
)

SELECT * FROM summary