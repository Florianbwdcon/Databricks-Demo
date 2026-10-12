# Uploads the Knowledge Hub pages from the folder knowledge/ to a volume in Databricks
# and rebuilds the table knowledge_pages from them, so that Genie can read the pages.
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

# Genie only reads tables, so the pages are also stored as one row per page.
# The header fields are read from the header table at the top of every page.
$warehouse = (databricks warehouses list --output json | Out-String) | ConvertFrom-Json |
    Where-Object { $_.name -eq $WarehouseName }
if (-not $warehouse) { throw "SQL warehouse '$WarehouseName' not found." }

$table = "$Catalog.$Schema.knowledge_pages"
Write-Host "Rebuilding table $table on warehouse $WarehouseName (starts automatically if stopped)"

Invoke-Sql @"
CREATE OR REPLACE TABLE $table (
  title      STRING COMMENT 'Title of the page. Name it as the source when using the page.',
  as_of      DATE COMMENT 'Date the page was last updated. Name it together with the title as the source.',
  owner      STRING COMMENT 'Team that is responsible for the page',
  valid_from DATE COMMENT 'Date from which the content of the page applies',
  file_name  STRING COMMENT 'Name of the Markdown file in the volume',
  content    STRING COMMENT 'Full text of the page in Markdown. Read it to explain rules, definitions, reasons and events.'
)
COMMENT 'Knowledge Hub of the fictional Nordlicht Insurance: one row per knowledge page (guidelines, glossary, event reports, process). Use it for the explanation behind the numbers, for example why a metric changed. It contains no claim data.'
"@ $warehouse.id | Out-Null

Invoke-Sql @"
INSERT INTO $table
SELECT
  regexp_extract(value, r'\*\*Title\*\*\s*\|\s*(.*?)\s*\|', 1) AS title,
  to_date(regexp_extract(value, r'\*\*As of\*\*\s*\|\s*(.*?)\s*\|', 1), 'd MMMM yyyy') AS as_of,
  regexp_extract(value, r'\*\*Owner\*\*\s*\|\s*(.*?)\s*\|', 1) AS owner,
  to_date(regexp_extract(value, r'\*\*Valid from\*\*\s*\|\s*(.*?)\s*\|', 1), 'd MMMM yyyy') AS valid_from,
  regexp_extract(_metadata.file_path, r'([^/]+)$', 1) AS file_name,
  value AS content
FROM read_files('/Volumes/$Catalog/$Schema/$Volume/', format => 'text', wholeText => true, fileNamePattern => '*.md')
"@ $warehouse.id | Out-Null

$result = Invoke-Sql "SELECT title, as_of, owner, valid_from, file_name, length(content) AS characters FROM $table ORDER BY title" $warehouse.id
Write-Host ''
Write-Host (($result.manifest.schema.columns | ForEach-Object { $_.name }) -join "`t")
foreach ($row in $result.result.data_array) { Write-Host ($row -join "`t") }
