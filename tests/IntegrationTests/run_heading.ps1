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
 'BHTHUONGBIEN','T','HEAD-ROUTE','A',
 '(heading-check "native-route-all-perpendicular-to-selected-route" (and (heading-same-angle (heading-angle "HEAD-A") 0.0) (heading-same-angle (heading-angle "HEAD-B") (/ pi 2.0))))',
 '_.UCS','_Z','30',
 'BHTHUONGBIEN','H','0,0','0,10','A',
 '(heading-check "native-perpendicular-AB-respects-rotated-UCS" (and (heading-same-angle (heading-angle "HEAD-A") (* pi (/ 2.0 3.0))) (heading-same-angle (heading-angle "HEAD-B") (* pi (/ 2.0 3.0)))))',
 '_.UCS','_World',
 '(setq heading-undo-rec (bht:obj-read "HEAD-A") heading-undo-transform (heading-transform "HEAD-A") heading-undo-angle (heading-angle "HEAD-A"))',
 'BHTHUONGBIEN','H','0,0','10,0','A',
 '_.UNDO','1',
 '(heading-check "native-one-undo-restores-record-and-symbol" (and (equal heading-undo-rec (bht:obj-read "HEAD-A")) (equal heading-undo-transform (heading-transform "HEAD-A")) (heading-same-angle heading-undo-angle (heading-angle "HEAD-A"))))',
 '(setq heading-before-rec (bht:obj-read "HEAD-A") heading-before-d (entget (heading-insert "HEAD-A")))',
 'BHTHUONGBIEN','H','',
 '(heading-check "native-cancel-A-no-mutation" (and (equal heading-before-rec (bht:obj-read "HEAD-A")) (equal heading-before-d (entget (heading-insert "HEAD-A")))))',
 'BHTHUONGBIEN','H','0,0','',
 '(heading-check "native-cancel-B-no-mutation" (equal heading-before-rec (bht:obj-read "HEAD-A")))',
 'BHTHUONGBIEN','H','0,0','0,0',
 '(heading-check "native-zero-length-AB-no-mutation" (equal heading-before-rec (bht:obj-read "HEAD-A")))',
 'BHTHUONGBIEN','H','0,0','10,0','C','',
 '(heading-check "native-empty-selection-no-mutation" (equal heading-before-rec (bht:obj-read "HEAD-A")))',
 '_.UCS','_World','(setvar "OSMODE" 0)',
 'BHTHUONGBIEN','H=H','0,0','10,0','A',
 '(bht:symbol-sync-ex (quote ("HEAD-A" "HEAD-B")) nil)',
 '(heading-check "perpendicular-persists-on-refresh-and-H-alias" (and (= (bht:get (bht:obj-read "HEAD-A") "sign_heading_mode") "FIXED_PERP") (heading-same-angle (heading-angle "HEAD-A") 0.0)))',
 'BHTHUONGBIEN','H','10,0','0,0','A',
 '(heading-check "reverse-AB-flips-perpendicular-side" (heading-same-angle (heading-angle "HEAD-A") pi))',
 '(princ (strcat "\nHEADING-FINAL-FAIL=" (itoa heading-fails)))',
 '_.QUIT','_Y'
)
$scr=Join-Path $out 'heading.scr'
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'heading.log'
& "$AcadDir\accoreconsole.exe" /isolate BHTHeading (Join-Path $out 'heading-profile') /s $scr /l en-US > $log
$report=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
$report -split "`n" | Where-Object {$_ -match '^(PASS|FAIL) HEADING|^HEADING-(FINAL-)?FAIL='} | ForEach-Object {Write-Host $_}
if($report -notmatch 'HEADING-FINAL-FAIL=0' -or $report -match 'FAIL HEADING|; error:'){throw 'Bulk heading integration failed'}
