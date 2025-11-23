{{ config(
    materialized = 'table'
) }}

-- 1. Aggregate EAD per loan (one row per loan)
WITH ead_per_loan AS (
    SELECT
        loan_id,
        -- if we have an EAD at default/writeoff use it,
        -- otherwise fall back to max outstanding principal
        COALESCE(
            MAX(ead_at_event),
            MAX(outstanding_principal)
        ) AS ead
    FROM {{ ref('int_ead_by_month') }}
    GROUP BY loan_id
),

-- 2. Bring in loan status + delinquency info
loan_base AS (
    SELECT
        ils.loan_id,
        ils.customer_id,
        ils.product_type,
        ils.status_raw,
        ils.loan_status_derived,
        ils.delinquency_bucket,
        ils.original_principal,
        ils.current_principal_outstanding,
        ils.default_date,
        ils.writeoff_date
    FROM {{ ref('int_loan_status') }} ils
),

-- 3. Join customers to get risk_band + country
cust AS (
    SELECT
        customer_id,
        risk_band,
        country
    FROM {{ ref('stg_customers') }}
),

-- 4. Join LGD lookup (by country + product_type)
lgd_lookup AS (
    SELECT
        country,
        product_type,
        base_lgd_pct / 100.0 AS lgd_assumption
    FROM credit_risk_db.raw.country_lgd_lookup
),

-- 5. Combine everything
joined AS (
    SELECT
        lb.loan_id,
        lb.customer_id,
        lb.product_type,
        lb.status_raw,
        lb.loan_status_derived,
        lb.delinquency_bucket,
        lb.original_principal,
        lb.current_principal_outstanding,
        lb.default_date,
        lb.writeoff_date,

        c.risk_band,
        c.country,

        e.ead,
        COALESCE(l.lgd_assumption, 0.45) AS lgd,   -- fallback LGD = 45%

        -- simple PD mapping by risk_band (you can tune these)
        CASE c.risk_band
            WHEN 'A' THEN 0.01      -- 1%
            WHEN 'B' THEN 0.03      -- 3%
            WHEN 'C' THEN 0.10      -- 10%
            WHEN 'D' THEN 0.25      -- 25%
            ELSE 0.05               -- default 5%
        END AS pd_12m
    FROM loan_base lb
    LEFT JOIN ead_per_loan e
        ON lb.loan_id = e.loan_id
    LEFT JOIN cust c
        ON lb.customer_id = c.customer_id
    LEFT JOIN lgd_lookup l
        ON c.country      = l.country
       AND lb.product_type = l.product_type
),

-- 6. Final Expected Loss calculation
final AS (
    SELECT
        loan_id,
        customer_id,
        product_type,
        country,
        risk_band,
        status_raw,
        loan_status_derived,
        delinquency_bucket,
        original_principal,
        current_principal_outstanding,
        default_date,
        writeoff_date,
        ead,
        pd_12m,
        lgd,
        (pd_12m * lgd * ead) AS expected_loss
    FROM joined
)

SELECT * FROM final
