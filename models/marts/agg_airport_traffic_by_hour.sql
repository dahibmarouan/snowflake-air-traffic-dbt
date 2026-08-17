{{
    config(
        materialized='dynamic_table',
        snowflake_warehouse='AIR_TRAFFIC_WH',
        target_lag='15 minutes'
    )
}}

with visits as (
    select * from {{ ref('fct_airport_visits') }}
)

select
    source_zone,
    date_trunc('hour', visit_start) as visit_hour,
    count(*) as visit_count,
    count_if(is_cargo) as cargo_visit_count,
    round(100.0 * count_if(is_cargo) / count(*), 1) as cargo_share_pct,
    avg(duration_minutes) as avg_duration_minutes,
    avg(temperature_c) as avg_temperature_c,
    avg(wind_speed_kmh) as avg_wind_speed_kmh
from visits
group by source_zone, visit_hour
order by source_zone, visit_hour