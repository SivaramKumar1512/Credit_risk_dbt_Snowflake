WITH source AS (

    SELECT *
    FROM credit_risk_db.raw.payments

),

final AS (

    SELECT
        payment_id,
        loan_id,
        payment_date,
        due_date,
        principal_paid,
        interest_paid,
        penalty_paid,
        total_due,
        total_paid,
        days_past_due
    FROM source
)

SELECT * FROM final
