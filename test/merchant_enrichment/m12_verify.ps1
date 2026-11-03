param([ValidateSet('Test','Analyze','BuildOn','BuildOff','E2E')][string]$Mode = 'Test', [string]$TestName = '')
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$copy = [System.IO.Path]::GetFullPath((Join-Path $workspace '.dart_tool/m12-synthetic'))
if (-not $copy.StartsWith($workspace + [System.IO.Path]::DirectorySeparatorChar)) { throw 'Unsafe copy path' }
if (Test-Path -LiteralPath $copy) { throw 'Synthetic copy exists: inspect before retrying' }
$utf8 = [System.Text.UTF8Encoding]::new($false)
$dart = 'C:/dev/flutter/bin/cache/dart-sdk/bin/dart.exe'
$flutter = 'C:/dev/flutter/bin/cache/flutter_tools.snapshot'
try {
  New-Item -ItemType Directory -Path $copy | Out-Null
  $files = @(git -C $workspace ls-files lib test docs assets web pubspec.yaml pubspec.lock analysis_options.yaml .metadata)
  $files += @(Get-ChildItem -LiteralPath (Join-Path $workspace 'test/merchant_enrichment') -File | ForEach-Object { 'test/merchant_enrichment/' + $_.Name })
  $files = @($files | Sort-Object -Unique | Where-Object { $_ -ne 'lib/env/env.g.dart' -and -not $_.EndsWith('.env') })
  foreach ($relative in $files) {
    $source = Join-Path $workspace $relative
    $target = Join-Path $copy $relative
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target
    if ((Get-FileHash -LiteralPath $source).Hash -ne (Get-FileHash -LiteralPath $target).Hash) { throw "Source mismatch: $relative" }
  }
  Write-Output "SUT: verified $($files.Count) files against integration worktree; private Env excluded"
  # Execute the actual pre-lot-02 parsers, extracted read-only from the BO base commit.
  foreach ($model in @('merchant_enrichment/enrichment_models.dart', 'assistant_model.dart')) {
    $relative = 'lib/domain/models/' + $model
    $legacyPath = Join-Path $copy ('lib/domain/models/' + $model.Replace('enrichment_models.dart', 'm12_legacy_enrichment_models.dart').Replace('assistant_model.dart', 'm12_legacy_assistant_model.dart'))
    $legacy = git -C $workspace show "9348bdf584a4a91c3684a581c9d3c7120cb0b5d5:$relative"
    if ($LASTEXITCODE -ne 0) { throw 'Historical BO parser unavailable' }
    [System.IO.File]::WriteAllText($legacyPath, (($legacy -join "`n") + "`n"), $utf8)
    Write-Output "Legacy parser from BO 9348bdf: $relative"
  }
  [System.IO.File]::WriteAllText((Join-Path $copy 'lib/env/env.g.dart'), "part of 'env.dart';`nclass _Env { static final String kUrl = 'http://127.0.0.1:9/'; }`n", $utf8)
  $configPath = Join-Path $workspace '.dart_tool/package_config.json'
  $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
  foreach ($package in $config.packages) {
    # Relative root keeps Windows drive casing identical for package/relative imports in the analyzer.
    $package.rootUri = if ($package.name -eq 'back_office_tribuneo_v2') { '../' } else { [System.Uri]::new([System.Uri]::new($configPath), [string]$package.rootUri).AbsoluteUri }
  }
  New-Item -ItemType Directory -Path (Join-Path $copy '.dart_tool') | Out-Null
  [System.IO.File]::WriteAllText((Join-Path $copy '.dart_tool/package_config.json'), ($config | ConvertTo-Json -Depth 20), $utf8)
  Copy-Item -LiteralPath (Join-Path $workspace '.dart_tool/package_graph.json') -Destination (Join-Path $copy '.dart_tool/package_graph.json')
  $env:CI = 'true'; $env:FLUTTER_SKIP_UPDATE_CHECK = 'true'
  Push-Location $copy
  try {
    switch ($Mode) {
      'Test' { & $dart $flutter --no-version-check --suppress-analytics test --no-pub --reporter expanded test/merchant_enrichment test/merchant_enrichment/m12_compatibility.dart test/assistant_repository_test.dart test/assistant_test.dart test/row_save_queue_test.dart test/merchant_import_row_model_test.dart }
      'Analyze' { & $dart $flutter --no-version-check --suppress-analytics analyze --no-pub lib/domain/models/assistant_model.dart lib/domain/repositories/assistant_repository.dart lib/domain/models/merchant_enrichment lib/domain/usecases/merchant_enrichment lib/presentation/widgets/assistant lib/presentation/widgets/merchant_enrichment test/merchant_enrichment }
      'BuildOn' { & $dart $flutter --no-version-check --suppress-analytics build web --release --no-pub --dart-define=NEO_CHAT_ENABLED=true --dart-define=MERCHANT_ENRICHMENT_ENABLED=true }
      'BuildOff' { & $dart $flutter --no-version-check --suppress-analytics build web --release --no-pub --dart-define=NEO_CHAT_ENABLED=false --dart-define=MERCHANT_ENRICHMENT_ENABLED=false }
      'E2E' { $filter = @(); if ($TestName) { $filter = @('--plain-name', $TestName) }; & $dart $flutter --no-version-check --suppress-analytics test --no-pub --reporter expanded --dart-define=ENRICHMENT_E2E=http://127.0.0.1 @filter test/merchant_enrichment/live_local_api.dart }
    }
    if ($LASTEXITCODE -ne 0) { throw "Flutter $Mode failed: $LASTEXITCODE" }
  } finally { Pop-Location }
} finally {
  # Only this exact disposable copy, inside this integration workspace.
  $expected = [System.IO.Path]::GetFullPath((Join-Path $workspace '.dart_tool/m12-synthetic'))
  if ($copy -eq $expected -and $copy.StartsWith($workspace + [System.IO.Path]::DirectorySeparatorChar) -and (Test-Path -LiteralPath $copy)) {
    Remove-Item -LiteralPath $copy -Recurse -Force
  }
}
