param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$out=Join-Path $root "build\v$version"
if($BinDir -eq ''){$BinDir=Join-Path $out 'bin'}
function LP([string]$p){$p.Replace('\','/')}
$lines=@(
 '(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$BinDir\BHT.Bridge.dll")+'"'),
 ('(setq *bht-no-launch* T *bht-module-root* "'+(LP "$root\src\lisp")+'")'),
 ('(load "'+(LP "$root\src\lisp\BHT-$version.lsp")+'")'),
 ('(load "'+(LP "$PSScriptRoot\test_HEADING.lsp")+'")'),
 '(bht:route-set-start-dir "HEAD-ROUTE" (quote (0.0 0.0 0.0)) 1)',
 '(setq *bht-route-selected* "HEAD-ROUTE")',
 '(bht:kh-place-options "HEAD-A" "DIRECT" "ROUTE_PERP" "0")','8,-5',
 '(heading-check "single-unlinked-selects-route-and-perpendicular" (and (heading-same-angle (heading-angle "HEAD-A") 0.0) (= (bht:get (bht:obj-read "HEAD-A") "sign_heading_route") "HEAD-ROUTE")))',
 '(setq *bht-route-selected* "HEAD-ROUTE")',
 '(bht:kh-place-options "HEAD-B" "ELBOW" "ROUTE_PERP" "0")','15,5',
 '(heading-check "single-local-north-tangent" (heading-same-angle (heading-angle "HEAD-B") (/ pi 2.0)))',
 '(setq place-rec (bht:obj-read "HEAD-A") place-geom (entget (heading-insert "HEAD-A")))',
 '(bht:kh-place-options "HEAD-A" "DIRECT" "ROUTE_PERP" "0")','',
 '(heading-check "single-cancel-keeps-record-and-geometry" (and (equal place-rec (bht:obj-read "HEAD-A")) (equal place-geom (entget (heading-insert "HEAD-A")))))',
 '(setq *bht-route-selected* "HEAD-ROUTE" place-rec (bht:obj-read "HEAD-FAR") place-geom (entget (heading-insert "HEAD-FAR")))',
 '(setq place-result (bht:kh-place-options "HEAD-FAR" "DIRECT" "ROUTE_PERP" "0"))',
 '(heading-check "single-out-of-range-error-keeps-record-and-geometry" (and (eq (car place-result) (quote LOI)) (equal place-rec (bht:obj-read "HEAD-FAR")) (equal place-geom (entget (heading-insert "HEAD-FAR")))))',
 '(setq *bht-route-selected* "HEAD-ROUTE")',
 '(bht:kh-place-options "HEAD-CUSTOM" "DIRECT" "ROUTE_PERP" "0")','30,-5',
 '(heading-check "single-custom-native-X-perpendicular" (heading-same-angle (heading-angle "HEAD-CUSTOM") (/ pi 2.0)))',
 '(bht:route-set-start-dir "HEAD-ROUTE" (quote (10.0 10.0 0.0)) -1)',
 '(bht:symbol-sync-ex (quote ("HEAD-A" "HEAD-B")) nil)',
 '(heading-check "single-persists-heading-on-refresh-route-reverse" (and (heading-same-angle (heading-angle "HEAD-A") pi) (heading-same-angle (heading-angle "HEAD-B") (* 1.5 pi))))',
 '(heading-check "single-preserves-survey-points" (equal heading-rtk (list (entget heading-p1 (quote ("BHT_PT"))) (entget heading-p2 (quote ("BHT_PT"))))))',
 '(princ (strcat "\nHEADING-FINAL-FAIL=" (itoa heading-fails)))',
 '_.QUIT','_Y'
)
$scr=Join-Path $out 'placement640.scr'
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'placement640.log'
& "$AcadDir\accoreconsole.exe" /isolate BHTPlacement640 (Join-Path $out 'placement640-profile') /s $scr /l en-US > $log
$report=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
$report -split "`n" | Where-Object {$_ -match '^(PASS|FAIL) HEADING|^HEADING-(FINAL-)?FAIL='} | ForEach-Object {Write-Host $_}
if($report -notmatch 'HEADING-FINAL-FAIL=0' -or $report -match 'FAIL HEADING|; error:'){throw 'Bulk heading integration failed'}
