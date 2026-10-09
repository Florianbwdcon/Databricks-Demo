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
