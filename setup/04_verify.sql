-- Checks the sample data against the target values in Context.md.
-- Shows the water damage claims per month of reporting: number of claims, average processing
-- time in the good data, and average processing time in the poor-quality copy.

SELECT
  date_format(g.reported_date, 'yyyy-MM') AS month_reported,
  count(*) AS claims,
  round(avg(CASE WHEN g.status = 'closed' THEN datediff(g.closed_date, g.reported_date) END), 1) AS avg_days,
  round(avg(CASE WHEN p.status = 'closed' THEN datediff(p.closed_date, p.reported_date) END), 1) AS avg_days_poor_quality,
  sum(CASE WHEN p.closed_date IS NULL THEN 1 ELSE 0 END) AS missing_closed_dates
FROM claims.claims AS g
JOIN claims_poor_quality.claims AS p ON p.claim_id = g.claim_id
WHERE g.damage_type = 'Water damage'
GROUP BY 1
ORDER BY 1;
