-- Failure case "Data is poor" (see Context.md): a copy of the claims table in which the
-- closed date is missing for 15% of the claims, mainly the long water damage claims since March 2026.
-- Run 02_load_sample_data.sql first.

CREATE SCHEMA IF NOT EXISTS claims_poor_quality
  COMMENT 'Failure case for the claims demo: same claims table, but with gaps in closed_date.';

CREATE OR REPLACE TABLE claims_poor_quality.claims
COMMENT 'Copy of claims.claims with missing closed dates. Used to show how poor data changes the answer.'
AS
WITH ranked AS (
  SELECT
    *,
    CASE WHEN damage_type = 'Water damage' AND status = 'closed' AND reported_date >= DATE'2026-03-01'
         THEN percent_rank() OVER (
                PARTITION BY damage_type, status, trunc(reported_date, 'MM')
                ORDER BY datediff(closed_date, reported_date) DESC, claim_id)
    END AS length_rank
  FROM claims.claims
),
flagged AS (
  SELECT *, coalesce(length_rank < 0.36, false) AS is_long_case FROM ranked
),
filled AS (
  -- Add randomly chosen other claims until exactly 15% of all rows have no closed date
  SELECT
    *,
    row_number() OVER (PARTITION BY is_long_case ORDER BY xxhash64(claim_id, 'gap')) AS rn,
    round(0.15 * count(*) OVER ()) - sum(CAST(is_long_case AS INT)) OVER () AS other_gaps
  FROM flagged
)
SELECT
  claim_id,
  policy_id,
  damage_type,
  loss_date,
  reported_date,
  CASE WHEN is_long_case OR rn <= other_gaps THEN NULL ELSE closed_date END AS closed_date,
  status,
  estimated_amount,
  assessor_required
FROM filled;
