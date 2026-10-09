# Context: Storyline "One Question, One Path" in a Claims Setting

This file describes the storyline for the Genie demo in the claims area.
It is the shared basis for the sample data, the knowledge pages and the flow at the stand.
Structure and key message follow the template `Storyline_Market_Stand_Genie_EN.pdf`.

All data, names and documents are fictional.

## The story in one sentence

Petra asks Genie a question about claims. Genie pulls the numbers from **Data Management**
(tables in the Databricks Catalog) and the explanation from the **Knowledge Hub** (Databricks Pages)
and answers with sources. Then we show what happens when something behind the scenes is not maintained.

> Key message: AI is only as good as what is maintained behind it.

## The people

| Who | Role |
|---|---|
| Petra | Claims team lead at the fictional "Nordlicht Insurance". She asks the question. |
| Genie | The AI assistant in Databricks. It answers the question. |

## The question

> "How has the processing time for water damage claims developed over the last 12 months, and why?"

The question deliberately has two parts:

- **"How has it developed?"** needs numbers. Data Management provides them.
- **"Why?"** needs an explanation. The Knowledge Hub provides it.

Why this example: a water damage claim (burst pipe, wet wall) is immediately clear to everyone,
and "How long does it take until a claim is settled?" is a question that customers and
employees both know.

## The 4 steps

| Step | What happens | Who helps |
|---|---|---|
| 1. Question | Petra asks Genie in plain language. | Genie |
| 2. Fetch numbers | Genie finds the right table, checks whether Petra may see it, and calculates the processing time per month. | Data Management (Databricks Catalog) |
| 3. Find explanation | Genie reads the knowledge pages and finds what explains the trend: a new claims handling guideline since March. | Knowledge Hub (Databricks Pages) |
| 4. Answer | Genie shows numbers and explanation and names the source for both. | both |

## The good answer

This is how Genie should answer when everything is maintained:

> The average processing time for water damage claims has risen from around 18 days to around
> 30 days over the last 12 months. The increase starts in March 2026.
>
> Reason: a new claims handling guideline has been in force since 1 March 2026. For water damage
> claims above €3,000, an assessor must inspect the damage before payout. This extends the
> processing of these claims by about two to three weeks.
>
> Sources: table `claims_demo.claims.claims` (numbers),
> page "Claims Handling Guideline Water Damage", as of 1 March 2026 (explanation).

## Data Management: tables in the Databricks Catalog

Catalog `claims_demo`, schema `claims`. Four tables, deliberately kept small.

### `customers`

| Column | Type | Meaning |
|---|---|---|
| `customer_id` | STRING | Customer number (key) |
| `first_name` | STRING | First name (personal data) |
| `last_name` | STRING | Last name (personal data) |
| `postal_code` | STRING | Postal code |
| `city` | STRING | City |

### `policies`

| Column | Type | Meaning |
|---|---|---|
| `policy_id` | STRING | Policy number (key) |
| `customer_id` | STRING | Reference to `customers` |
| `product` | STRING | Product, e.g. "Residential Building Comfort", "Home Contents Plus" |
| `start_date` | DATE | Policy start |
| `end_date` | DATE | Policy end, empty for active policies |

### `claims`

The central table for the question.

| Column | Type | Meaning |
|---|---|---|
| `claim_id` | STRING | Claim number (key) |
| `policy_id` | STRING | Reference to `policies` |
| `damage_type` | STRING | Damage type: "Water damage", "Storm/Hail", "Fire", "Glass breakage" |
| `loss_date` | DATE | Date of loss |
| `reported_date` | DATE | Date the claim was reported |
| `closed_date` | DATE | Date the claim was closed, empty for open claims |
| `status` | STRING | "open", "closed", "rejected" |
| `estimated_amount` | DECIMAL(10,2) | Estimated claim amount in euros |
| `assessor_required` | BOOLEAN | Assessor needed (yes/no) |

### `claim_payments`

| Column | Type | Meaning |
|---|---|---|
| `payment_id` | STRING | Payment number (key) |
| `claim_id` | STRING | Reference to `claims` |
| `payment_date` | DATE | Payout date |
| `amount` | DECIMAL(10,2) | Amount paid out in euros |

### Relationships

`customers` 1:n `policies` 1:n `claims` 1:n `claim_payments`

### Definition of the metric

**Processing time** = number of days between `reported_date` and `closed_date`.
Only closed claims count. The average is evaluated per month of reporting.

