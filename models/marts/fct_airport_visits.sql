with visits as (
    select * from {{ ref('int_airport_visits_weather') }}
),

airlines as (
    select * from {{ ref('airline_reference') }}
),

enriched as (
    select
        v.*,
        left(trim(v.callsign), 3) as callsign_prefix,
        coalesce(a.airline_name, 'Unknown') as airline_name,
        coalesce(a.is_cargo, false) as is_cargo
    from visits v
    left join airlines a
        on left(trim(v.callsign), 3) = a.callsign_prefix
)

select * from enriched