param([string]$BinDir)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim();$out=Join-Path $root "build/v$version"
function LP($p){$p.Replace('\','/')}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$BinDir\BHT.Bridge.dll")+'"'),('(setq *bht-no-launch* T *bht-module-root* "'+(LP "$root\src\lisp")+'")'),('(load "'+(LP "$root\src\lisp\BHT-$version.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_HEADING.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_JOINT641.lsp")+'")'),'_.QUIT','_Y')
$scr=Join-Path $out 'joint641.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'joint641.log'
& 'D:\AutoCAD 2024\accoreconsole.exe' /isolate BHTJoint641 (Join-Path $out 'joint641-profile') /s $scr /l en-US > $log
$s=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
$s -split "`n" | Where-Object {$_ -match '^(PASS|FAIL) JOINT|^JOINT-'} | ForEach-Object {Write-Host $_}
if($s -notmatch 'JOINT-FAIL=0' -or $s -match '(?m)^FAIL JOINT|; error:'){throw 'Route maintenance failed'}
