# Uploads the Knowledge Hub pages from the folder knowledge/ to a volume in Databricks.
# Creates the schema and the volume if they do not exist. Existing files are overwritten.
#
# Usage:   .\setup\upload_knowledge.ps1
#          .\setup\upload_knowledge.ps1 -Catalog my_catalog
# Needs:   Databricks CLI, logged in (databricks auth login)

param(
    [string]$Catalog = 'claims_demo',
    [string]$Schema = 'knowledge',
    [string]$Volume = 'pages'
)

$ErrorActionPreference = 'Stop'

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

Write-Host ''
databricks fs ls $target
