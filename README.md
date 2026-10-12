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

Every page starts with a header: title, as of, owner, valid from.

Upload the pages to the volume `claims_demo.knowledge.pages` (creates schema and volume if needed)
and rebuild the table `claims_demo.knowledge.knowledge_pages` from them:

```powershell
.\setup\upload_knowledge.ps1
```

The table has one row per page with the header fields (`title`, `as_of`, `owner`, `valid_from`)
and the full text (`content`). Genie reads the pages from this table, because attaching a volume
to a Genie Agent is not enabled in this workspace (`VOLUME_INDEX_FEATURE_PREVIEW_NOT_ENABLED`).

Re-running overwrites the files in the volume and rebuilds the table.

## Genie Agent

Create the Genie Agent "Claims Genie" with the four claims tables, the table `knowledge_pages`,
the instructions and the definition of processing time:

```powershell
.\setup\create_genie_agent.ps1
```

Re-running updates the agent.
