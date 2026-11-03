param([ValidateSet('Test', 'Analyze')][string]$Mode = 'Test')
$ErrorActionPreference = 'Stop'
$workspace = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$harness = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'research_runtime'))
$expected = Join-Path $workspace 'test/merchant_enrichment/research_runtime'
if ($harness -ne $expected -or -not $harness.StartsWith($workspace + [System.IO.Path]::DirectorySeparatorChar)) { throw 'Unsafe harness path' }
if (Test-Path -LiteralPath $harness) { throw 'Existing harness: inspect it before running.' }
$dart = 'C:/dev/flutter/bin/cache/dart-sdk/bin/dart.exe'
$flutter = 'C:/dev/flutter/bin/cache/flutter_tools.snapshot'
$utf8 = [System.Text.UTF8Encoding]::new($false)
try {
  & python (Join-Path $PSScriptRoot 'research_prepare.py')
  if ($LASTEXITCODE -ne 0) { throw 'Harness preparation failed' }
  $env:CI = 'true'
  $env:FLUTTER_SKIP_UPDATE_CHECK = 'true'
  Push-Location $harness
  try {
    # Windows PowerShell wraps native stderr (even blank Flutter progress) as errors.
    # Exit status remains authoritative; file operations below still fail fast.
    $ErrorActionPreference = 'Continue'
    if ($Mode -eq 'Analyze') {
      $output = & $dart $flutter --no-version-check --suppress-analytics analyze --no-pub `
        lib/domain/models/merchant_enrichment lib/domain/models/assistant_model.dart `
        lib/domain/repositories/merchant_enrichment lib/domain/usecases/merchant_enrichment `
        lib/presentation/widgets/merchant_enrichment lib/presentation/widgets/assistant/assistant_message_view.dart `
        test/merchant_enrichment/research_flow_test.dart 2>&1
      $name = 'ANALYSE_FLUTTER.txt'
    } else {
      $output = & $dart $flutter --no-version-check --suppress-analytics test --no-pub --reporter expanded `
        test/merchant_enrichment/research_flow_test.dart test/merchant_enrichment/chat_comparison_test.dart `
        test/merchant_enrichment/enrichment_panel_test.dart test/merchant_enrichment/enrichment_usecase_test.dart `
        test/merchant_enrichment/vat_panel_test.dart test/merchant_enrichment/vat_usecase_test.dart `
        test/assistant_repository_test.dart test/assistant_test.dart 2>&1
      $name = 'TESTS_FLUTTER.txt'
    }
    $result = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    [System.IO.File]::WriteAllText((Join-Path $workspace "docs/merchant-enrichment/research/$name"), (($output -join "`n") + "`n"), $utf8)
    Copy-Item -LiteralPath (Join-Path $harness 'sources.json') -Destination (Join-Path $workspace 'docs/merchant-enrichment/research/SOURCES_TESTS.json')
    $output | Select-Object -Last 12
    if ($result -ne 0) { throw "Flutter $Mode failed ($result)" }
  } finally { Pop-Location }
} finally {
  # Delete only this verified generated test directory, never Git work or source data.
  if ($harness -eq $expected -and (Test-Path -LiteralPath (Join-Path $harness 'sources.json'))) {
    Remove-Item -LiteralPath $harness -Recurse -Force
  }
}
