# Sets up the user for the failure case "No permission" (see Context.md): the user may use the
# warehouse and the Genie Agent and may read everything except the table claims.claims.
# The user account itself must exist in Microsoft Entra ID. Re-running is safe.
#
# Usage:   .\setup\create_no_access_user.ps1 -UserName demo.noaccess@example.onmicrosoft.com
# Needs:   Databricks CLI, logged in (databricks auth login)

param(
    [Parameter(Mandatory)][string]$UserName,
    [string]$Catalog = 'claims_demo',
    [string]$AgentTitle = 'Claims Genie',
    [string]$WarehouseName = 'claims-demo-wh'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# The CLI takes the request body as a file, so that quotes survive
function Invoke-WithJson([hashtable]$Body, [scriptblock]$Command) {
    $bodyFile = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($bodyFile, ($Body | ConvertTo-Json -Depth 6), $utf8NoBom)
        & $Command "@$bodyFile" | Out-Null
    } finally {
        [System.IO.File]::Delete($bodyFile)
    }
    if ($LASTEXITCODE -ne 0) { throw 'Databricks CLI call failed.' }
}

function Grant([string]$Type, [string]$Name, [string[]]$Privileges) {
    Write-Host "Granting $($Privileges -join ', ') on $Type $Name"
    Invoke-WithJson @{ changes = @(@{ principal = $UserName; add = $Privileges }) } {
        param($json) databricks grants update $Type $Name --json $json
    }
}

$user = (databricks users list --filter "userName eq `"$UserName`"" --output json | Out-String) | ConvertFrom-Json
if ($user) {
    Write-Host "User $UserName is already in the workspace"
} else {
    Write-Host "Adding user $UserName to the workspace"
    databricks users create --user-name $UserName | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not add user $UserName." }
}

$warehouse = (databricks warehouses list --output json | Out-String) | ConvertFrom-Json |
    Where-Object { $_.name -eq $WarehouseName }
if (-not $warehouse) { throw "SQL warehouse '$WarehouseName' not found." }
Write-Host "Allowing the user to use the warehouse $WarehouseName"
Invoke-WithJson @{ access_control_list = @(@{ user_name = $UserName; permission_level = 'CAN_USE' }) } {
    param($json) databricks permissions update warehouses $warehouse.id --json $json
}

$agent = ((databricks genie list-spaces --output json | Out-String) | ConvertFrom-Json).spaces |
    Where-Object { $_.title -eq $AgentTitle }
if (-not $agent) { throw "Genie Agent '$AgentTitle' not found." }
Write-Host "Allowing the user to ask the Genie Agent '$AgentTitle'"
Invoke-WithJson @{ access_control_list = @(@{ user_name = $UserName; permission_level = 'CAN_RUN' }) } {
    param($json) databricks permissions update genie $agent.space_id --json $json
}

# Everything the Genie Agent uses, except the table claims.claims
Grant 'catalog' $Catalog @('USE_CATALOG')
Grant 'schema' "$Catalog.claims" @('USE_SCHEMA')
Grant 'schema' "$Catalog.knowledge" @('USE_SCHEMA')
foreach ($table in 'claims.customers', 'claims.policies', 'claims.claim_payments',
                   'knowledge.knowledge_pages', 'knowledge.knowledge_by_month') {
    Grant 'table' "$Catalog.$table" @('SELECT')
}

Write-Host ''
Write-Host "Done. $UserName has no SELECT on $Catalog.claims.claims."
