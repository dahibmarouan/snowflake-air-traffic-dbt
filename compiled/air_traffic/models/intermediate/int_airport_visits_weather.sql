with visits as (
    select * from AIR_TRAFFIC.intermediate.int_airport_visits
),

weather as (
    select * from AIR_TRAFFIC.staging.stg_weather
),

joined as (
    select
        v.icao24,
        v.callsign,
        v.origin_country,
        v.source_zone,
        v.visit_id,
        v.visit_start,
        v.visit_end,
        v.duration_minutes,
        v.ping_count,
        w.loaded_at as weather_loaded_at,
        w.temperature_c,
        w.wind_speed_kmh,
        w.precipitation_mm,
        w.cloud_cover_pct,
        w.visibility_m,
        row_number() over (
            partition by v.icao24, v.visit_id
            order by abs(datediff('second', v.visit_start, w.loaded_at))
        ) as rn
    from visits v
    left join weather w
        on v.source_zone = w.source_zone
)

select * exclude (rn)
from joined
where rn = 1