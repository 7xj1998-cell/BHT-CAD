param([Parameter(Mandatory=$true)][string]$Installer)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$work = Join-Path $root ('build\v' + $version + '\installer-test-' + [guid]::NewGuid().ToString('N'))
$portable = Join-Path $work 'Gửi máy khác & kiểm tra'
New-Item -ItemType Directory -Path $portable | Out-Null
$copy = Join-Path $portable 'Bộ cài BHT.exe'
Copy-Item -LiteralPath $Installer -Destination $copy
function Fingerprint([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return '' }
  return ((Get-ChildItem -LiteralPath $path -File -Recurse | Sort-Object FullName | ForEach-Object { $_.FullName + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }) -join "`n")
}
$installed = Join-Path $env:APPDATA 'Autodesk\ApplicationPlugins\BHT.bundle'
$before = Fingerprint $installed
$report = Join-Path $portable 'Kết quả xác minh.txt'
$process = Start-Process -FilePath $copy -ArgumentList @('--validate-only','--report',('"' + $report + '"')) -WindowStyle Hidden -Wait -PassThru
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $report)) { throw 'Portable installer validation failed' }
if ((Get-Content -LiteralPath $report -Raw) -notmatch 'Gói cài đặt hợp lệ') { throw 'Portable installer report missing successful validation' }
Write-Host 'PASS one-file-portable-Unicode-space-ampersand-path'
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$probe = Join-Path $work 'probe.exe'
& $csc /nologo /target:exe /platform:x64 /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.IO.Compression.dll "/out:$probe" (Join-Path $PSScriptRoot 'SingleFileInstallerProbe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Installer probe compile failed' }
& $probe $copy $work
if ($LASTEXITCODE -ne 0) { throw 'Installer probe failed' }
$corruptReport = Join-Path $work 'corrupt-report.txt'
$process = Start-Process -FilePath (Join-Path $work 'tampered.exe') -ArgumentList @('--validate-only','--report',('"' + $corruptReport + '"')) -WindowStyle Hidden -Wait -PassThru
if ($process.ExitCode -ne 1 -or (Get-Content -LiteralPath $corruptReport -Raw) -notmatch 'bị thay đổi') { throw 'Corrupted installer was not rejected' }
Write-Host 'PASS corrupted-embedded-payload-rejected'
if ((Fingerprint $installed) -ne $before) { throw 'Validation changed installed BHT' }
Write-Host 'PASS validation-does-not-install-or-change-BHT'
Write-Host ('SINGLE FILE INSTALLER TESTS PASSED: ' + $work)
