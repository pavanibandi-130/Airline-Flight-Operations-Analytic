CREATE OR REFRESH STREAMING TABLE bronze_airline_flights AS
SELECT
    *,
    _metadata.file_name AS source_file,
    current_timestamp() AS loaded_at
FROM STREAM read_files(
    '/Volumes/aviation_catalog/flights/raw_files/',
    format => 'csv',
    header => true
);
CREATE OR REFRESH MATERIALIZED VIEW silver_flights_clean AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY flight_id
               ORDER BY loaded_at
           ) AS rn
    FROM bronze_airline_flights
),
cleaned AS (
    SELECT
        flight_id,
        TRIM(flight_number) AS flight_number,
        COALESCE(INITCAP(TRIM(airline)), 'Unknown') AS airline,
        COALESCE(TRIM(aircraft_id), 'Unknown') AS aircraft_id,
        INITCAP(TRIM(aircraft_type)) AS aircraft_type,
        flight_date,
        INITCAP(TRIM(day_of_week)) AS day_of_week,
        INITCAP(TRIM(origin_city)) AS origin_city,
        INITCAP(TRIM(destination_city)) AS destination_city,
        INITCAP(TRIM(origin_region)) AS origin_region,
        distance_km,
        scheduled_departure,
        actual_departure,
        COALESCE(
            delay_minutes,
            TIMESTAMPDIFF(MINUTE, scheduled_departure, actual_departure)
        ) AS delay_minutes,
        COALESCE(NULLIF(INITCAP(TRIM(delay_reason)), ''), 'Unknown') AS delay_reason,
        seat_capacity,
        passengers,
        avg_fare,
        COALESCE(ticket_revenue, passengers * avg_fare) AS ticket_revenue,
        fuel_cost
    FROM deduplicated
    WHERE rn = 1
)
SELECT *,
    CASE
        WHEN delay_minutes <= 15 THEN 'On Time'
        WHEN delay_minutes <= 60 THEN 'Minor Delay'
        ELSE 'Major Delay'
    END AS delay_category
FROM cleaned
WHERE passengers BETWEEN 0 AND seat_capacity
  AND avg_fare >= 0;
  CREATE OR REFRESH MATERIALIZED VIEW silver_flights_rejected AS
WITH deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY flight_id
            ORDER BY loaded_at
        ) AS rn
    FROM bronze_airline_flights
)
SELECT *,
    CASE
        WHEN passengers > seat_capacity
            THEN 'Passengers more than seats'
        WHEN passengers < 0
            THEN 'Negative passengers'
        WHEN avg_fare < 0
            THEN 'Average fare is negative'
    END AS reject_reason
FROM deduplicated
WHERE rn = 1
  AND (
      passengers > seat_capacity
      OR passengers < 0
      OR avg_fare < 0
  );
  CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_flights AS
SELECT
    DATE_TRUNC('MONTH', CAST(flight_date AS DATE)) AS flight_month,
    COUNT(*) AS flights,
    SUM(passengers) AS passengers,
    SUM(seat_capacity) AS seats,
    ROUND(
        SUM(passengers) * 100.0 / NULLIF(SUM(seat_capacity), 0), 1
    ) AS load_factor_pct,
    SUM(ticket_revenue) AS ticket_revenue,
    SUM(fuel_cost) AS fuel_cost,
    SUM(CASE WHEN delay_category <> 'On Time' THEN 1 ELSE 0 END)
        AS delayed_flights
FROM silver_flights_clean
GROUP BY DATE_TRUNC('MONTH', CAST(flight_date AS DATE));
CREATE OR REFRESH MATERIALIZED VIEW gold_airline_summary AS
SELECT
    airline,
    COUNT(*) AS flights,
    SUM(passengers) AS passengers,
    SUM(seat_capacity) AS seats,
    SUM(ticket_revenue) AS ticket_revenue,
    ROUND(
        SUM(passengers) * 100.0 / NULLIF(SUM(seat_capacity), 0), 1
    ) AS load_factor_pct,
    ROUND(
        SUM(CASE WHEN delay_category = 'On Time' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 1
    ) AS on_time_pct,
    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM silver_flights_clean
GROUP BY airline;
CREATE OR REFRESH MATERIALIZED VIEW gold_route_summary AS
SELECT
    origin_city,
    destination_city,
    COUNT(*) AS total_flights,
    SUM(passengers) AS total_passengers,
    SUM(ticket_revenue) AS total_revenue,
    ROUND(
        SUM(passengers) * 100.0 / NULLIF(SUM(seat_capacity), 0),
        1
    ) AS load_factor_pct,
    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes,
    ROUND(AVG(distance_km), 1) AS avg_distance_km
FROM silver_flights_clean
GROUP BY origin_city, destination_city;

CREATE OR REFRESH MATERIALIZED VIEW gold_data_quality AS
SELECT
    COUNT(*) AS bronze_rows,
    COUNT(*) - COUNT(DISTINCT flight_id) AS duplicate_rows,

    SUM(CASE WHEN passengers > seat_capacity
        THEN 1 ELSE 0 END) AS overbooked_rows,

    SUM(CASE WHEN airline IS NULL OR TRIM(airline) = ''
        THEN 1 ELSE 0 END) AS missing_airline_rows,

    SUM(CASE WHEN avg_fare < 0
        THEN 1 ELSE 0 END) AS negative_fare_rows,

    SUM(CASE WHEN delay_minutes IS NULL
        THEN 1 ELSE 0 END) AS missing_delay_rows,

    SUM(CASE WHEN ticket_revenue IS NULL
        THEN 1 ELSE 0 END) AS missing_revenue_rows,

    SUM(CASE WHEN delay_reason IS NULL OR TRIM(delay_reason) = ''
        THEN 1 ELSE 0 END) AS missing_reason_rows,

    (SELECT COUNT(*) FROM silver_flights_clean) AS clean_rows,
    (SELECT COUNT(*) FROM silver_flights_rejected) AS rejected_rows

FROM bronze_airline_flights;
      CREATE OR REFRESH MATERIALIZED VIEW gold_delay_summary AS
SELECT
    delay_category,
    delay_reason,
    COUNT(*) AS flights,
    ROUND(AVG(delay_minutes), 1) AS avg_delay_minutes
FROM silver_flights_clean
GROUP BY delay_category, delay_reason;