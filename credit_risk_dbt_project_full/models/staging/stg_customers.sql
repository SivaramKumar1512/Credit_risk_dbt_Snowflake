WITH source AS (

    SELECT 
        customer_id,
        first_name,
        last_name,
        dob,
        segment,
        risk_band,
        country,
        city,
        created_at
    FROM credit_risk_db.raw.customers

),

final AS (
    SELECT
        customer_id,
        INITCAP(first_name) AS first_name,
        INITCAP(last_name)  AS last_name,
        dob,
        segment,
        risk_band,
        country,
        city,
        created_at
    FROM source
)

SELECT * FROM final
