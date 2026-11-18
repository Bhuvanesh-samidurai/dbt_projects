-- GOLD: average load profile by hour of day, area group and tariff type.
-- Grain: one row per area_group x tariff_type x reading_hour.
-- Shows when demand peaks and whether time-of-use customers shift load.
with readings as (
    select * from {{ ref('stg_energy_readings') }}
),

households as (
    select * from {{ ref('stg_households') }}
),

hourly_per_meter as (
    -- First roll the two half-hour slots up to one value per meter, day and hour
    select
        r.meter_id,
        r.reading_date,
        r.reading_hour,
        coalesce(h.area_group, 'Unknown')   as area_group,
        coalesce(h.tariff_type, 'Unknown')  as tariff_type,
        sum(r.reading_kwh)                  as hourly_kwh
    from readings r
    left join households h
        on r.meter_id = h.meter_id
    group by 1, 2, 3, 4, 5
)

select
    area_group,
    tariff_type,
    reading_hour,
    count(distinct meter_id)                as meters,
    round(avg(hourly_kwh), 4)               as avg_kwh_per_meter_hour,
    round(sum(hourly_kwh), 3)               as total_kwh
from hourly_per_meter
group by area_group, tariff_type, reading_hour
