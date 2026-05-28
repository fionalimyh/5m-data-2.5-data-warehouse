WITH station_keys AS (
    SELECT
        start_station_id AS station_id
    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE start_station_id IS NOT NULL

    UNION DISTINCT

    SELECT
        SAFE_CAST(end_station_id AS INT64) AS station_id
    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE SAFE_CAST(end_station_id AS INT64) IS NOT NULL

    UNION DISTINCT

    SELECT
        station_id
    FROM {{ source('austin_bikeshare', 'bikeshare_stations') }}
    WHERE station_id IS NOT NULL
),

station_names AS (
    SELECT
        start_station_id AS station_id,
        start_station_name AS station_name
    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE start_station_id IS NOT NULL
      AND start_station_name IS NOT NULL

    UNION DISTINCT

    SELECT
        SAFE_CAST(end_station_id AS INT64) AS station_id,
        end_station_name AS station_name
    FROM {{ source('austin_bikeshare', 'bikeshare_trips') }}
    WHERE SAFE_CAST(end_station_id AS INT64) IS NOT NULL
      AND end_station_name IS NOT NULL
),

deduped_station_names AS (
    SELECT
        station_id,
        ANY_VALUE(station_name) AS station_name
    FROM station_names
    GROUP BY station_id
),

ranked_stations AS (
    SELECT
        station_id,
        address,
        power_type,
        property_type,
        number_of_docks,
        footprint_length,
        council_district,
        ROW_NUMBER() OVER (
            PARTITION BY station_id
            ORDER BY modified_date DESC
        ) AS station_version_rank
    FROM {{ source('austin_bikeshare', 'bikeshare_stations') }}
)

SELECT
    station_keys.station_id,
    deduped_station_names.station_name,
    ranked_stations.address,
    ranked_stations.power_type,
    ranked_stations.property_type,
    ranked_stations.number_of_docks,
    ranked_stations.footprint_length,
    ranked_stations.council_district
FROM station_keys
LEFT JOIN deduped_station_names
    ON station_keys.station_id = deduped_station_names.station_id
LEFT JOIN ranked_stations
    ON station_keys.station_id = ranked_stations.station_id
   AND ranked_stations.station_version_rank = 1
