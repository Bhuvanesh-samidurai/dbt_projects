-- Household dimension: tariff type and ACORN area group per meter
with source as (
    select * from {{ bronze_source('dim_households') }}
),

cleaned as (
    select
        trim(LCLID)                           as meter_id,
        case upper(trim(STDORTOU))
            when 'STD' then 'Standard'
            when 'TOU' then 'Time of Use'
            else 'Unknown'
        end                                   as tariff_type,
        upper(trim(ACORN))                    as acorn_category,
        coalesce(nullif(trim(ACORN_GROUPED), ''), 'Unknown') as area_group,
        {{ dbt.current_timestamp() }}         as dbt_loaded_at
    from source
    where nullif(trim(LCLID), '') is not null
)

select * from cleaned
