param([string]$BinDir)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim();$out=Join-Path $root "build/v$version"
function LP($p){$p.Replace('\','/')}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$BinDir\BHT.Bridge.dll")+'"'),('(setq *bht-no-launch* T *bht-module-root* "'+(LP "$root\src\lisp")+'")'),('(load "'+(LP "$root\src\lisp\BHT-$version.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_HEADING.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_CHAINAGE639.lsp")+'")'),'BHTKM2COC','0,0','Km45+000','100,0','Km46+000','25,10','_.QUIT','_Y')
$scr=Join-Path $out 'chainage639.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'chainage639.log'
& 'D:\AutoCAD 2024\accoreconsole.exe' /isolate BHTChainage639 (Join-Path $out 'chainage639-profile') /s $scr /l en-US > $log
$s=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
$s -split "`n" | Where-Object {$_ -match '^(PASS|FAIL) KM|^KM-|ƯỚC TÍNH'} | ForEach-Object {Write-Host $_}
if($s -notmatch 'KM-FAIL=0' -or $s -match '(?m)^FAIL KM|; error:'){throw 'Route maintenance failed'}
