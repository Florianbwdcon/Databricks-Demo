# Databricks-Demo
This is sample Data for a Databricks Demo using Genie

The storyline of the demo is described in `Context.md`.

## Setup

The folder `setup/` builds the demo data in Databricks:

| File | What it does |
|---|---|
| `01_create_tables.sql` | Creates the schema `claims` with the tables `customers`, `policies`, `claims`, `claim_payments` |
| `02_load_sample_data.sql` | Fills the tables with fictional sample data (same rows on every run) |
| `03_create_poor_quality_copy.sql` | Creates `claims_poor_quality.claims` for the failure case "Data is poor" |
| `04_verify.sql` | Shows the water damage claims per month to check them against `Context.md` |

Run everything with the Databricks CLI (must be logged in):

```powershell
.\setup\deploy.ps1
```

By default the script uses the catalog `claims_demo` and the SQL warehouse `claims-demo-wh`.
Other names: `.\setup\deploy.ps1 -Catalog my_catalog -WarehouseName my-warehouse`.
Re-running drops and rebuilds the tables.

The SQL files can also be run one after the other in the Databricks SQL editor with the
target catalog selected.

## Knowledge Hub

The folder `knowledge/` contains the pages of the Knowledge Hub as Markdown:

| File | Page |
|---|---|
| `claims_handling_guideline_water_damage.md` | Claims Handling Guideline Water Damage |
| `claims_glossary.md` | Claims Glossary |
| `event_report_frost_january_2026.md` | Event Report Frost January 2026 |
| `claims_handling_process.md` | Claims Handling Process |

Every page starts with a header (title, as of, owner, valid from) and a section "Summary".
Event reports also have the header field "Event start".

Upload the pages to the volume `claims_demo.knowledge.pages` (creates schema and volume if needed)
and rebuild the table `claims_demo.knowledge.knowledge_pages` and the view
`claims_demo.knowledge.knowledge_by_month` from them:

```powershell
.\setup\upload_knowledge.ps1
```

The table has one row per page with the header fields (`title`, `as_of`, `owner`, `valid_from`),
the summary and the full text. The view has one row per month in which a page took effect, with
title, as of date and summary as a note. Genie joins the view with the monthly numbers to explain
why they change. This replaces attaching the volume to the Genie Agent, which is not enabled in
this workspace (`VOLUME_INDEX_FEATURE_PREVIEW_NOT_ENABLED`).

Re-running overwrites the files in the volume and rebuilds table and view.

## Genie Agent

Create the Genie Agent "Claims Genie" with the four claims tables, the table `knowledge_pages`,
the view `knowledge_by_month`, the instructions, the definition of processing time and
example queries for the two demo questions:

```powershell
.\setup\create_genie_agent.ps1
```

Re-running updates the agent.

The agent for the failure case "Data is poor" is the same script with the poor-quality claims table:

```powershell
.\setup\create_genie_agent.ps1 -Title 'Claims Genie (poor data)' -ClaimsSchema claims_poor_quality
```

The failure case "Document is outdated" has its own Knowledge Hub. The folder `knowledge_outdated/`
only contains the old guideline from 2023. Upload it to the schema `knowledge_outdated` and create
the agent on it:

```powershell
.\setup\upload_knowledge.ps1 -Folder knowledge_outdated -Schema knowledge_outdated
.\setup\create_genie_agent.ps1 -Title 'Claims Genie (outdated document)' -KnowledgeSchema knowledge_outdated
```

After a change to the instructions in `create_genie_agent.ps1`, run all three calls again.

## User without permission

The failure case "No permission" needs a second user who asks the agent "Claims Genie" but may
not read the table `claims_demo.claims.claims`. Create the user account in Microsoft Entra ID,
then add it to the workspace and set its permissions:

```powershell
.\setup\create_no_access_user.ps1 -UserName demo.noaccess@example.onmicrosoft.com
```

The user may use the warehouse and the agent and may read all other tables of the agent.
