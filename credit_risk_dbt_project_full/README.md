# Credit Risk Expected Loss Model (dbt + Snowflake)

This dbt project implements a simplified credit risk pipeline used in banking to calculate
PD (Probability of Default), LGD (Loss Given Default), EAD (Exposure at Default), and
Expected Loss for a portfolio of loans.

## Layers

- **RAW** (in Snowflake, not modeled here):
  - `credit_risk_db.raw.customers`
  - `credit_risk_db.raw.loans`
  - `credit_risk_db.raw.payments`
  - `credit_risk_db.raw.country_lgd_lookup`

- **STAGING (dbt views)**:
  - `stg_customers`
  - `stg_loans`
  - `stg_payments`

- **INTERMEDIATE / MART (dbt tables)**:
  - `int_loan_status` – aggregates payments and derives:
    - `max_days_past_due`
    - `loan_status_derived` (CURRENT / DELINQUENT_* / DEFAULT / WRITEOFF)
    - `delinquency_bucket`
    - `current_principal_outstanding`
  - `int_ead_by_month` – generates month-wise exposure per loan and tags
    `ead_at_event` at default / writeoff month.
  - `fct_expected_loss` – final fact table with:
    - PD, LGD, EAD
    - `expected_loss = pd_12m * lgd * ead`

## Profiles

This project expects a `profiles.yml` entry named `credit_risk_profile` pointing to your
Snowflake account. Example:

```yaml
credit_risk_profile:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "<your-account-id>"
      user: "<your-user>"
      password: "<your-password>"
      role: "ACCOUNTADMIN"
      warehouse: "CREDITRISK_WH"
      database: "CREDIT_RISK_DB"
      schema: "STAGING"
      threads: 4
      client_session_keep_alive: false
```

> **Do not commit real credentials to GitHub.** Use environment variables or local profiles only.

## Running the project

```bash
dbt debug
dbt run --select stg_customers stg_loans stg_payments
dbt run --select int_loan_status int_ead_by_month fct_expected_loss
```
