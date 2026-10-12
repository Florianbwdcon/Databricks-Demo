# Creates the Genie Agent (Genie space) of the claims demo with the four claims tables,
# the Knowledge Hub table and view, the instructions and the definition of processing time.
# Re-running updates the agent. Run deploy.ps1 and upload_knowledge.ps1 first.
#
# Usage:   .\setup\create_genie_agent.ps1
#          .\setup\create_genie_agent.ps1 -Title 'Claims Genie (poor data)' -ClaimsSchema claims_poor_quality
#          .\setup\create_genie_agent.ps1 -Title 'Claims Genie (outdated document)' -KnowledgeSchema knowledge_outdated
# Needs:   Databricks CLI, logged in (databricks auth login)

param(
    [string]$Title = 'Claims Genie',
    [string]$Catalog = 'claims_demo',
    # Schema of the table claims. The other three tables always come from the schema claims.
    [string]$ClaimsSchema = 'claims',
    # Schema of the table knowledge_pages and the view knowledge_by_month.
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
$monthView = "$Catalog.$KnowledgeSchema.knowledge_by_month"

$description = 'Answers questions about claims at the fictional Nordlicht Insurance: numbers from the claims tables, explanations from the pages of the Knowledge Hub. All data is fictional.'

$instructions = @"
You answer questions about claims at the fictional Nordlicht Insurance.

Processing time
- Processing time = number of days between reported_date and closed_date: datediff(closed_date, reported_date).
- Only claims with status = 'closed' count. Leave out open and rejected claims.
- Evaluate it as the average per month, and take the month from reported_date.
- Always return the number of closed claims without a closed_date next to a processing time. If it is above 0, say how many claims are affected and that the average is therefore not reliable and probably too low.

Time periods
- "The last 12 months" means the last 12 complete calendar months by reported_date. Leave out the current month.

Numbers and explanations
- Numbers come from the claims tables. Explanations ("why") come from the Knowledge Hub.
- The view $monthView holds what the Knowledge Hub says per month: one row for every month in which a guideline, a rule or an event took effect, with the column knowledge_hub_note.
- Whenever a question asks how something developed over time or why something changed, is high or is low: calculate the numbers per month and left join $monthView on the month, so that knowledge_hub_note stands next to the numbers. Use the example queries as the pattern.
- Explain a change in the numbers with the knowledge_hub_note of the month in which the change starts. Say in which month the change starts.
- Only use what the notes say. If no note explains the change, say that the Knowledge Hub contains no explanation. Do not guess.
- For questions about terms, rules or the process, read title, as_of and summary from $pagesTable.

Sources
- End every answer with a line "Sources:".
- For numbers, name the table, for example $claimsTable.
- For explanations, name the title of the page and its as of date exactly as they stand in the note, for example: page "Claims Glossary", as of 1 March 2026. Do not name $monthView or $pagesTable as the source of an explanation.

Style
- The answer has exactly two sentences and then the line "Sources:". Nothing else: no headings, no lists, no third sentence, no follow-up question.
- Sentence 1 is about the numbers only. For a development over time it has this form: "<Metric> rose from <start value> in <first month> to <end value> in <last month>, with the lasting increase starting in <month>." A change is lasting when the number stays higher in the following months. Leave out a single month that is a little higher and then falls back. For a question about one month, sentence 1 gives the number of that month and the normal level.
- Sentence 1 ends there when closed_claims_without_closed_date is 0 in all months. Only when it is above 0 in any month, sentence 1 continues with: ", but this average is not reliable and probably too low, because <lowest> to <highest> closed claims per month have no closed date."
- Sentence 2 is about the reason only. It has this form: "Reason: Page "<title>", as of <date>, says that <what the page says>." Take it from the knowledge_hub_note of the month in which the lasting change starts, or of the month the question asks about. Use only that one page.
- If there is no knowledge_hub_note for that month, sentence 2 is exactly: "Reason: The Knowledge Hub contains no explanation for this change." Do not take a reason from another month. The last line is then exactly: Sources: table <full table name> (numbers), no page found (explanation).
- Never use the words "note", "notes", "attached", "rows" or "data quality" in the answer.
- The last line of every answer is mandatory and has exactly this form: Sources: table <full table name> (numbers), page "<title>", as of <date> (explanation).
- Use plain language. Round days to whole numbers.
- Answer in the language of the question.
"@

$window = @"
    AND reported_date >= add_months(trunc(current_date(), 'MM'), -12)
    AND reported_date < trunc(current_date(), 'MM')
"@

$examples = @(
    @{
        question = 'How has the processing time for water damage claims developed over the last 12 months, and why?'
        sql      = @"
WITH monthly AS (
  SELECT
    trunc(reported_date, 'MM') AS month_reported,
    count(*) AS number_of_claims,
    round(avg(datediff(closed_date, reported_date))) AS avg_processing_time_days,
    count_if(closed_date IS NULL) AS closed_claims_without_closed_date
  FROM $claimsTable
  WHERE damage_type = 'Water damage'
    AND status = 'closed'
$window
  GROUP BY ALL
)
SELECT monthly.*, knowledge.knowledge_hub_note
FROM monthly
LEFT JOIN $monthView AS knowledge ON knowledge.month = monthly.month_reported
ORDER BY monthly.month_reported
"@
    },
    @{
        question = 'Why were there so many claims in January?'
        sql      = @"
WITH monthly AS (
  SELECT
    trunc(reported_date, 'MM') AS month_reported,
    damage_type,
    count(*) AS number_of_claims
  FROM $claimsTable
  WHERE true
$window
  GROUP BY ALL
)
SELECT monthly.*, knowledge.knowledge_hub_note
FROM monthly
LEFT JOIN $monthView AS knowledge ON knowledge.month = monthly.month_reported
ORDER BY monthly.damage_type, monthly.month_reported
"@
    }
)

$tables = @(
    $claimsTable,
    "$Catalog.claims.customers",
    "$Catalog.claims.policies",
    "$Catalog.claims.claim_payments",
    $pagesTable,
    $monthView
)
# Genie expects the tables sorted by code point, which Sort-Object does not do
[Array]::Sort($tables, [StringComparer]::Ordinal)

$space = [ordered]@{
    version      = 2
    config       = @{
        sample_questions = @($examples | ForEach-Object { @{ id = New-Id $_.question; question = @($_.question) } } | Sort-Object { $_.id })
    }
    data_sources = @{
        tables = @($tables | ForEach-Object { @{ identifier = $_ } })
    }
    instructions = [ordered]@{
        text_instructions     = @(@{ id = New-Id 'instructions'; content = @($instructions) })
        example_question_sqls = @($examples | ForEach-Object { @{ id = New-Id "example $($_.question)"; question = @($_.question); sql = @($_.sql) } } | Sort-Object { $_.id })
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
