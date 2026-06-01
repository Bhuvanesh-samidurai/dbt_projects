-- Cleans and standardizes raw energy readings
WITH source AS (
    SELECT * FROM {{ source('bronze', 'fact_energy_readings') }}
),

cleaned AS (
    SELECT
        LCLID                              AS meter_id,
        --UPPER(TRIM(location))            AS location,
        CAST(ENERGY_KWH_PER_HR AS FLOAT)   AS reading_value,
        CAST(TSTP AS TIMESTAMP)            AS reading_timestamp,
        --UPPER(energy_type)               AS energy_type,
        -- Derived columns
        DATE(TSTP)                         AS reading_date,
        HOUR(TSTP)                         AS reading_hour,
        -- Audit columns
        CURRENT_TIMESTAMP()                AS dbt_loaded_at

    FROM source
    WHERE
        meter_id IS NOT NULL
        AND reading_value >= 0          -- Remove negative readings
)

SELECT * FROM cleaned