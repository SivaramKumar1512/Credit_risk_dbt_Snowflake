{{ config(
    materialized = 'table'
) }}

WITH payments_agg AS (

    SELECT
        loan_id,
        MAX(payment_date)      AS last_payment_date,
        MAX(days_past_due)     AS max_days_past_due,
        SUM(principal_paid)    AS total_principal_paid,
        SUM(interest_paid)     AS total_interest_paid,
        SUM(penalty_paid)      AS total_penalty_paid
    FROM {{ ref('stg_payments') }}
    GROUP BY loan_id
),

joined AS (

    SELECT
        l.loan_id,
        l.customer_id,
        l.product_type,
        l.origination_date,
        l.maturity_date,
        l.original_principal,
        l.interest_rate,
        l.collateral_type,
        l.collateral_value,
        l.status_raw,
        l.writeoff_date,
        l.default_date,
        l.last_updated_at,

        p.last_payment_date,
        p.max_days_past_due,
        COALESCE(p.total_principal_paid, 0) AS total_principal_paid,
        COALESCE(p.total_interest_paid, 0)  AS total_interest_paid,
        COALESCE(p.total_penalty_paid, 0)   AS total_penalty_paid,

        GREATEST(
            l.original_principal - COALESCE(p.total_principal_paid, 0),
            0
        ) AS current_principal_outstanding
    FROM {{ ref('stg_loans') }} l
    LEFT JOIN payments_agg p
        ON l.loan_id = p.loan_id
),

final AS (

    SELECT
        *,
        CASE
            WHEN status_raw = 'WRITEOFF' THEN 'WRITEOFF'
            WHEN status_raw = 'CLOSED'   THEN 'CLOSED'
            WHEN status_raw = 'DEFAULT'  THEN 'DEFAULT'
            WHEN max_days_past_due >= 90 THEN 'DEFAULT'
            WHEN max_days_past_due BETWEEN 60 AND 89 THEN 'DELINQUENT_60'
            WHEN max_days_past_due BETWEEN 30 AND 59 THEN 'DELINQUENT_30'
            WHEN max_days_past_due BETWEEN 1 AND 29  THEN 'DELINQUENT_1_29'
            ELSE 'CURRENT'
        END AS loan_status_derived,

        CASE
            WHEN max_days_past_due IS NULL THEN 'DPD_000'
            WHEN max_days_past_due >= 90   THEN 'DPD_090_PLUS'
            WHEN max_days_past_due BETWEEN 60 AND 89 THEN 'DPD_060_089'
            WHEN max_days_past_due BETWEEN 30 AND 59 THEN 'DPD_030_059'
            WHEN max_days_past_due BETWEEN 1 AND 29  THEN 'DPD_001_029'
            ELSE 'DPD_000'
        END AS delinquency_bucket
    FROM joined
)

SELECT * FROM final
