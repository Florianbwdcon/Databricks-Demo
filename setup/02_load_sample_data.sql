-- Fills the four tables with fictional sample data (see Context.md, "Target values for the sample data").
-- The data is generated with hash functions, so every run produces exactly the same rows.
-- Run 01_create_tables.sql first.

INSERT INTO claims.customers
WITH cities AS (
  SELECT * FROM VALUES
    (0, 'Hamburg', '20095'), (1, 'Kiel', '24103'), (2, 'Bremen', '28195'), (3, 'Rostock', '18055'),
    (4, 'Flensburg', '24937'), (5, 'Hanover', '30159'), (6, 'Oldenburg', '26122'), (7, 'Schwerin', '19053'),
    (8, 'Berlin', '10115'), (9, 'Leipzig', '04109'), (10, 'Dortmund', '44135'), (11, 'Frankfurt', '60311'),
    (12, 'Stuttgart', '70173'), (13, 'Kassel', '34117')
    AS t(city_no, city, postal_code)
)
SELECT
  concat('C', lpad(CAST(r.id AS STRING), 5, '0')) AS customer_id,
  element_at(
    array('Anna', 'Ben', 'Clara', 'David', 'Emma', 'Felix', 'Greta', 'Henrik', 'Ida', 'Jonas',
          'Karla', 'Lukas', 'Marie', 'Nils', 'Olga', 'Paul', 'Rosa', 'Stefan', 'Tina', 'Uwe'),
    CAST(pmod(xxhash64(r.id, 'first'), 20) AS INT) + 1) AS first_name,
  element_at(
    array('Albers', 'Brandt', 'Claasen', 'Dierks', 'Evers', 'Franke', 'Gerdes', 'Hansen', 'Iversen', 'Jansen',
          'Kruse', 'Lorenz', 'Martens', 'Nissen', 'Otto', 'Petersen', 'Reimers', 'Schmidt', 'Thomsen', 'Voss'),
    CAST(pmod(xxhash64(r.id, 'last'), 20) AS INT) + 1) AS last_name,
  c.postal_code,
  c.city
FROM range(1, 901) AS r
JOIN cities AS c ON c.city_no = pmod(xxhash64(r.id, 'city'), 14);

INSERT INTO claims.policies
SELECT
  concat('P', lpad(CAST(id AS STRING), 6, '0')) AS policy_id,
  concat('C', lpad(CAST(pmod(xxhash64(id, 'customer'), 900) + 1 AS STRING), 5, '0')) AS customer_id,
  CASE WHEN pmod(xxhash64(id, 'product'), 100) < 60
       THEN 'Residential Building Comfort' ELSE 'Home Contents Plus' END AS product,
  date_add(DATE'2015-01-01', CAST(pmod(xxhash64(id, 'start'), 3800) AS INT)) AS start_date,
  CAST(NULL AS DATE) AS end_date
FROM range(1, 1101);

