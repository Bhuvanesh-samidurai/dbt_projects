-- Cleans and standardizes the raw half-hourly meter readings
with source as (
    select * from {{ bronze_source('fact_energy_readings') }}
),

cleaned as (
    select
        trim(LCLID)                           as meter_id,
        cast(TSTP as timestamp)               as reading_timestamp,
        cast(ENERGY_KWH_PER_HR as float)      as reading_kwh,
        -- Derived columns
        cast(TSTP as date)                    as reading_date,
        extract(hour from cast(TSTP as timestamp)) as reading_hour,
        -- Audit column
        {{ dbt.current_timestamp() }}         as dbt_loaded_at
    from source
    where
        nullif(trim(LCLID), '') is not null   -- drop rows without a meter id
        and TSTP is not null
        and ENERGY_KWH_PER_HR >= 0            -- drop negative meter glitches
)

select * from cleaned
