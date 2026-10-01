$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$bhtVersion = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$sourceText = [IO.File]::ReadAllText((Join-Path $root 'packaging\INSTALL_BHT.ps1'))
$start = $sourceText.IndexOf('function Test-BhtPackage')
$end = $sourceText.IndexOf('function Write-Ok', $start)
. ([scriptblock]::Create($sourceText.Substring($start,$end-$start)))
$fixture = Join-Path $root ('build\installer-test-' + [guid]::NewGuid().ToString('N'))
$bundle = Join-Path $fixture 'BHT.bundle'
$windows = Join-Path $bundle 'Contents\Windows'
New-Item -ItemType Directory -Force -Path $windows | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'packaging\BHT.bundle\PackageContents.xml') -Destination $bundle
Copy-Item -LiteralPath (Join-Path $root "src\lisp\BHT-$bhtVersion.lsp") -Destination $windows -Recurse
Copy-Item -LiteralPath (Join-Path $root 'src\lisp\modules') -Destination $windows -Recurse
foreach($name in @('Core','Bridge','Palette')) { Copy-Item -LiteralPath (Join-Path $root "build\v$bhtVersion\bin\BHT.$name.dll") -Destination $windows }
$manifest = Join-Path $fixture 'SHA256SUMS.txt'
$lines = Get-ChildItem -LiteralPath $bundle -File -Recurse | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash + '  ' + $_.FullName.Substring($fixture.Length+1).Replace('\','/') }
[IO.File]::WriteAllLines($manifest,$lines)
function Expect-Rejected([string]$name) {
  $rejected = $false
  try { Test-BhtPackage $fixture | Out-Null } catch { $rejected = $true }
  if(-not $rejected){throw "FAIL $name"}; Write-Host "PASS $name"
}
Test-BhtPackage $fixture | Out-Null; Write-Host 'PASS valid-package'
$module = Join-Path $windows "BHT-$bhtVersion.lsp"; $original = [IO.File]::ReadAllBytes($module)
[IO.File]::AppendAllText($module,'; tampered'); Expect-Rejected 'changed-module'; [IO.File]::WriteAllBytes($module,$original)
Remove-Item -LiteralPath $module; Expect-Rejected 'missing-module'; [IO.File]::WriteAllBytes($module,$original)
$extra = Join-Path $windows 'unlisted.lsp'; [IO.File]::WriteAllText($extra,'; unexpected'); Expect-Rejected 'unlisted-executable'; Remove-Item -LiteralPath $extra
[IO.File]::AppendAllText($manifest,"`n" + ('0'*64) + '  ../outside.lsp'); Expect-Rejected 'manifest-path-traversal'; [IO.File]::WriteAllLines($manifest,$lines)
$plugins = Join-Path $fixture 'Plugins'; $target = Join-Path $plugins 'BHT.bundle'; New-Item -ItemType Directory -Force -Path $target | Out-Null; [IO.File]::WriteAllText((Join-Path $target 'old.txt'),'old-release')
Install-BhtBundle $bundle $plugins | Out-Null
$backup = @(Get-ChildItem -LiteralPath $plugins -Directory -Filter 'BHT-backup-*')
if($backup.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $backup[0].FullName 'old.txt'))){throw 'FAIL old-release-backup'}; Write-Host 'PASS old-release-backup'
function Move-Item([string]$LiteralPath,[string]$Destination) {
  if([IO.Path]::GetFileName($LiteralPath).StartsWith('BHT-stage-')) { throw 'simulated replacement failure' }
  Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
}
$failed=$false; try{Install-BhtBundle $bundle $plugins | Out-Null}catch{$failed=$true}
if(-not $failed -or -not(Test-Path -LiteralPath (Join-Path $target "Contents\Windows\BHT-$bhtVersion.lsp"))){throw 'FAIL rollback'}; Write-Host 'PASS rollback-after-replacement-failure'
Write-Host 'INSTALLER SECURITY TESTS PASSED (7 checks, isolated fixture)'
