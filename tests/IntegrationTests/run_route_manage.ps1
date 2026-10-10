param([string]$BinDir)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim();$out=Join-Path $root "build/v$version"
function LP($p){$p.Replace('\','/')}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$BinDir\BHT.Bridge.dll")+'"'),('(setq *bht-no-launch* T *bht-module-root* "'+(LP "$root\src\lisp")+'")'),('(load "'+(LP "$root\src\lisp\BHT-$version.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_HEADING.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_ROUTE_MANAGE.lsp")+'")'),'(if (/= 0 (logand 8 (getvar "UNDOCTL"))) (command-s "_.UNDO" "_End"))','(setq manage-before (bht:route-read "REPLACE") *bht-route-selected* "REPLACE")','BHTXOATUYEN','K','(manage-check "cancel-delete-no-mutation" (equal manage-before (bht:route-read "REPLACE")))','(setq *bht-route-selected* "REPLACE")','BHTXOATUYEN','C','(manage-check "interactive-delete" (null (bht:route-read "REPLACE")))','_.UNDO','1','(manage-check "undo-restores-route" (equal manage-before (bht:route-read "REPLACE")))','(setq *bht-route-selected* "REPLACE")','BHTSUATUYEN','EDITED','TIM_RANH','120','10','(manage-check "interactive-edit" (and (null (bht:route-read "REPLACE")) (= (bht:get (bht:route-read "EDITED") "loai") "TIM_RANH")))','_.UNDO','1','(manage-check "undo-restores-edit" (and (null (bht:route-read "EDITED")) (equal manage-before (bht:route-read "REPLACE"))))','(princ (strcat "\nMANAGE-FINAL-FAIL=" (itoa manage-fails)))','_.QUIT','_Y')
$scr=Join-Path $out 'route-manage.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'route-manage.log'
& 'D:\AutoCAD 2024\accoreconsole.exe' /isolate BHTRouteManage (Join-Path $out 'route-manage-profile') /s $scr /l en-US > $log
$s=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
$s -split "`n" | Where-Object {$_ -match '^(PASS|FAIL) MANAGE|^MANAGE-'} | ForEach-Object {Write-Host $_}
if($s -notmatch 'MANAGE-FINAL-FAIL=0' -or $s -match '(?m)^FAIL MANAGE|; error:'){throw 'Route maintenance failed'}
