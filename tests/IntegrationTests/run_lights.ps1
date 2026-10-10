param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='',[string]$RuntimePath='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$out=Join-Path $root "build\v$version"
if($BinDir -eq ''){$BinDir=Join-Path $out 'bin-release'}
$probe=Join-Path $BinDir 'LightLibraryProbe.dll'
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:library /platform:x64 "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Bridge.dll" "/out:$probe" (Join-Path $PSScriptRoot 'LightLibraryProbe.cs')
if($LASTEXITCODE -ne 0){throw 'Light probe compile failed'}
function LP([string]$p){$p.Replace('\','/')}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$BinDir\BHT.Bridge.dll")+'"'),'_.NETLOAD',('"'+(LP $probe)+'"'),'BHTLIGHTPROBE',
 ('(setq *bht-no-launch* T *bht-module-root* "'+(LP "$root\src\lisp")+'")'),('(load "'+(LP "$root\src\lisp\BHT-$version.lsp")+'")'),
 '(setq light-fails 0)',
 '(defun light-check (name ok) (if (not ok) (setq light-fails (1+ light-fails))) (princ (strcat "\n" (if ok "PASS LIGHT " "FAIL LIGHT ") name)))',
 '(setq light-block nil light-row (tblnext "BLOCK" T)) (while light-row (if (wcmatch (cdr (assoc 2 light-row)) "BHT_LIGHT_DEN_CS_DON_MB_*") (setq light-block (cdr (assoc 2 light-row)))) (setq light-row (tblnext "BLOCK")))',
 '(setq light-p (entmakex (quote ((0 . "POINT") (10 100.0 100.0 0.0)))))',
 '(bht:pt-write-xdata light-p "LIGHT-PT" "QA" "1" "1" 100.0 100.0 0.0 "DEN" "test" "" "")',
 '(setq light-before (entget light-p (quote ("BHT_PT"))))',
 '(bht:obj-create "LIGHT-OBJ" (list (cons "nhom" "DEN") (cons "custom_block" light-block)) (quote ("LIGHT-PT")) T)',
 '(bht:kh-free-apply "LIGHT-OBJ" (quote (102.0 100.0 0.0)) 0.0 nil)',
 '(light-check "per-object-custom-light-keeps-RTK" (equal light-before (entget light-p (quote ("BHT_PT")))))',
 '(light-check "per-object-imported-light-used" (assoc "LIGHT-OBJ" (bht:tagged-pairs "INSERT" "BHT_KH" 1)))',
 '(light-check "library-head-north-uses-native-Y" (equal (bht:kh-picked-rotation (bht:obj-read "LIGHT-OBJ") (quote (0.0 0.0 0.0)) (quote (0.0 1.0 0.0))) 0.0 1e-8))',
 '(light-check "library-head-east-uses-native-Y" (equal (bht:kh-picked-rotation (bht:obj-read "LIGHT-OBJ") (quote (0.0 0.0 0.0)) (quote (1.0 0.0 0.0))) (- (/ pi 2.0)) 1e-8))',
 ('(load "'+(LP (Join-Path $PSScriptRoot 'test_LIGHT646.lsp'))+'")'),
 ('(load "'+(LP (Join-Path $PSScriptRoot 'test_LIGHT648.lsp'))+'")'),
 '(princ (strcat "\nLIGHT-FAIL=" (itoa light-fails)))','_.QUIT','_Y')
if($RuntimePath){$lines=@($lines | ForEach-Object {$_.Replace(("$root\src\lisp\BHT-$version.lsp").Replace('\','/'),$RuntimePath.Replace('\','/'))})}
$scr=Join-Path $out 'lights.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'lights.log'
& "$AcadDir\accoreconsole.exe" /isolate BHTLights (Join-Path $out 'lights-test-profile') /s $scr /l en-US > $log
$report=Get-Content -LiteralPath (Join-Path $BinDir 'light-probe.txt');$report | ForEach-Object {Write-Host $_}
$console=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
if($report -match '^FAIL' -or $console -notmatch 'LIGHT-FAIL=0' -or $console -match '; error:|(?m)^FAIL LIGHT'){throw 'Light library integration failed'}
Write-Host 'PASS light Lisp placement and direction'
