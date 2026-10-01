$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$taskVersionRoot = Join-Path $root ('build\version-policy-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $taskVersionRoot | Out-Null
foreach ($dir in @('src','scripts','packaging','tests')) { Copy-Item -LiteralPath (Join-Path $root $dir) -Destination $taskVersionRoot -Recurse }
New-Item -ItemType Directory -Path (Join-Path $taskVersionRoot 'docs') | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'docs\HUONG_DAN.md') -Destination (Join-Path $taskVersionRoot 'docs')
foreach ($name in @('VERSION','README.md','CHANGELOG.md','AGENTS.md')) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $taskVersionRoot }
@{ version = $version; contentHash = 'deliberately-different-for-test' } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $taskVersionRoot 'RELEASE_STATE.json') -Encoding UTF8
$blocked = $false
try { & (Join-Path $taskVersionRoot 'scripts\package.ps1') -SkipBuild }
catch { Write-Host ('Guard result: ' + $_.Exception.Message); $blocked = $_.Exception.Message.Contains('Phải tăng phiên bản') }
if (-not $blocked) { throw 'FAIL: changed content was accepted under the same version' }
Write-Host 'PASS release-policy: changed content requires a version bump'
$parsed = [version]$version
$nextVersion = "$($parsed.Major).$($parsed.Minor).$($parsed.Build + 1)"
& (Join-Path $taskVersionRoot 'scripts\set-version.ps1') -Version $nextVersion
if ((Get-Content -LiteralPath (Join-Path $taskVersionRoot 'VERSION') -Raw).Trim() -ne $nextVersion) { throw 'FAIL: next version not saved' }
Write-Host 'PASS release-policy: version tool synchronizes all runtime metadata'
$blocked = $false
try { & (Join-Path $taskVersionRoot 'scripts\set-version.ps1') -Version $version }
catch { $blocked = $_.Exception.Message.Contains('must exceed') }
if (-not $blocked) { throw 'FAIL: downgrade accepted' }
Write-Host 'PASS release-policy: downgrade rejected'
if ((Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim() -ne $version) { throw 'FAIL: real source version modified by tests' }
Write-Host 'PASS release-policy: real source unchanged'
