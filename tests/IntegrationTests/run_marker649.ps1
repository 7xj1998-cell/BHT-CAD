param([string]$BinDir,[string]$RuntimePath="")
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim();$out=Join-Path $root "build/v$version"
function LP($p){$p.Replace('\','/')}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$BinDir\BHT.Bridge.dll")+'"'),('(setq *bht-no-launch* T *bht-module-root* "'+(LP "$root\src\lisp")+'")'),('(load "'+(LP "$root\src\lisp\BHT-$version.lsp")+'")'),('(load "'+(LP "$PSScriptRoot\test_MARKER649.lsp")+'")'),'_.QUIT','_Y')
if($RuntimePath){$lines=@($lines | ForEach-Object {$_.Replace(("$root\src\lisp\BHT-$version.lsp").Replace('\','/'),$RuntimePath.Replace('\','/'))})}
$scr=Join-Path $out 'marker649.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'marker649.log'
& 'D:\AutoCAD 2024\accoreconsole.exe' /isolate BHTMarker649 (Join-Path $out 'marker649-profile') /s $scr /l en-US > $log
$s=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
$s -split "`n" | Where-Object {$_ -match '^(PASS|FAIL) M649|^M649-'} | ForEach-Object {Write-Host $_}
if($s -notmatch 'M649-FAIL=0' -or $s -match '(?m)^FAIL M649|; error:'){throw 'Route maintenance failed'}
