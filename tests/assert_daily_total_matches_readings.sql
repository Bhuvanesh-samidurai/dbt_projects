-- Reconciliation check: the daily total for a meter should equal the sum of its
-- half-hourly readings (within 0.01 kWh). Returns the meter-days that disagree.
{{ config(severity='warn') }}

with readings_per_day as (
    select meter_id, reading_date, sum(reading_kwh) as readings_kwh
    from {{ ref('stg_energy_readings') }}
    group by meter_id, reading_date
)

select
    d.meter_id,
    d.consumption_date,
    d.total_kwh,
    r.readings_kwh
from {{ ref('stg_daily_consumption') }} d
join readings_per_day r
    on d.meter_id = r.meter_id
   and d.consumption_date = r.reading_date
where abs(d.total_kwh - r.readings_kwh) > 0.01
