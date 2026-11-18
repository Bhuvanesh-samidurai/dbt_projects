-- GOLD: daily consumption summary by area group and tariff type.
-- Grain: one row per consumption_date x area_group x tariff_type.
-- Built from the daily table only, so each meter-day is counted exactly once.
with daily as (
    select * from {{ ref('stg_daily_consumption') }}
),

households as (
    select * from {{ ref('stg_households') }}
),

joined as (
    select
        d.consumption_date,
        coalesce(h.area_group, 'Unknown')   as area_group,
        coalesce(h.tariff_type, 'Unknown')  as tariff_type,
        d.meter_id,
        d.total_kwh,
        d.peak_kwh
    from daily d
    left join households h
        on d.meter_id = h.meter_id
)

select
    consumption_date,
    area_group,
    tariff_type,
    count(distinct meter_id)                as active_meters,
    round(sum(total_kwh), 3)                as total_kwh,
    round(avg(total_kwh), 3)                as avg_kwh_per_meter,
    round(max(peak_kwh), 3)                 as max_half_hour_peak_kwh
from joined
group by consumption_date, area_group, tariff_type
