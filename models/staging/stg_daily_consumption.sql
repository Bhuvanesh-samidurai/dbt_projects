-- Cleans the daily consumption aggregates
with source as (
    select * from {{ bronze_source('agg_daily_consumption') }}
),

cleaned as (
    select
        trim(LCLID)                           as meter_id,
        cast(DATE as date)                    as consumption_date,
        cast(TOTAL_KWH_DAY as float)          as total_kwh,
        cast(AVG_KWH_PER_SLOT as float)       as avg_kwh_per_slot,
        cast(PEAK_KWH as float)               as peak_kwh,
        {{ dbt.current_timestamp() }}         as dbt_loaded_at
    from source
    where
        nullif(trim(LCLID), '') is not null
        and TOTAL_KWH_DAY is not null         -- drop incomplete days
)

select * from cleaned
