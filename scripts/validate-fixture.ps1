$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path $root "examples\toy-python-service"
$app = Join-Path $fixture "app.py"
$expected = Join-Path $fixture "TECH_DEBT_AUDIT.expected.md"

if (-not (Test-Path -LiteralPath $app)) {
  throw "Missing fixture app: $app"
}

if (-not (Test-Path -LiteralPath $expected)) {
  throw "Missing expected audit: $expected"
}

$appLines = Get-Content -LiteralPath $app
$expectedText = Get-Content -LiteralPath $expected -Raw

$checks = @(
  @{ Ref = "app.py:5";  Pattern = 'select \* from users where id = " \+ user_id' },
  @{ Ref = "app.py:10"; Pattern = 'DATABASE_URL' },
  @{ Ref = "app.py:11"; Pattern = 'dev-secret-key' },
  @{ Ref = "app.py:18"; Pattern = 'print\("running query"' }
)

foreach ($check in $checks) {
  $parts = $check.Ref.Split(":")
  $lineNumber = [int]$parts[1]
  $line = $appLines[$lineNumber - 1]

  if ($line -notmatch $check.Pattern) {
    throw "Fixture line $($check.Ref) no longer matches expected pattern. Actual: $line"
  }

  if ($expectedText -notmatch [regex]::Escape($check.Ref)) {
    throw "Expected audit does not cite $($check.Ref)"
  }
}

Write-Output "Fixture validation passed."
