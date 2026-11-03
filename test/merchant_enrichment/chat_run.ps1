param([switch]$Analyze)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$mirror = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'chat_harness'))
$allowed = [System.IO.Path]::GetFullPath((Join-Path $workspace 'test/merchant_enrichment/chat_harness'))
if ($mirror -ne $allowed -or -not $mirror.StartsWith($workspace + [System.IO.Path]::DirectorySeparatorChar)) { throw 'Unsafe harness path' }
if (Test-Path -LiteralPath $mirror) { throw 'Harness already exists; inspect it before retrying.' }
$dart = 'C:/dev/flutter/bin/cache/dart-sdk/bin/dart.exe'
$flutter = 'C:/dev/flutter/bin/cache/flutter_tools.snapshot'
Push-Location $workspace
try {
  New-Item -ItemType Directory -Path $mirror | Out-Null
  # Only tracked library sources: no .env, generated private file, keys, or original checkout.
  $files = git ls-files lib
  foreach ($relative in $files) {
    if ($relative -eq 'lib/env/env.g.dart' -or $relative.EndsWith('.env')) { throw 'Private source in tracked list' }
    $source = Join-Path $workspace $relative
    $target = Join-Path $mirror $relative
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target
  }
  # Include the new E04 source files, which have deliberately not been committed.
  $newSources = @('lib/domain/models/merchant_enrichment/chat_context_reference.dart',
    'lib/domain/usecases/merchant_enrichment/chat_comparison_usecase.dart',
    'lib/presentation/widgets/merchant_enrichment/chat_comparison.dart')
  foreach ($relative in $newSources) {
    $target = Join-Path $mirror $relative
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($target)) | Out-Null
    Copy-Item -LiteralPath (Join-Path $workspace $relative) -Destination $target
  }
  $utf8 = [System.Text.UTF8Encoding]::new($false)
  [System.IO.File]::WriteAllText((Join-Path $mirror 'lib/env/env.g.dart'), "part of 'env.dart';`nclass _Env { static final String kUrl = 'http://127.0.0.1:9/'; }`n", $utf8)
  $configPath = Join-Path $workspace '.dart_tool/package_config.json'
  $configUri = [System.Uri]::new($configPath)
  $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json
  foreach ($package in $config.packages) {
    if ($package.name -eq 'back_office_tribuneo_v2') {
      $package.rootUri = [System.Uri]::new($workspace + '/').AbsoluteUri
      $package.packageUri = 'test/merchant_enrichment/chat_harness/lib/'
    } else {
      $package.rootUri = [System.Uri]::new($configUri, [string]$package.rootUri).AbsoluteUri
    }
  }
  $packages = Join-Path $mirror '.dart_tool/package_config.json'
  New-Item -ItemType Directory -Path (Join-Path $mirror '.dart_tool') | Out-Null
  Copy-Item -LiteralPath (Join-Path $workspace '.dart_tool/package_graph.json') -Destination (Join-Path $mirror '.dart_tool/package_graph.json')
  Copy-Item -LiteralPath (Join-Path $workspace 'pubspec.yaml') -Destination (Join-Path $mirror 'pubspec.yaml')
  Copy-Item -LiteralPath (Join-Path $workspace 'pubspec.lock') -Destination (Join-Path $mirror 'pubspec.lock')
  [System.IO.File]::WriteAllText($packages, ($config | ConvertTo-Json -Depth 20), $utf8)
  # Prove every mirrored source matches the current worktree before compiling.
  foreach ($relative in @($files) + $newSources) {
    if ((Get-FileHash -LiteralPath (Join-Path $workspace $relative)).Hash -ne
        (Get-FileHash -LiteralPath (Join-Path $mirror $relative)).Hash) { throw "Source mismatch: $relative" }
  }
  $env:CI = 'true'
  $env:FLUTTER_SKIP_UPDATE_CHECK = 'true'
  if ($Analyze) {
    & $dart $flutter --no-version-check --suppress-analytics analyze --no-pub `
      lib/domain/models/assistant_model.dart lib/domain/repositories/assistant_repository.dart `
      lib/domain/models/merchant_enrichment lib/domain/usecases/merchant_enrichment/chat_comparison_usecase.dart `
      lib/presentation/widgets/assistant lib/presentation/widgets/merchant_enrichment test/merchant_enrichment/chat_comparison_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Analyze failed' }
  } else {
    & $dart $flutter --no-version-check --suppress-analytics test --no-pub --packages=$packages --reporter expanded `
      test/merchant_enrichment/chat_comparison_test.dart test/assistant_repository_test.dart test/assistant_test.dart `
      test/merchant_enrichment/enrichment_panel_test.dart test/merchant_enrichment/enrichment_usecase_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed' }
  }
} finally {
  Pop-Location
  # Exact, verified directory created by this script; no computed target outside workspace.
  if ($mirror -eq $allowed) {
    # The analyzer may release its Windows directory handle shortly after exit.
    for ($attempt = 0; $attempt -lt 30 -and (Test-Path -LiteralPath $mirror); $attempt++) {
      try { Remove-Item -LiteralPath $mirror -Recurse -Force -ErrorAction Stop }
      catch { if ($attempt -eq 29) { throw }; Start-Sleep -Milliseconds 200 }
    }
  }
}
