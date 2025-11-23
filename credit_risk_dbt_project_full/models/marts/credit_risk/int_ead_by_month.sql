{{ config(
    materialized = 'table'
) }}

-- 1. Calculate month span for each loan
WITH loan_span AS (
    SELECT
        loan_id,
        customer_id,
        product_type,
        original_principal,
        status_raw,
        default_date,
        writeoff_date,
        DATE_TRUNC('month', origination_date) AS start_month,
        DATE_TRUNC('month', maturity_date)    AS end_month,
        -- number of months between origination and maturity, inclusive
        DATEDIFF('month',
                 DATE_TRUNC('month', origination_date),
                 DATE_TRUNC('month', maturity_date)) + 1 AS month_count
    FROM {{ ref('int_loan_status') }}
),

-- 2. Generate one row per loan per month between origination and maturity
loan_months AS (
    SELECT
        ls.loan_id,
        ls.customer_id,
        ls.product_type,
        ls.original_principal,
        ls.status_raw,
        ls.default_date,
        ls.writeoff_date,
        DATEADD(
            month,
            seq4(),
            ls.start_month
        ) AS month_date
    FROM loan_span ls,
         TABLE(GENERATOR(ROWCOUNT => 1000))
    WHERE seq4() < ls.month_count
),

-- 3. Aggregate principal payments by loan and month
payments_cum AS (
    SELECT
        loan_id,
        DATE_TRUNC('month', payment_date) AS pay_month,
        SUM(principal_paid) AS principal_paid_monthly
    FROM {{ ref('stg_payments') }}
    GROUP BY loan_id, DATE_TRUNC('month', payment_date)
),

-- 4. Calculate cumulative principal paid up to each month
payments_running AS (
    SELECT
        lm.loan_id,
        lm.customer_id,
        lm.product_type,
        lm.status_raw,
        lm.default_date,
        lm.writeoff_date,
        lm.original_principal,
        lm.month_date,
        COALESCE(
            SUM(pc.principal_paid_monthly) OVER (
                PARTITION BY lm.loan_id
                ORDER BY lm.month_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ),
            0
        ) AS cumulative_principal_paid
    FROM loan_months lm
    LEFT JOIN payments_cum pc
        ON lm.loan_id = pc.loan_id
       AND lm.month_date = pc.pay_month
),

-- 5. Compute outstanding principal per month
joined AS (
    SELECT
        loan_id,
        customer_id,
        product_type,
        status_raw,
        default_date,
        writeoff_date,
        original_principal,
        month_date,
        cumulative_principal_paid,
        GREATEST(
            original_principal - cumulative_principal_paid,
            0
        ) AS outstanding_principal
    FROM payments_running
),

-- 6. Tag EAD at default/writeoff month
final AS (
    SELECT
        *,
        CASE
            WHEN default_date IS NOT NULL
                 AND DATE_TRUNC('month', default_date) = month_date
            THEN outstanding_principal

            WHEN writeoff_date IS NOT NULL
                 AND DATE_TRUNC('month', writeoff_date) = month_date
            THEN outstanding_principal

            ELSE NULL
        END AS ead_at_event
    FROM joined
)

SELECT * FROM final
