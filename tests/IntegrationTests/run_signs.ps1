param([string]$AcadDir = 'D:\AutoCAD 2024', [string]$BinDir = '', [switch]$SkipBuild, [string]$RuntimePath = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ($RuntimePath -eq '') { $RuntimePath = Join-Path $root "src\lisp\BHT-$version.lsp" }
$out = Join-Path $root ("build\v" + $version)
if ($BinDir -eq '') { $BinDir = Join-Path $out 'bin' }
New-Item -ItemType Directory -Force -Path $out | Out-Null
if (-not $SkipBuild) {
  & (Join-Path $root 'scripts\build.ps1') -AcadDir $AcadDir -OutDir $BinDir -UseCsc -Test
  if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
}
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$probe = Join-Path $BinDir 'SignLibraryProbe.dll'
& $csc /nologo /target:library /platform:x64 "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Bridge.dll" "/out:$probe" (Join-Path $PSScriptRoot 'SignLibraryProbe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Probe compile failed' }
function LispPath([string]$path) { return $path.Replace('\','/') }
$lines = @('(setvar "SECURELOAD" 0)', '(setvar "LISPSYS" 1)', '_.NETLOAD', ('"' + (LispPath "$BinDir\BHT.Bridge.dll") + '"'), '_.NETLOAD', ('"' + (LispPath $probe) + '"'), 'BHTSIGNPROBE', ('(load "' + (LispPath "$root\src\lisp\BHT-$version.lsp") + '")'), ('(load "' + (LispPath "$PSScriptRoot\test_SIGN.lsp") + '")'), ('(load "' + (LispPath "$PSScriptRoot\font_expected.lsp") + '")'), ('(load "' + (LispPath "$PSScriptRoot\test_TCVN.lsp") + '")'), '_.QUIT', '_Y')
$lines = @(('(setq *bht-module-root* "' + (LispPath "$root\src\lisp") + '" )')) + $lines
$lines = $lines | ForEach-Object { $_.Replace((LispPath "$root\src\lisp\BHT-$version.lsp"), (LispPath $RuntimePath)) }
# Exercise actual getangle/getpoint prompts, cancellation, undo-corner and rotated UCS.
$interactive = @(
  '(setq before-free-input (bht:obj-read "OBJ-SIGN"))',
  '(bht:kh-place-free "OBJ-SIGN")', '90', '55,-9', '56,-12', 'Xoa', 'Dat', '',
  '(signs-check "free-input-cancel-atomic" (equal before-free-input (bht:obj-read "OBJ-SIGN")))',
  '_.UCS', '_Z', '30',
  '(bht:kh-place-free "OBJ-SIGN")', '45', '57,-10', '61,-15', 'Xoa', '62,-16', 'Dat', '80,-30',
  '(signs-check "free-input-rotated-UCS-angle" (equal (cadr (bht:kh-free-transform (bht:obj-read "OBJ-SIGN"))) (* pi (/ 75.0 180.0)) 1e-6))',
  '(signs-check "free-input-two-corners" (= (length (bht:kh-via-points (bht:obj-read "OBJ-SIGN"))) 2))',
  '_.UCS', '_World',
  '(setq quick-before (bht:obj-read "OBJ-SIGN"))',
  '(bht:kh-place-options "OBJ-SIGN" "DIRECT" "HORIZONTAL" "0")', '',
  '(signs-check "quick-cancel-no-change" (equal quick-before (bht:obj-read "OBJ-SIGN")))',
  '(bht:kh-place-options "OBJ-SIGN" "DIRECT" "HORIZONTAL" "0")', '100,-20',
  '(signs-check "quick-direct-one-click" (and (equal (car (bht:kh-free-transform (bht:obj-read "OBJ-SIGN"))) (quote (100.0 -20.0 0.0)) 1e-6) (= (length (bht:kh-via-points (bht:obj-read "OBJ-SIGN"))) 0)))',
  '(bht:kh-place-options "OBJ-SIGN" "ELBOW" "ANGLE" "30")', '90,-25',
  '(signs-check "quick-auto-elbow-angle" (and (= (length (bht:kh-via-points (bht:obj-read "OBJ-SIGN"))) 1) (equal (cadr (bht:kh-free-transform (bht:obj-read "OBJ-SIGN"))) (/ pi 6) 1e-6)))',
  '(bht:kh-place-options "OBJ-SIGN" "DIRECT" "ROUTE" "0")', '95,-30',
  '(signs-check "quick-route-angle" (equal (cadr (bht:kh-free-transform (bht:obj-read "OBJ-SIGN"))) (cadr (bht:kh-route-transform (bht:obj-read "OBJ-SIGN") (bht:obj-position (bht:obj-read "OBJ-SIGN") (bht:pt-all)) (bht:kh-scale))) 1e-6))',
  '(setq quick-before (bht:obj-read "OBJ-SIGN"))',
  '(bht:kh-place-options "OBJ-SIGN" "DIRECT" "PICK" "0")', '80,-30', '',
  '(signs-check "quick-cancel-direction-no-change" (equal quick-before (bht:obj-read "OBJ-SIGN")))',
  '(setq before-label-review (bht:pt-all))',
  '(c:BHTNHANDIEM)', 'A',
  '(signs-check "label-menu-hide" (= (bht:meta "nhan_an" "0") "1"))',
  '(c:BHTANNHAN)',
  '(signs-check "label-old-alias-shows" (= (bht:meta "nhan_an" "1") "0"))',
  '(c:BHTNHANDIEM)', 'H',
  '(signs-check "label-menu-show" (= (bht:meta "nhan_an" "1") "0"))',
  '(signs-check "label-show-keeps-RTK" (equal before-label-review (bht:pt-all)))',
  '(princ (strcat "\nFREE-INPUT-FAIL=" (itoa *sign-test-fail*)))'
)
$apiProbeResult = Join-Path $BinDir 'assembly-api.txt'
if (Test-Path -LiteralPath $apiProbeResult) { Remove-Item -LiteralPath $apiProbeResult }
$lines = $lines[0..($lines.Count - 3)] + $interactive + @('BHTASSEMBLYAPIPROBE', '_.QUIT', '_Y')
$scr = Join-Path $out 'run.scr'
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[IO.File]::WriteAllLines($scr, $lines, $utf8Bom)
$log = Join-Path $out 'console-raw.txt'
# Separate test profile prevents installed TDT startup reactors/menu scripts entering the test process.
$isolation = Join-Path $out 'coreconsole-profile'
New-Item -ItemType Directory -Force -Path $isolation | Out-Null
& "$AcadDir\accoreconsole.exe" /isolate BHTSignTests $isolation /p "<<Unnamed Profile>>" /s $scr /l en-US > $log
$console = [IO.File]::ReadAllText($log).Replace([string][char]0, '')
if ($console -match '; error:|malformed list|no function definition') { throw 'Lisp execution error in sign tests' }
if (-not (Test-Path -LiteralPath $apiProbeResult)) { throw 'Palette acedInvoke assembly probe did not complete' }
Write-Host ([IO.File]::ReadAllText($apiProbeResult))
$console | Set-Content -LiteralPath (Join-Path $out 'console.txt') -Encoding UTF8
$results = Get-Content -LiteralPath (Join-Path $BinDir 'probe.txt')
$results | ForEach-Object { Write-Host $_ }
$console -split "`n" | Where-Object { $_ -match 'PASS SIGN|FAIL SIGN|SIGN-TEST-FAIL|PASS TCVN|FAIL TCVN|TCVN-TEST-FAIL' } | ForEach-Object { Write-Host $_ }
if (($results -match '^FAIL') -or ($console -match 'FAIL SIGN|FAIL TCVN|TCVN-TEST-FAIL=[1-9]') -or ($console -notmatch 'SIGN-TEST-FAIL=0') -or ($console -notmatch 'TCVN-TEST-FAIL=0') -or ($console -notmatch 'FREE-INPUT-FAIL=0')) { throw 'Sign integration tests failed' }
Write-Host 'SIGN INTEGRATION PASSED'


$pickerExe = Join-Path $BinDir 'PickerProbe.exe'
& $csc /nologo /target:exe /platform:x64 /r:System.Windows.Forms.dll /r:System.Drawing.dll "/r:$BinDir\BHT.Palette.dll" "/r:$BinDir\BHT.Bridge.dll" "/r:$BinDir\BHT.Core.dll" "/out:$pickerExe" (Join-Path $PSScriptRoot 'PickerProbe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Picker probe compile failed' }
& $pickerExe $AcadDir
if ($LASTEXITCODE -ne 0) { throw 'Picker probe failed' }