This definition is also stored as a table and column comment in the Catalog and in the glossary
of the Knowledge Hub, so that Genie finds it.

### Target values for the sample data

The sample data for water damage claims should produce this trend:

| Month reported | Number of claims | Avg. processing time (days) |
|---|---|---|
| Oct 2025 | 38 | 18 |
| Nov 2025 | 41 | 17 |
| Dec 2025 | 44 | 18 |
| Jan 2026 | 96 | 21 |
| Feb 2026 | 52 | 19 |
| Mar 2026 | 40 | 24 |
| Apr 2026 | 37 | 27 |
| May 2026 | 39 | 29 |
| Jun 2026 | 36 | 30 |
| Jul 2026 | 38 | 31 |
| Aug 2026 | 35 | 30 |
| Sep 2026 | 37 | 31 |

Notes on the data:

- From March 2026, claims with `estimated_amount` above €3,000 have `assessor_required = true`
  and take around 36 days. Claims without an assessor still take around 18 days.
- January 2026 has more than twice as many claims because of a frost period.
  This makes a good follow-up question ("Why were there so many claims in January?").
- The other damage types stay unremarkable over the year (about 1,000 claims in total).
- Simplification: in the good data set all claims are closed, so the claims reported
  last have closed dates up to November 2026.
- The tables and the sample data are built by the scripts in `setup/` (see `README.md`).
- The period is designed for a demo in October 2026. For a later date, shift the data
  so that "the last 12 months" still fits.

## Knowledge Hub: pages in Databricks Pages

Every page has a small header at the top: **Title, As of (date), Owner, Valid from**.
These are exactly the details Genie needs to name a source properly.

| Page | Content | Role in the story |
|---|---|---|
| Claims Handling Guideline Water Damage | Since 1 March 2026: an assessor is mandatory for claims above €3,000. Before that the threshold was €10,000. Waiting time for an assessor appointment is about two weeks. | Provides the "why" |
| Claims Glossary | Explains terms such as processing time, reported date, closed date, damage type. | Makes sure Genie calculates the metric correctly |
| Event Report Frost January 2026 | Frost period from 8 to 19 January 2026, many burst pipes, mainly in the north. | Explains the peak in January (follow-up question) |
| Claims Handling Process | The steps from reporting to payout in simple words. | Background for visitors |

## The highlight: "What if something is missing?"

The same question is asked again, but this time one thing is broken.
Visitors pick one of three cards:

| Failure case | Example | Effect on Genie's answer |
|---|---|---|
| Data is poor | The closed date is missing for 15% of claims, mainly the long ones. | Genie reports 24 instead of 30 days. The number is wrong, or Genie warns about gaps. |
| Document is outdated | The new guideline was never filed. The Knowledge Hub only contains the old version from 2023. | Genie sees the increase but finds no explanation, or a wrong one. |
| No permission | Petra is not allowed to see the claims table. | Genie declines cleanly instead of guessing. |

Visitors immediately see the answer get worse and understand: quality does not come from the AI
itself, but from the data and knowledge behind it.

### Implementing the failure cases

| Failure case | Implementation in Databricks |
|---|---|
| Data is poor | Second schema `claims_demo.claims_poor_quality` with the same table `claims`, but without `closed_date` in 15% of the rows. |
| Document is outdated | Second page area that only contains the old guideline (as of 2023, threshold €10,000). |
| No permission | Second group without `SELECT` permission on `claims_demo.claims.claims`. |

## How it runs at the stand (approx. 5 minutes)

| Block | Duration | Content |
|---|---|---|
| Intro | 30 sec. | "In the past, Petra would have waited three days for an Excel report. Now she asks Genie." |
| Walkthrough | 2 min. | The four steps on screen, each with a short note on what happens behind the scenes. |
| Failure case | 2 min. | The visitor picks a card and sees the effect. |
| Takeaway | 30 sec. | "What can I do tomorrow?" Add a date and an owner to documents, report data errors. |

## What we need

- Catalog `claims_demo` with the four tables and the sample data
- Four pages in the Knowledge Hub (Databricks Pages)
- A Genie space with the question and four prepared answers
  (good, poor data, outdated document, no permission)
- Three failure-case cards to touch or click
- Poster with the four steps for passers-by

## For the deep dive (on request only)

- Glossary: what exactly does "processing time" mean?
- Catalog and lineage: where do the numbers come from?
- Routing: when does Genie use tables, when pages?
- Checking the generated query and plausibility checks
- Roles, permissions and purpose limitation for claims data (e.g. masking customer names)
