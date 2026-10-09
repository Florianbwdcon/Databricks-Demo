# Builds the claims demo in Databricks: runs the SQL files in this folder in order
# through the Databricks CLI and prints the result of the last one (the check).
#
# Usage:   .\setup\deploy.ps1
#          .\setup\deploy.ps1 -Catalog my_catalog -WarehouseName my-warehouse
# Needs:   Databricks CLI, logged in (databricks auth login)

param(
    [string]$Catalog = 'claims_demo',
    [string]$WarehouseName = 'claims-demo-wh'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Invoke-Sql([string]$Statement, [string]$WarehouseId, [string]$UseCatalog) {
    $body = @{ warehouse_id = $WarehouseId; statement = $Statement; wait_timeout = '50s'; on_wait_timeout = 'CONTINUE' }
    if ($UseCatalog) { $body.catalog = $UseCatalog }
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

$warehouse = (databricks warehouses list --output json | Out-String) | ConvertFrom-Json |
    Where-Object { $_.name -eq $WarehouseName }
if (-not $warehouse) { throw "SQL warehouse '$WarehouseName' not found." }

Write-Host "Catalog $Catalog on warehouse $WarehouseName (starts automatically if stopped)"
Invoke-Sql "CREATE CATALOG IF NOT EXISTS $Catalog" $warehouse.id '' | Out-Null

$result = $null
foreach ($file in Get-ChildItem -Path $PSScriptRoot -Filter '*.sql' | Sort-Object Name) {
    Write-Host "Running $($file.Name)"
    $lines = [System.IO.File]::ReadAllLines($file.FullName) | Where-Object { $_ -notmatch '^\s*--' }
    $statements = ($lines -join "`n") -split ';\s*(?:\n|$)' | Where-Object { $_.Trim() }
    foreach ($statement in $statements) {
        $result = Invoke-Sql $statement $warehouse.id $Catalog
    }
}

Write-Host ''
Write-Host (($result.manifest.schema.columns | ForEach-Object { $_.name }) -join "`t")
foreach ($row in $result.result.data_array) { Write-Host ($row -join "`t") }