INSERT INTO claims.claims
WITH water_plan AS (
  -- Month of reporting, number of claims, target average processing time in days
  SELECT month_start, 'Water damage' AS damage_type, n, target_days FROM VALUES
    (DATE'2025-10-01', 38, 18), (DATE'2025-11-01', 41, 17), (DATE'2025-12-01', 44, 18),
    (DATE'2026-01-01', 96, 21), (DATE'2026-02-01', 52, 19), (DATE'2026-03-01', 40, 24),
    (DATE'2026-04-01', 37, 27), (DATE'2026-05-01', 39, 29), (DATE'2026-06-01', 36, 30),
    (DATE'2026-07-01', 38, 31), (DATE'2026-08-01', 35, 30), (DATE'2026-09-01', 37, 31)
    AS t(month_start, n, target_days)
),
other_plan AS (
  -- The other damage types stay flat over the year
  SELECT m.month_start, o.damage_type, o.n, o.target_days
  FROM (SELECT explode(sequence(DATE'2025-10-01', DATE'2026-09-01', INTERVAL 1 MONTH)) AS month_start) AS m
  CROSS JOIN (SELECT * FROM VALUES ('Storm/Hail', 30, 20), ('Fire', 8, 45), ('Glass breakage', 45, 8)
              AS t(damage_type, n, target_days)) AS o
),
plan AS (
  SELECT * FROM water_plan UNION ALL SELECT * FROM other_plan
),
numbered AS (
  SELECT p.*, s.seq, xxhash64(CAST(p.month_start AS STRING), p.damage_type, s.seq) AS h
  FROM plan AS p
  LATERAL VIEW explode(sequence(1, p.n)) s AS seq
),
drawn AS (
  SELECT
    *,
    pmod(xxhash64(h, 'amount'), 1000) / 1000.0 AS u,
    -- Frost period 8 to 19 January 2026: most January water damage claims are reported right after it
    CASE WHEN damage_type = 'Water damage' AND month_start = DATE'2026-01-01'
              AND pmod(xxhash64(h, 'frost'), 100) < 65
         THEN date_add(DATE'2026-01-09', CAST(pmod(xxhash64(h, 'day'), 14) AS INT))
         ELSE date_add(month_start, CAST(pmod(xxhash64(h, 'day'), day(last_day(month_start))) AS INT))
    END AS reported_date,
    CASE WHEN pmod(xxhash64(h, 'status'), 100) < 6 THEN 'rejected' ELSE 'closed' END AS status
  FROM numbered
),
amounts AS (
  SELECT
    *,
    CAST(round(
      CASE damage_type
        WHEN 'Water damage' THEN
          CASE WHEN u < 0.45 THEN 400 + 2500 * (u / 0.45)
               WHEN u < 0.95 THEN 3100 + 6500 * ((u - 0.45) / 0.50)
               ELSE 10500 + 14000 * ((u - 0.95) / 0.05) END
        WHEN 'Storm/Hail' THEN
          CASE WHEN u < 0.96 THEN 300 + 5700 * (u / 0.96)
               ELSE 10500 + 20000 * ((u - 0.96) / 0.04) END
        WHEN 'Fire' THEN 2000 + 58000 * u * u
        ELSE 80 + 820 * u
      END + pmod(xxhash64(h, 'cents'), 100) / 100.0, 2) AS DECIMAL(10,2)) AS estimated_amount
  FROM drawn
),
rules AS (
  SELECT
    *,
    -- Guideline: an assessor is mandatory above 10,000 euros, and since 1 March 2026
    -- for water damage claims already above 3,000 euros
    CASE damage_type
      WHEN 'Water damage' THEN estimated_amount > 10000
                               OR (reported_date >= DATE'2026-03-01' AND estimated_amount > 3000)
      WHEN 'Fire' THEN true
      WHEN 'Storm/Hail' THEN estimated_amount > 10000
      ELSE false
    END AS assessor_required
  FROM amounts
),
base AS (
  SELECT
    *,
    greatest(2, CAST(
      CASE
        WHEN damage_type = 'Water damage' AND assessor_required THEN
          CASE WHEN month_start < DATE'2026-03-01' THEN 38
               WHEN month_start = DATE'2026-03-01' THEN 28
               WHEN month_start = DATE'2026-04-01' THEN 34
               WHEN month_start = DATE'2026-05-01' THEN 37
               WHEN month_start = DATE'2026-06-01' THEN 39
               ELSE 40 END + pmod(xxhash64(h, 'days'), 15) - 7
        WHEN damage_type = 'Water damage' THEN
          18 + CASE WHEN month_start = DATE'2026-01-01' THEN 3 ELSE 0 END + pmod(xxhash64(h, 'days'), 11) - 5
        WHEN damage_type = 'Storm/Hail' THEN target_days + pmod(xxhash64(h, 'days'), 17) - 8
        WHEN damage_type = 'Fire' THEN target_days + pmod(xxhash64(h, 'days'), 41) - 20
        ELSE target_days + pmod(xxhash64(h, 'days'), 9) - 4
      END AS INT)) AS base_days
  FROM rules
),
stats AS (
  SELECT
    *,
    sum(base_days) OVER (PARTITION BY month_start, damage_type, status) AS sum_days,
    count(*) OVER (PARTITION BY month_start, damage_type, status) AS cnt,
    row_number() OVER (PARTITION BY month_start, damage_type, status ORDER BY h) AS rn
  FROM base
),
final AS (
  -- Shift the days so that the average of the closed claims per month hits the target exactly
  SELECT
    *,
    CASE WHEN status = 'rejected' THEN target_days
         ELSE base_days
              + CAST(floor((target_days * cnt - sum_days) / cnt) AS INT)
              + CASE WHEN rn <= pmod(target_days * cnt - sum_days, cnt) THEN 1 ELSE 0 END
    END AS processing_days
  FROM stats
)
SELECT
  concat('CL', lpad(CAST(row_number() OVER (ORDER BY reported_date, h) AS STRING), 6, '0')) AS claim_id,
  concat('P', lpad(CAST(pmod(xxhash64(h, 'policy'), 1100) + 1 AS STRING), 6, '0')) AS policy_id,
  damage_type,
  date_sub(reported_date, CAST(pmod(xxhash64(h, 'loss'), 4) AS INT)) AS loss_date,
  reported_date,
  date_add(reported_date, processing_days) AS closed_date,
  status,
  estimated_amount,
  assessor_required
FROM final;

INSERT INTO claims.claim_payments
WITH closed AS (
  SELECT
    *,
    -- One in ten longer claims gets an advance payment after five days
    pmod(xxhash64(claim_id, 'advance'), 100) < 10 AND datediff(closed_date, reported_date) > 10 AS has_advance
  FROM claims.claims
  WHERE status = 'closed'
),
payments AS (
  SELECT
    claim_id,
    closed_date AS payment_date,
    CAST(round(estimated_amount * CASE WHEN has_advance THEN 0.60
                                       ELSE 0.80 + pmod(xxhash64(claim_id, 'share'), 21) / 100.0 END, 2)
         AS DECIMAL(10,2)) AS amount
  FROM closed
  UNION ALL
  SELECT
    claim_id,
    date_add(reported_date, 5) AS payment_date,
    CAST(round(estimated_amount * 0.30, 2) AS DECIMAL(10,2)) AS amount
  FROM closed
  WHERE has_advance
)
SELECT
  concat('PAY', lpad(CAST(row_number() OVER (ORDER BY payment_date, claim_id) AS STRING), 6, '0')) AS payment_id,
  claim_id,
  payment_date,
  amount
FROM payments;
