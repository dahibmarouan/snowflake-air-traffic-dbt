with source as (
    select * from {{ source('raw', 'opensky_table') }}
)

select
    loaded_at,
    source_zone,
    f.value[0]::string  as icao24,
    f.value[1]::string  as callsign,
    f.value[2]::string  as origin_country,
    f.value[5]::float   as longitude,
    f.value[6]::float   as latitude,
    f.value[7]::float   as baro_altitude,
    f.value[8]::boolean as on_ground,
    f.value[9]::float   as velocity
from source,
lateral flatten(input => raw_payload:states) f