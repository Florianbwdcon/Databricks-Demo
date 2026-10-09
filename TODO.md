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

- [ ] Clarify where the Knowledge Hub lives in the Databricks workspace and how pages get there
- [ ] Write the page "Claims Handling Guideline Water Damage" (as of 1 March 2026)
- [ ] Write the page "Claims Glossary"
- [ ] Write the page "Event Report Frost January 2026"
- [ ] Write the page "Claims Handling Process"
- [ ] Give every page the header: title, as of, owner, valid from
- [ ] Upload the pages to the Knowledge Hub

## Genie

- [ ] Create the Genie space with the four tables
- [ ] Add instructions and the definition of "processing time"
- [ ] Connect the Knowledge Hub pages so that Genie can find the explanation
- [ ] Test the main question and compare with "The good answer" in `Context.md`
- [ ] Test the follow-up question "Why were there so many claims in January?"
- [ ] Check that Genie names a source for the numbers and for the explanation

## Remaining failure cases

- [ ] "Document is outdated": second page area with only the old guideline (as of 2023, threshold 10,000 euros)
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
