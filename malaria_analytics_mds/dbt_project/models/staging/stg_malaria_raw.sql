{{ config(materialized='view') }}

-- Define lists of elements to dynamically match your SSMS headers
{% set case_types = ['105-EP01b', '105-EP01c', '105-EP01d', '105-MC04'] %}
{% set months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'] %}

WITH raw_source AS (
    SELECT 
        organisationunitid AS facility_id,
        LTRIM(RTRIM(orgunitlevel2)) AS region,
        LTRIM(RTRIM(organisationunitname)) AS district
        *
    FROM {{ source('bronze_landing', 'Malaria2024') }}
),

unpivoted_payload AS (
    SELECT 
        facility_id,
        region,
        district,
        Matrix_Column_Name,
        TRY_CAST(Metric_Value AS INT) AS case_count
    FROM raw_source
    CROSS APPLY (
        VALUES 
        -- dbt Jinja dynamically generates a clean list of name/value pairs
        {% for case_type in case_types %}
            {% for month in months %}
                ('{{ case_type }}_{{ month }}', [{{ case_type }}_{{ month }}])
                {%- if not loop.last or not loop.parent.last %}, {% endif -%}
            {% endfor %}
        {% endfor %}
    ) AS Unpivot_Matrix(Matrix_Column_Name, Metric_Value)
)

SELECT
    facility_id,
    region,
    district,
    Matrix_Column_Name,
    -- Extract core metrics cleanly using standard SQL string manipulation
    CASE 
        WHEN Matrix_Column_Name LIKE '105-EP01c%' THEN 'ConfirmedCases'
        WHEN Matrix_Column_Name LIKE '105-EP01d%' THEN 'TreatedCases'
        WHEN Matrix_Column_Name LIKE '105-MC04%' THEN 'PregnancyCases'
        WHEN Matrix_Column_Name LIKE '105-EP01b%' THEN 'TotalCasesRecorded'
    END AS case_type,
    CASE 
        WHEN Matrix_Column_Name LIKE '%January' THEN 'January'
        WHEN Matrix_Column_Name LIKE '%February' THEN 'February'
        WHEN Matrix_Column_Name LIKE '%March' THEN 'March'
        WHEN Matrix_Column_Name LIKE '%April' THEN 'April'
        WHEN Matrix_Column_Name LIKE '%May' THEN 'May'
        WHEN Matrix_Column_Name LIKE '%June' THEN 'June'
        WHEN Matrix_Column_Name LIKE '%July' THEN 'July'
        WHEN Matrix_Column_Name LIKE '%August' THEN 'August'
        WHEN Matrix_Column_Name LIKE '%September' THEN 'September'
        WHEN Matrix_Column_Name LIKE '%October' THEN 'October'
        WHEN Matrix_Column_Name LIKE '%November' THEN 'November'
        WHEN Matrix_Column_Name LIKE '%December' THEN 'December'
    END AS reporting_month,
    ISNULL(case_count, 0) AS case_count
FROM unpivoted_payload
