param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($BinDir -eq ''){$BinDir=Join-Path $root "build\v$version\bin-final"}
$out=Join-Path $root "build\v$version"
$lines=@(
 '(setvar "SECURELOAD" 0)', '_.NETLOAD', ('"'+("$BinDir\BHT.Bridge.dll").Replace('\','/')+'"'),
 ('(setq *bht-no-launch* T *bht-module-root* "'+("$root\src\lisp").Replace('\','/')+'")'),
 ('(load "'+("$root\src\lisp\BHT-$version.lsp").Replace('\','/')+'")'),
 '(setq route-fails 0)',
 '(defun route-check (name ok) (if (not ok) (setq route-fails (1+ route-fails))) (princ (strcat "\n" (if ok "PASS ROUTE " "FAIL ROUTE ") name)))',
 '(setq route-pl (entmakex (quote ((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 2) (70 . 0) (10 0.0 0.0) (10 100.0 0.0)))) route-pl-before (entget route-pl))',
 # Deterministic selection fixture; point/confirmation input uses native CAD prompts.
 '(defun entsel (prompt) (list route-pl (quote (50.0 0.0 0.0))))',
 '(c:BHTTUYEN)', 'PL-START','D','100','0','100,0','D','C',
 '(setq route-rec (bht:route-read "PL-START"))',
 '(route-check "ordinary-PL-creation-prompts-start-and-direction" (and (= (bht:get route-rec "start_dist") "100.000000") (= (bht:get route-rec "direction") "-1")))',
 '(route-check "ordinary-PL-keeps-source-geometry" (equal route-pl-before (entget route-pl)))',
 '(bht:route-add-mark "PL-START" 0.0 1000.0 1000.0 "QA" "")',
 '(setq route-before (bht:route-read "PL-START"))',
 '(c:BHTROUTESTART)','50,0','K',
 '(route-check "cancel-direction-keeps-record-and-marks" (equal route-before (bht:route-read "PL-START")))',
 '(c:BHTROUTESTART)','',
 '(route-check "skip-point-keeps-record-and-marks" (equal route-before (bht:route-read "PL-START")))',
 '_.UCS','_Z','30',
 '(bht:route-pick-start "PL-START")','43.3012701892,-25','C',
 '(setq route-rec (bht:route-read "PL-START"))',
 '(route-check "start-pick-transforms-UCS-to-WCS" (equal (bht:num (bht:get route-rec "start_dist")) 50.0 1e-5))',
 '(route-check "change-start-preserves-marks-and-flags-review" (and (= (length (bht:route-marks route-rec)) 1) (= (bht:get route-rec "station_control_status") "NEEDS_REVIEW")))',
 '_.UCS','_World',
 # Adapter fixture provides a copied reference without requiring the vendor ARX in Core Console.
 '(setq route-ref (entmakex (quote ((0 . "LWPOLYLINE") (100 . "AcDbEntity") (8 . "0") (100 . "AcDbPolyline") (90 . 2) (70 . 0) (10 0.0 10.0) (10 100.0 10.0)))) route-source-before (entget route-pl))',
 '(defun BHTTDT91ROUTE (source existing) (list "OK" (cdr (assoc 5 (entget route-ref))) "TDT_ADAPTER_FIXTURE"))',
 '(c:BHTTUYENTDT)','TDT-START','100','0','100,10','D','C',
 '(setq route-rec (bht:route-read "TDT-START"))',
 '(route-check "new-TDT-reference-prompts-start-and-direction" (and (= (bht:get route-rec "start_dist") "100.000000") (= (bht:get route-rec "direction") "-1")))',
 '(route-check "TDT-source-and-reference-retained" (and (equal route-source-before (entget route-pl)) (= (bht:get route-rec "handle") (cdr (assoc 5 (entget route-ref))))))',
 '(setq route-before (bht:route-read "TDT-START"))',
 '(c:BHTTUYENTDT)',
 '(setq route-rec (bht:route-read "TDT-START"))',
 '(route-check "TDT-refresh-keeps-confirmed-start-direction" (and (= (bht:get route-rec "start_dist") (bht:get route-before "start_dist")) (= (bht:get route-rec "direction") (bht:get route-before "direction"))))',
 '(route-check "preview-arrow-cleaned" (null (ssget "_X" (quote ((62 . 2))))))',
 '(princ (strcat "\nROUTE-START-FAIL=" (itoa route-fails)))','_.QUIT','_Y'
)
$scr=Join-Path $out 'route-start.scr'
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'route-start.log'
& "$AcadDir\accoreconsole.exe" /isolate BHTRouteStart (Join-Path $out 'route-start-profile') /s $scr /l en-US > $log
$report=[IO.File]::ReadAllText($log).Replace([string][char]0,'')
$report -split "`n" | Where-Object {$_ -match '^PASS ROUTE|^FAIL ROUTE|ROUTE-START-FAIL='} | Write-Output
if($report -notmatch 'ROUTE-START-FAIL=0' -or $report -match '(?m)^FAIL ROUTE|; error:'){throw 'Route start integration failed'}
