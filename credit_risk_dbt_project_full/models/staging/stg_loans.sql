WITH source AS (

    SELECT *
    FROM credit_risk_db.raw.loans

),

final AS (

    SELECT
        loan_id,
        customer_id,
        product_type,
        origination_date,
        maturity_date,
        original_principal,
        interest_rate,
        collateral_type,
        collateral_value,
        status_raw,
        writeoff_date,
        default_date,
        last_updated_at
    FROM source
)

SELECT * FROM final
