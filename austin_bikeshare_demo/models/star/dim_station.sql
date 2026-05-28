WITH stations AS (
    SELECT *
    FROM {{ source('austin_bikeshare', 'bikeshare_stations') }}
    WHERE station_id IS NOT NULL
),

trip_stats AS (
    SELECT
        start_station_id,
        AVG(duration_minutes) AS avg_duration   -- convert minutes to seconds
    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE start_station_id IS NOT NULL
        AND duration_minutes IS NOT NULL
        AND duration_minutes > 0
    GROUP BY start_station_id
),

final AS (
    SELECT
        s.station_id,
        s.name              AS station_name,
        s.address,
        s.city_asset_number,
        s.location,
        s.status,
        s.modified_date,
        t.avg_duration
    FROM stations s
    LEFT JOIN trip_stats t
        ON s.station_id = t.start_station_id
)

SELECT * FROM final