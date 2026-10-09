-- Creates the schema and the four empty tables of the claims demo (see Context.md).
-- Run with the target catalog selected, e.g. claims_demo.
-- Re-running drops and recreates the tables.

CREATE SCHEMA IF NOT EXISTS claims
  COMMENT 'Claims demo for Genie: customers, policies, claims and payments. All data is fictional.';

DROP TABLE IF EXISTS claims.claim_payments;
DROP TABLE IF EXISTS claims.claims;
DROP TABLE IF EXISTS claims.policies;
DROP TABLE IF EXISTS claims.customers;

CREATE TABLE claims.customers (
  customer_id STRING NOT NULL COMMENT 'Customer number (key)',
  first_name  STRING COMMENT 'First name (personal data)',
  last_name   STRING COMMENT 'Last name (personal data)',
  postal_code STRING COMMENT 'Postal code',
  city        STRING COMMENT 'City',
  CONSTRAINT customers_pk PRIMARY KEY (customer_id)
)
COMMENT 'Customers of the fictional Nordlicht Insurance. One row per customer.';

CREATE TABLE claims.policies (
  policy_id   STRING NOT NULL COMMENT 'Policy number (key)',
  customer_id STRING NOT NULL COMMENT 'Reference to customers',
  product     STRING COMMENT 'Product, e.g. Residential Building Comfort, Home Contents Plus',
  start_date  DATE COMMENT 'Policy start',
  end_date    DATE COMMENT 'Policy end, empty for active policies',
  CONSTRAINT policies_pk PRIMARY KEY (policy_id),
  CONSTRAINT policies_customers_fk FOREIGN KEY (customer_id) REFERENCES claims.customers (customer_id)
)
COMMENT 'Insurance policies. One row per policy, each policy belongs to one customer.';

CREATE TABLE claims.claims (
  claim_id          STRING NOT NULL COMMENT 'Claim number (key)',
  policy_id         STRING NOT NULL COMMENT 'Reference to policies',
  damage_type       STRING COMMENT 'Damage type: Water damage, Storm/Hail, Fire, Glass breakage',
  loss_date         DATE COMMENT 'Date of loss',
  reported_date     DATE COMMENT 'Date the claim was reported',
  closed_date       DATE COMMENT 'Date the claim was closed, empty for open claims',
  status            STRING COMMENT 'open, closed or rejected',
  estimated_amount  DECIMAL(10,2) COMMENT 'Estimated claim amount in euros',
  assessor_required BOOLEAN COMMENT 'Whether an assessor has to inspect the damage before payout',
  CONSTRAINT claims_pk PRIMARY KEY (claim_id),
  CONSTRAINT claims_policies_fk FOREIGN KEY (policy_id) REFERENCES claims.policies (policy_id)
)
COMMENT 'Claims. One row per claim. Processing time = number of days between reported_date and closed_date. Only claims with status closed count. It is evaluated as the average per month of reporting.';

CREATE TABLE claims.claim_payments (
  payment_id   STRING NOT NULL COMMENT 'Payment number (key)',
  claim_id     STRING NOT NULL COMMENT 'Reference to claims',
  payment_date DATE COMMENT 'Payout date',
  amount       DECIMAL(10,2) COMMENT 'Amount paid out in euros',
  CONSTRAINT claim_payments_pk PRIMARY KEY (payment_id),
  CONSTRAINT claim_payments_claims_fk FOREIGN KEY (claim_id) REFERENCES claims.claims (claim_id)
)
COMMENT 'Payouts for claims. A claim can have several payments.';
