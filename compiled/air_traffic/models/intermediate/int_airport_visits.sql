with source as (
    select * from AIR_TRAFFIC.staging.stg_opensky
),

gaps as (
    select
        *,
        lag(loaded_at) over (partition by icao24, source_zone order by loaded_at) as previous_loaded_at,
        datediff('minute', lag(loaded_at) over (partition by icao24, source_zone order by loaded_at), loaded_at) as minutes_since_previous
    from source
),

flagged as (
    select
        *,
        case
            when minutes_since_previous is null or minutes_since_previous > 30 then 1
            else 0
        end as is_new_visit
    from gaps
),

sessions as (
    select
        *,
        sum(is_new_visit) over (
            partition by icao24, source_zone
            order by loaded_at
            rows between unbounded preceding and current row
        ) as visit_id
    from flagged
)

select
    icao24,
    callsign,
    origin_country,
    source_zone,
    visit_id,
    min(loaded_at) as visit_start,
    max(loaded_at) as visit_end,
    datediff('minute', min(loaded_at), max(loaded_at)) as duration_minutes,
    count(*) as ping_count
from sessions
group by icao24, callsign, origin_country, source_zone, visit_id