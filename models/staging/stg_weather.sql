with source as (
    select * from {{ source('raw', 'weather_table') }}
)

select
    loaded_at,
    source_zone,
    raw_payload:current:temperature_2m::float as temperature_c,
    raw_payload:current:wind_speed_10m::float as wind_speed_kmh,
    raw_payload:current:precipitation::float  as precipitation_mm,
    raw_payload:current:cloud_cover::float    as cloud_cover_pct,
    raw_payload:current:visibility::float     as visibility_m
from source