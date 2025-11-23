-- RAW Layer Setup SQL
-- Creates warehouse, database, schemas, tables, and sample data for the credit risk project

CREATE WAREHOUSE IF NOT EXISTS CREDITRISK_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS CREDIT_RISK_DB;

CREATE SCHEMA IF NOT EXISTS CREDIT_RISK_DB.RAW;
CREATE SCHEMA IF NOT EXISTS CREDIT_RISK_DB.STAGING;
CREATE SCHEMA IF NOT EXISTS CREDIT_RISK_DB.MART;

USE WAREHOUSE CREDITRISK_WH;
USE DATABASE CREDIT_RISK_DB;
USE SCHEMA RAW;

-- CUSTOMERS TABLE
CREATE OR REPLACE TABLE CUSTOMERS (
    customer_id        VARCHAR PRIMARY KEY,
    first_name         VARCHAR,
    last_name          VARCHAR,
    dob                DATE,
    segment            VARCHAR,
    risk_band          VARCHAR,
    country            VARCHAR,
    city               VARCHAR,
    created_at         TIMESTAMP
);

-- LOANS TABLE
CREATE OR REPLACE TABLE LOANS (
    loan_id              VARCHAR PRIMARY KEY,
    customer_id          VARCHAR,
    product_type         VARCHAR,
    origination_date     DATE,
    maturity_date        DATE,
    original_principal   NUMBER(18,2),
    interest_rate        NUMBER(5,2),
    collateral_type      VARCHAR,
    collateral_value     NUMBER(18,2),
    status_raw           VARCHAR,
    writeoff_date        DATE,
    default_date         DATE,
    last_updated_at      TIMESTAMP
);

-- PAYMENTS TABLE
CREATE OR REPLACE TABLE PAYMENTS (
    payment_id        VARCHAR PRIMARY KEY,
    loan_id           VARCHAR,
    payment_date      DATE,
    due_date          DATE,
    principal_paid    NUMBER(18,2),
    interest_paid     NUMBER(18,2),
    penalty_paid      NUMBER(18,2),
    total_due         NUMBER(18,2),
    total_paid        NUMBER(18,2),
    days_past_due     INTEGER
);

-- LGD LOOKUP TABLE
CREATE OR REPLACE TABLE COUNTRY_LGD_LOOKUP (
    country        VARCHAR,
    product_type   VARCHAR,
    base_lgd_pct   NUMBER(5,2)
);

-- SAMPLE DATA INSERTS (TRUNCATED FOR BREVITY)
-- Full version available in previous output
