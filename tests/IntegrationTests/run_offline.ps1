param([string]$AcadDir = 'D:\AutoCAD 2024', [string]$RuntimePath = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ($RuntimePath -eq '') { $RuntimePath = Join-Path $root "src\lisp\BHT-$version.lsp" }
$out = Join-Path $root "build\v$version"
$bin = Join-Path $out 'bin'
function LP($p) { $p.Replace('\','/') }
$scr = Join-Path $out 'offline.scr'
$lines = @('(setvar "SECURELOAD" 0)', '(setvar "LISPSYS" 1)', ('(setenv "ACAD" (strcat (getenv "ACAD") ";' + (LP "$root\fonts_local") + '"))'), '_.NETLOAD', ('"' + (LP "$bin\BHT.Bridge.dll") + '"'), '_.NETLOAD', ('"' + (LP "$bin\SignLibraryProbe.dll") + '"'), 'BHTOFFLINEPROBE', ('(setq *bht-module-root* "' + (LP "$root\src\lisp") + '")'), ('(load "' + (LP "$root\src\lisp\BHT-$version.lsp") + '")'), ('(load "' + (LP "$PSScriptRoot\test_SIGN.lsp") + '")'), ('(load "' + (LP "$PSScriptRoot\font_expected.lsp") + '")'), ('(load "' + (LP "$PSScriptRoot\test_TCVN.lsp") + '")'), '_.QUIT','_Y')
$lines = $lines | ForEach-Object { $_.Replace((LP "$root\src\lisp\BHT-$version.lsp"), (LP $RuntimePath)) }
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$provider = $env:BHT_SIGN_PROVIDER
try { $env:BHT_SIGN_PROVIDER='BUILTIN'; & "$AcadDir\accoreconsole.exe" /isolate BHTOfflineTests "$out\offline-profile" /p '<<Unnamed Profile>>' /s $scr /l en-US > "$out\offline-raw.txt" }
finally { $env:BHT_SIGN_PROVIDER=$provider }
$log=[IO.File]::ReadAllText("$out\offline-raw.txt").Replace([string][char]0,'')
[IO.File]::WriteAllText("$out\offline-console.txt",$log,[Text.UTF8Encoding]::new($true))
$probe=[IO.File]::ReadAllText("$bin\offline-probe.txt")
Write-Host $probe
if($probe -match 'FAIL' -or $log -match 'FAIL SIGN|FAIL TCVN' -or $log -notmatch 'SIGN-TEST-FAIL=0' -or $log -notmatch 'TCVN-TEST-FAIL=0' -or $log -notmatch 'PASS TCVN native-engine-active') { throw 'Offline or migration regression failed' }
Write-Host 'OFFLINE / NATIVE TEXT REGRESSION PASSED'
$provider=$env:BHT_SIGN_PROVIDER
try { $env:BHT_SIGN_PROVIDER='BUILTIN'; & "$bin\PickerProbe.exe" $AcadDir; if($LASTEXITCODE -ne 0){throw 'Offline picker failed'} }
finally { $env:BHT_SIGN_PROVIDER=$provider }
