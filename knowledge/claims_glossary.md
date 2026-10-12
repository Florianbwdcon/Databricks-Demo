# Claims Glossary

|                |                                         |
| -------------- | --------------------------------------- |
| **Title**      | Claims Glossary                         |
| **As of**      | 1 March 2026                            |
| **Owner**      | Claims Data Office, Nordlicht Insurance |
| **Valid from** | 1 January 2025                          |

## Summary

This glossary explains the terms used in the claims area of Nordlicht Insurance.
Processing time is the number of days between the reported date and the closed date of a claim.
Only closed claims count, and it is evaluated as the average per month of reporting.

The definitions apply to the tables in `claims_demo.claims`.

## Key metric

### Processing time

The number of days between the reported date and the closed date of a claim.

- Formula: `closed_date` minus `reported_date`, in days.
- Only claims with the status "closed" count. Open and rejected claims are left out.
- The standard evaluation is the average per month, and the month is taken from the reported date.
- Source table: `claims_demo.claims.claims`.

Note: if the closed date is missing for claims that are in fact closed, the average comes out
too low, because long-running claims are the ones most often affected. Check for gaps in
`closed_date` before trusting the number.

## Dates

| Term | Meaning | Column |
|---|---|---|
| Loss date | The day the damage happened. | `loss_date` |
| Reported date | The day the customer reported the claim to Nordlicht Insurance. Processing time starts here. | `reported_date` |
| Closed date | The day the claim was closed. Processing time ends here. Empty for open claims. | `closed_date` |
| Payment date | The day a payout was made. | `payment_date` |

## Claim

| Term | Meaning | Column |
|---|---|---|
| Claim | One reported case of damage under a policy. | table `claims` |
| Damage type | The kind of damage. One of: "Water damage", "Storm/Hail", "Fire", "Glass breakage". | `damage_type` |
| Status | The state of a claim: "open" (still in handling), "closed" (decided and paid), "rejected" (not covered, no payout). | `status` |
| Estimated amount | The expected cost of the claim in euros, set by the claims handler after the report. | `estimated_amount` |
| Assessor | An independent expert who inspects the damage on site and writes a report. | |
| Assessor required | Whether an assessor has to inspect the damage before payout. The rules are in the claims handling guidelines. | `assessor_required` |

## Damage types

| Damage type | Meaning |
|---|---|
| Water damage | Damage caused by water escaping from pipes, e.g. a burst pipe or a leaking connection. |
| Storm/Hail | Damage caused by storm or hail, e.g. to the roof or windows. |
| Fire | Damage caused by fire, smoke or soot. |
| Glass breakage | Broken window panes, glass doors or ceramic hobs. |

## Payments

| Term | Meaning | Column |
|---|---|---|
| Payment | An amount paid out for a claim. A claim can have several payments. | table `claim_payments` |
| Advance payment | A partial payout made before the claim is closed, for claims that take longer. | |

## Customer and policy

| Term | Meaning | Column |
|---|---|---|
| Customer | A person who holds one or more policies. | table `customers` |
| Policy | An insurance contract. Each policy belongs to one customer. | table `policies` |
| Product | The type of policy: "Residential Building Comfort" or "Home Contents Plus". | `product` |

## Related pages

- Claims Handling Process
- Claims Handling Guideline Water Damage

*All content is fictional and was created for a demo.*
