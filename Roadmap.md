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
| Knowledge pages | provide the "why" | volume `claims_demo.knowledge.pages` | done |
| Knowledge Assistant | searches the knowledge pages | Agents | open |
| Genie Agent | queries the tables | Agents / Genie space | open |
| Supervisor Agent | connects both, this is "Genie" at the stand | Agents | open |

Workspace: sandbox `adb-7405618085597765` (CLI profile `Florian`).

## Where we are

The data side and the knowledge side are finished and live in Databricks.
Everything that turns them into an answer is still missing: the three agents, two of the
three failure cases and the material for the stand.

```
Phase 1  Storyline and data       done
Phase 2  Knowledge Hub            done
Phase 3  Agents                   next
Phase 4  Failure cases            1 of 3 done
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
- Pages uploaded to the volume, repeatable through `setup/upload_knowledge.ps1`

### Around it

- Project rules in `CLAUDE.md`: repository in English, work on `dev`, no push to `master`
- GitHub login for this repository switched to the account `Florianbwdcon`
- Everything up to here is on `origin/dev`

## What is left to do

### Phase 3: Agents (next)

1. Create a **Knowledge Assistant** on the volume `/Volumes/claims_demo/knowledge/pages/`
   and test it with "Why have water damage claims taken longer since March?"
2. Create a **Genie space** with the four tables, add instructions and the definition
   of processing time
3. Create a **Supervisor Agent** that connects Genie and the Knowledge Assistant
4. Test the main question and compare with "The good answer" in `Context.md`
5. Test the follow-up question: "Why were there so many claims in January?"
6. Check that a source is named for the numbers and for the explanation

### Phase 4: Failure cases

- "Document is outdated": write a page with the old guideline (valid from 1 July 2023,
  threshold €10,000), put it in a second volume, second Knowledge Assistant on top
- "No permission": second group without `SELECT` on `claims_demo.claims.claims`
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
