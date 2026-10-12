# Creates the Genie Agent (Genie space) of the claims demo with the four claims tables,
# the Knowledge Hub table, the instructions and the definition of processing time.
# Re-running updates the agent. Run deploy.ps1 and upload_knowledge.ps1 first.
#
# Usage:   .\setup\create_genie_agent.ps1
#          .\setup\create_genie_agent.ps1 -Title 'Claims Genie (poor data)' -ClaimsSchema claims_poor_quality
# Needs:   Databricks CLI, logged in (databricks auth login)

param(
    [string]$Title = 'Claims Genie',
    [string]$Catalog = 'claims_demo',
    # Schema of the table claims. The other three tables always come from the schema claims.
    [string]$ClaimsSchema = 'claims',
    # Schema of the table knowledge_pages with the pages of the Knowledge Hub.
    [string]$KnowledgeSchema = 'knowledge',
    [string]$WarehouseName = 'claims-demo-wh'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Genie expects 32-character hex ids, sorted within each list
function New-Id([string]$Text) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    return -join ($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text)) | ForEach-Object { $_.ToString('x2') })
}

$claimsTable = "$Catalog.$ClaimsSchema.claims"
$pagesTable = "$Catalog.$KnowledgeSchema.knowledge_pages"

$description = 'Answers questions about claims at the fictional Nordlicht Insurance: numbers from the claims tables, explanations from the pages of the Knowledge Hub. All data is fictional.'

$instructions = @"
You answer questions about claims at the fictional Nordlicht Insurance.

Processing time
- Processing time = number of days between reported_date and closed_date: datediff(closed_date, reported_date).
- Only claims with status = 'closed' count. Leave out open and rejected claims.
- Evaluate it as the average per month, and take the month from reported_date.
- Before you report a processing time, check whether closed_date is empty for claims with status = 'closed'. If it is, say how many claims are affected and that the average is not reliable.

Time periods
- "The last 12 months" means the last 12 complete calendar months by reported_date. Leave out the current month.

Numbers and explanations
- Numbers come from the claims tables. Explanations ("why") come from the pages of the Knowledge Hub.
- The pages of the Knowledge Hub are the rows of the table ${pagesTable}: one row per page, with the full text in the column content. The table is small, so read all rows with title, as_of, valid_from and content.
- When a question asks why something changed, calculate the numbers from the claims tables and read the pages in $pagesTable to find the explanation. Never join the claims tables with $pagesTable. Compare the dates in the pages (valid from, events) with the month in which the numbers change.
- Only use what the pages say. If the pages do not explain it, say that you found no explanation. Do not guess.

Sources
- End every answer with a line "Sources:".
- For numbers, name the table, for example $claimsTable.
- For explanations, name the title of the page and its as_of date, for example: page "Claims Glossary", as of 1 March 2026. Do not name the table $pagesTable as the source of an explanation.

Style
- Answer briefly and in plain language. Round days to whole numbers.
- Answer in the language of the question.
"@

$exampleSql = @"
SELECT
  date_trunc('MONTH', reported_date) AS month_reported,
  count(*) AS number_of_claims,
  round(avg(datediff(closed_date, reported_date))) AS avg_processing_time_days
FROM $claimsTable
WHERE damage_type = 'Water damage'
  AND status = 'closed'
  AND reported_date >= add_months(date_trunc('MONTH', current_date()), -12)
  AND reported_date < date_trunc('MONTH', current_date())
GROUP BY ALL
ORDER BY month_reported
"@

$questions = @(
    'How has the processing time for water damage claims developed over the last 12 months, and why?',
    'Why were there so many claims in January?'
)

$tables = @(
    $claimsTable,
    "$Catalog.claims.customers",
    "$Catalog.claims.policies",
    "$Catalog.claims.claim_payments",
    $pagesTable
) | Sort-Object

$space = [ordered]@{
    version      = 2
    config       = @{
        sample_questions = @($questions | ForEach-Object { @{ id = New-Id $_; question = @($_) } } | Sort-Object { $_.id })
    }
    data_sources = @{
        tables = @($tables | ForEach-Object { @{ identifier = $_ } })
    }
    instructions = [ordered]@{
        text_instructions     = @(@{ id = New-Id 'instructions'; content = @($instructions) })
        example_question_sqls = @(@{ id = New-Id 'example'; question = @('What is the average processing time for water damage claims per month over the last 12 months?'); sql = @($exampleSql) })
    }
}

$warehouse = (databricks warehouses list --output json | Out-String) | ConvertFrom-Json |
    Where-Object { $_.name -eq $WarehouseName }
if (-not $warehouse) { throw "SQL warehouse '$WarehouseName' not found." }

$body = @{
    warehouse_id     = $warehouse.id
    title            = $Title
    description      = $description
    serialized_space = ($space | ConvertTo-Json -Depth 10 -Compress)
}

$existing = ((databricks genie list-spaces --output json | Out-String) | ConvertFrom-Json).spaces |
    Where-Object { $_.title -eq $Title }

$bodyFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($bodyFile, ($body | ConvertTo-Json -Depth 10), $utf8NoBom)
    if ($existing) {
        Write-Host "Updating Genie Agent '$Title'"
        $result = (databricks genie update-space $existing.space_id --json "@$bodyFile" --output json | Out-String)
    } else {
        Write-Host "Creating Genie Agent '$Title'"
        $result = (databricks genie create-space --json "@$bodyFile" --output json | Out-String)
    }
} finally {
    Remove-Item $bodyFile -Confirm:$false
}
if ($LASTEXITCODE -ne 0) { throw 'Databricks CLI call failed.' }

$result = $result | ConvertFrom-Json
Write-Host "Space id: $($result.space_id)"
