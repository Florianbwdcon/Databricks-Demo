# To-do list: claims demo with Genie

Status of the demo described in `Context.md`. Tick an item off when it is done.

## Done

- [x] Storyline written (`Context.md`)
- [x] Low-cost SQL warehouse `claims-demo-wh` created (serverless, 2X-Small, auto-stop after 1 minute)
- [x] Catalog `claims_demo` with the tables `customers`, `policies`, `claims`, `claim_payments`
- [x] Sample data loaded and checked against the target values in `Context.md`
- [x] Failure case "Data is poor": `claims_demo.claims_poor_quality.claims`
- [x] Setup scripts in `setup/`, described in `README.md`

## Knowledge Hub (pages in OKF)

- [x] Clarify where the Knowledge Hub lives in the Databricks workspace and how pages get there
      (volume `claims_demo.knowledge.pages`, filled by `setup/upload_knowledge.ps1`)
- [x] Write the page "Claims Handling Guideline Water Damage" (as of 1 March 2026)
- [x] Write the page "Claims Glossary"
- [x] Write the page "Event Report Frost January 2026"
- [x] Write the page "Claims Handling Process"
- [x] Give every page the header: title, as of, owner, valid from
- [x] Upload the pages to the Knowledge Hub
- [x] Store the pages as the table `claims_demo.knowledge.knowledge_pages` and the view `knowledge_by_month` for Genie
- Blocked in this workspace: Knowledge Assistant and Supervisor Agent ("contact sales"), and
  attaching the volume to the Genie Agent (`VOLUME_INDEX_FEATURE_PREVIEW_NOT_ENABLED`)

## Genie

- [x] Create the Genie Agent "Claims Genie" with the four claims tables and `knowledge_pages`
      (`setup/create_genie_agent.ps1`)
- [x] Add instructions and the definition of "processing time"
- [x] Instruct Genie to name the page title and "as of" date as the source of the explanation
- [x] Test the numbers of the main question (18 days in Oct 2025 to 31 days in Sep 2026, source named)
- [x] Get a usable "why" out of Genie: view `knowledge_by_month` puts the summary of a page next to
      the month in which it took effect, and Genie joins it with the monthly numbers
- [x] Test the main question: 17-18 days at the end of 2025 to 30-31 days in summer 2026, increase from
      March 2026 explained with the guideline, sources named (tested through the API on 12 October 2026)
- [x] Test the follow-up question "Why were there so many claims in January?" (96 water damage claims, frost report)
- [x] Test the main question in the Genie UI (Agent mode, by Florian on 12 October 2026): correct, but long
- [x] Shorten the answer: at most three sentences plus sources, main reason first
- [ ] Test both questions again in the Genie UI with the short style, in the mode used at the stand
- [ ] The line "Sources:" is sometimes missing in the answer to the follow-up question
- [x] Check that Genie names a source for the numbers and for the explanation

## Remaining failure cases

- [x] "Data is poor": Genie Agent "Claims Genie (poor data)" on `claims_poor_quality.claims`. Tested through the
      API on 12 October 2026: 21 to 26 days from March 2026 instead of 24 to 31, and Genie warns that
      2 to 17 closed claims per month have no closed date and the average is probably too low
- [ ] "Document is outdated": second schema with a `knowledge_pages` table that only holds the old guideline
      (valid from 1 July 2023, threshold 10,000 euros) and a second Genie Agent on it
- [ ] "No permission": second group without `SELECT` permission on `claims_demo.claims.claims`
- [ ] Test all three failure cases with the main question and note Genie's answers

## At the stand

- [ ] Three failure-case cards to touch or click
- [ ] Poster with the four steps for passers-by
- [ ] Prepare the four answers (good, poor data, outdated document, no permission) as a fallback without live Genie
- [ ] Rehearse the 5-minute run-through
- [ ] Start the warehouse shortly before the demo so the first answer does not wait for the start

## Housekeeping

- [ ] Shift the sample data if the demo takes place later than October 2026
- [ ] Commit the local `.gitignore` change (`.obsidian/`)
- [ ] Remove the test file `test2.txt`
- [ ] Decide when `dev` is merged into `master`
- [ ] Stop or delete the warehouse `claims-demo-wh` after the demo

## Deep dive (optional)

- [ ] Mask customer names for groups that do not need them
- [ ] Show lineage for the claims tables in the Catalog
- [ ] Show how to check the query Genie generated
