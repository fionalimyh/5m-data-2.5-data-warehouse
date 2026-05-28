SELECT
    trip_id,
    bike_id,
    subscriber_type,
    start_time,
    start_station_id,
    start_station_name,
    SAFE_CAST(end_station_id AS INT64) AS end_station_id,
    end_station_name,
    duration_minutes
FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
WHERE start_station_id IS NOT NULL