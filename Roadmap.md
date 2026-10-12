# Roadmap: Genie Demo Claims Handling

As of: 12 October 2026

This file shows what is done, where we are and what is still missing.
The storyline is in `Context.md`, the checklist to tick off is in `TODO.md`.

## The goal in one sentence

Petra asks at the stand: "How has the processing time for water damage claims developed over
the last 12 months, and why?" The numbers come from tables, the explanation from knowledge
pages, and the answer names the source for both. After that we show three failure cases.

## The setup

| Building block | Job | Where in Databricks | Status |
|---|---|---|---|
| Tables | provide the numbers | `claims_demo.claims` | done |
| Poor-quality copy | failure case "Data is poor" | `claims_demo.claims_poor_quality` | done |
| Knowledge pages | provide the "why" | volume `claims_demo.knowledge.pages`, table `knowledge_pages` and view `knowledge_by_month` in `claims_demo.knowledge` | done |
| Genie Agent | queries the claims tables and reads the pages from the table | Genie "Claims Genie" | done, UI test open |

Workspace: sandbox `adb-7405618085597765` (CLI profile `Florian`).

The original plan was a Knowledge Assistant for the pages and a Supervisor Agent that connects
it with Genie. Both are blocked for this Databricks account ("not available, please contact
sales"), in the UI and in the API. Attaching the volume directly to the Genie Agent is blocked
as well (`VOLUME_INDEX_FEATURE_PREVIEW_NOT_ENABLED`). So the pages are stored as a table that
is part of the Genie Agent.

## Where we are

The data side and the knowledge side are finished and live in Databricks.
The Genie Agent gives the good answer. Still missing: two of the three failure cases and
the material for the stand.

```
Phase 1  Storyline and data       done
Phase 2  Knowledge Hub            done
Phase 3  Genie Agent              done, UI test open
Phase 4  Failure cases            2 of 3 done and tested
Phase 5  Stand                    open
Phase 6  Housekeeping             open
```

## What is done

### Phase 1: Storyline and data

- Storyline written (`Context.md`)
- SQL warehouse `claims-demo-wh` created (serverless, 2X-Small, stops after 1 minute)
- Catalog `claims_demo` with the tables `customers`, `policies`, `claims`, `claim_payments`
- Sample data loaded and checked against the target values in `Context.md`
- Failure case "Data is poor": `claims_demo.claims_poor_quality.claims`
- Everything repeatable through `setup/deploy.ps1`

### Phase 2: Knowledge Hub

- Decided where the Knowledge Hub lives: Markdown files in the repository (`knowledge/`),
  rolled out to the volume `claims_demo.knowledge.pages`
- Four pages written, each with a header (title, as of, owner, valid from):
  - Claims Handling Guideline Water Damage (provides the "why")
  - Claims Glossary (definition of processing time)
  - Event Report Frost January 2026 (explains the peak in January)
  - Claims Handling Process (background)
- Numbers in the pages checked against the sample data
- Pages uploaded to the volume and stored as the table `claims_demo.knowledge.knowledge_pages`
  (one row per page), repeatable through `setup/upload_knowledge.ps1`

### Around it

- Project rules in `CLAUDE.md`: repository in English, work on `dev`, no push to `master`
- GitHub login for this repository switched to the account `Florianbwdcon`
- Everything up to here is on `origin/dev`

## What is left to do

### Phase 3: Genie Agent (nearly done)

Done: the Genie Agent "Claims Genie" exists with the four claims tables, the table
`knowledge_pages`, the view `knowledge_by_month` and the instructions
(`setup/create_genie_agent.ps1`). Tested through the API, it gives the good answer:

- Main question: processing time rises from 17-18 days at the end of 2025 to 30-31 days in
  summer 2026, the increase from March 2026 is explained with the new guideline, and the
  table and the page with its as of date are named as sources.
- Follow-up question: 96 water damage claims in January, explained with the frost report.

How it works: Genie runs one query per question. The view puts the summary of a page next to
the month in which it took effect, and Genie joins it with the monthly numbers.

Open: test both questions in the Genie UI and check how table and answer look on screen.

### Phase 4: Failure cases

Done: "Data is poor". The Genie Agent "Claims Genie (poor data)" uses `claims_poor_quality.claims`.
It reports 21 to 26 days from March 2026 instead of 24 to 31 and warns that closed claims
without a closed date make the average unreliable.

Done: "Document is outdated". The folder `knowledge_outdated/` only holds the old guideline from
2023, stored in the schema `claims_demo.knowledge_outdated`. The Genie Agent "Claims Genie
(outdated document)" reports the same numbers as the good agent and says that the Knowledge Hub
contains no explanation for the change.

Set up, not yet tested: "No permission". A second user may use the warehouse and the agent
"Claims Genie" and read all its tables except `claims_demo.claims.claims`
(`setup/create_no_access_user.ps1`). Open: log in as this user and ask the main question.

- Test all three failure cases with the main question and note the answers

### Phase 5: Stand

- Three failure-case cards to touch or click
- Poster with the four steps
- Prepare the four answers as a fallback in case something does not work live
- Rehearse the 5-minute run-through
- Start the warehouse shortly before the demo

### Phase 6: Housekeeping

- Shift the sample data if the demo takes place later than October 2026
- Sort out local files that are not in the repository yet: `databricks.yml`, `pyproject.toml`,
  `uv.lock`, `.vscode/`, `.obsidian/`
- Remove the test file `test2.txt`
- Decide when `dev` goes to `master`
- Stop or delete the warehouse `claims-demo-wh` after the demo

### Optional: deep dive

- Mask customer names for groups that do not need them
- Show lineage for the claims tables in the Catalog
- Show how to check the query Genie generated

## Open points

- **Owners and dates in the pages:** the owners (fictional teams), the date of the old guideline
  (1 July 2023) and the reason for the new threshold are made up and not yet confirmed by Florian.
- **CLI:** `databricks` is not on the PATH on Florian's machine. For the scripts, the folder
  of the VS Code extension has to be on the PATH.
- **Two workspaces:** the default CLI profile points to a different workspace.
  Inside the project folder the sandbox is used because of `databricks.yml`; outside it,
  pass `--profile Florian`.
