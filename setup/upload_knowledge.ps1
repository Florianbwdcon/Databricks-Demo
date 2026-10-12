# Uploads the Knowledge Hub pages from the folder knowledge/ to a volume in Databricks
# and rebuilds the table knowledge_pages and the view knowledge_by_month from them. Genie reads
# the pages from there, because attaching a volume to a Genie Agent is not enabled in this workspace.
# Creates the schema and the volume if they do not exist. Existing files are overwritten.
#
# Usage:   .\setup\upload_knowledge.ps1
#          .\setup\upload_knowledge.ps1 -Catalog my_catalog -WarehouseName my-warehouse
# Needs:   Databricks CLI, logged in (databricks auth login)

param(
    [string]$Catalog = 'claims_demo',
    [string]$Schema = 'knowledge',
    [string]$Volume = 'pages',
    [string]$WarehouseName = 'claims-demo-wh'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Invoke-Sql([string]$Statement, [string]$WarehouseId) {
    $body = @{ warehouse_id = $WarehouseId; statement = $Statement; wait_timeout = '50s'; on_wait_timeout = 'CONTINUE' }
    $bodyFile = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($bodyFile, ($body | ConvertTo-Json), $utf8NoBom)
        $response = (databricks api post /api/2.0/sql/statements --json "@$bodyFile" | Out-String) | ConvertFrom-Json
    } finally {
        Remove-Item $bodyFile -Confirm:$false
    }
    while ($response.status.state -in 'PENDING', 'RUNNING') {
        Start-Sleep -Seconds 2
        $response = (databricks api get "/api/2.0/sql/statements/$($response.statement_id)" | Out-String) | ConvertFrom-Json
    }
    if ($response.status.state -ne 'SUCCEEDED') {
        throw "Statement failed ($($response.status.state)): $($response.status.error.message)`n$Statement"
    }
    return $response
}

databricks schemas get "$Catalog.$Schema" *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating schema $Catalog.$Schema"
    databricks schemas create $Schema $Catalog --comment 'Knowledge Hub of the claims demo: pages as Markdown files. All content is fictional.' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not create schema $Catalog.$Schema." }
}

databricks volumes read "$Catalog.$Schema.$Volume" *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating volume $Catalog.$Schema.$Volume"
    databricks volumes create $Catalog $Schema $Volume MANAGED --comment 'Pages of the Knowledge Hub. Every page has a header with title, as of, owner and valid from.' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not create volume $Catalog.$Schema.$Volume." }
}

$target = "dbfs:/Volumes/$Catalog/$Schema/$Volume"
$pages = Join-Path (Split-Path $PSScriptRoot -Parent) 'knowledge'
foreach ($file in Get-ChildItem -Path $pages -Filter '*.md' | Sort-Object Name) {
    Write-Host "Uploading $($file.Name)"
    databricks fs cp $file.FullName "$target/$($file.Name)" --overwrite
    if ($LASTEXITCODE -ne 0) { throw "Could not upload $($file.Name)." }
}

# For Genie the pages are also stored as one row per page. The header fields are read from
# the header table at the top of every page, the summary from its section "Summary".
$warehouse = (databricks warehouses list --output json | Out-String) | ConvertFrom-Json |
    Where-Object { $_.name -eq $WarehouseName }
if (-not $warehouse) { throw "SQL warehouse '$WarehouseName' not found." }

$table = "$Catalog.$Schema.knowledge_pages"
$view = "$Catalog.$Schema.knowledge_by_month"
Write-Host "Rebuilding table $table on warehouse $WarehouseName (starts automatically if stopped)"

Invoke-Sql @"
CREATE OR REPLACE TABLE $table (
  title          STRING COMMENT 'Title of the page. Name it as the source when using the page.',
  as_of          DATE COMMENT 'Date the page was last updated. Name it together with the title as the source.',
  owner          STRING COMMENT 'Team that is responsible for the page',
  valid_from     DATE COMMENT 'Date from which the content of the page applies',
  effective_from DATE COMMENT 'Date from which the content of the page affects claims: the start of the event for event reports, otherwise valid_from',
  summary        STRING COMMENT 'Summary of the page in a few sentences. Use it to explain rules, definitions, reasons and events.',
  file_name      STRING COMMENT 'Name of the Markdown file in the volume',
  content        STRING COMMENT 'Full text of the page in Markdown'
)
COMMENT 'Knowledge Hub of the fictional Nordlicht Insurance: one row per knowledge page (guidelines, glossary, event reports, process). Use it for the explanation behind the numbers, for example why a metric changed. It contains no claim data.'
"@ $warehouse.id | Out-Null

Invoke-Sql @"
INSERT INTO $table
WITH header AS (
  SELECT
    regexp_extract(value, r'\*\*Title\*\*\s*\|\s*(.*?)\s*\|', 1) AS title,
    to_date(regexp_extract(value, r'\*\*As of\*\*\s*\|\s*(.*?)\s*\|', 1), 'd MMMM yyyy') AS as_of,
    regexp_extract(value, r'\*\*Owner\*\*\s*\|\s*(.*?)\s*\|', 1) AS owner,
    to_date(regexp_extract(value, r'\*\*Valid from\*\*\s*\|\s*(.*?)\s*\|', 1), 'd MMMM yyyy') AS valid_from,
    to_date(nullif(regexp_extract(value, r'\*\*Event start\*\*\s*\|\s*(.*?)\s*\|', 1), ''), 'd MMMM yyyy') AS event_start,
    regexp_replace(regexp_extract(value, r'(?s)## Summary\s+(.*?)\r?\n\s*\r?\n', 1), r'\s*\r?\n\s*', ' ') AS summary,
    regexp_extract(_metadata.file_path, r'([^/]+)$', 1) AS file_name,
    value AS content
  FROM read_files('/Volumes/$Catalog/$Schema/$Volume/', format => 'text', wholeText => true, fileNamePattern => '*.md')
)
SELECT title, as_of, owner, valid_from, coalesce(event_start, valid_from) AS effective_from, summary, file_name, content
FROM header
"@ $warehouse.id | Out-Null

# Genie runs one query per question. This view lets it put the explanation next to the numbers:
# joined on the month, a note appears in the month in which a rule or an event took effect.
Invoke-Sql @"
CREATE OR REPLACE VIEW $view (
  month              COMMENT 'First day of the month in which the pages took effect. Join it with the month of the numbers.',
  knowledge_hub_note COMMENT 'What the Knowledge Hub says took effect in this month: title of the page, its as of date and its summary. Use it to explain why numbers change in or after this month.'
)
COMMENT 'Knowledge Hub by month: one row per month in which a guideline, rule or event took effect. Left join it with monthly numbers on the month to explain why numbers change. Months without a row have no explanation in the Knowledge Hub.'
AS
SELECT
  trunc(effective_from, 'MM') AS month,
  concat_ws(' || ', collect_list(concat('Page "', title, '", as of ', date_format(as_of, 'd MMMM yyyy'), ': ', summary))) AS knowledge_hub_note
FROM $table
GROUP BY ALL
"@ $warehouse.id | Out-Null

$result = Invoke-Sql "SELECT title, as_of, valid_from, effective_from, summary FROM $table ORDER BY title" $warehouse.id
Write-Host ''
Write-Host (($result.manifest.schema.columns | ForEach-Object { $_.name }) -join "`t")
foreach ($row in $result.result.data_array) { Write-Host ($row -join "`t") }
