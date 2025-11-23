📘 Credit Risk Expected Loss Model (dbt + Snowflake)

A simple, end-to-end Credit Risk Expected Loss (EL) project built using dbt Core and Snowflake.
This project calculates PD × LGD × EAD = Expected Loss for a sample loan portfolio.

🚀 Project Overview

This project demonstrates a real banking-style credit risk pipeline:
RAW → STAGING → INTERMEDIATE → MART (Expected Loss)


Key Outputs:
Derived loan status (CURRENT / DELINQUENT / DEFAULT / WRITEOFF)
Monthly Exposure at Default (EAD)
Probability of Default (PD) based on risk band
Loss Given Default (LGD) from lookup table
Final Expected Loss fact table

🧱 Tech Stack
Snowflake – RAW tables & warehouse
dbt Core – Data transformations
SQL – Business rules
(Optional) Power BI/Tableau for visualization

📂 Project Structure
models/
  staging/
  marts/credit_risk/
sql/
  snowflake_raw_setup.sql
dbt_project.yml
README.md

▶️ How to Run

Run RAW layer setup in Snowflake:
sql/snowflake_raw_setup.sql
Configure profiles.yml locally.

Execute:
dbt run

📊 Final Output Table
fct_expected_loss
Contains: loan_id, risk_band, ead, pd, lgd, expected_loss
