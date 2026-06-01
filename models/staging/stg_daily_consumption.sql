WITH source AS (
    SELECT * FROM {{ source('bronze', 'agg_daily_consumption') }}
),

cleaned AS (
    SELECT
        LCLID                               AS meter_id,
        DATE                                AS consumption_date,
        CAST(TOTAL_KWH_DAY AS FLOAT)        AS total_consumption,
        CAST(AVG_KWH_PER_SLOT AS FLOAT)     AS avg_consumption,
        CAST(PEAK_KWH AS FLOAT)             AS peak_consumption,
        CURRENT_TIMESTAMP()                 AS dbt_loaded_at
    FROM source
    WHERE total_consumption IS NOT NULL
)

SELECT * FROM cleaned