param([string]$AcadDir='D:\AutoCAD 2024',[Parameter(Mandatory=$true)][string]$OutDir)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$version=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
$out=[IO.Path]::GetFullPath($OutDir)
if(!$out.StartsWith([IO.Path]::GetFullPath((Join-Path $root 'build'))+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Compile output must be inside build'}
New-Item -ItemType Directory -Force $out | Out-Null
$source=Join-Path $out 'runtime-private.lsp'
$files=Get-ChildItem (Join-Path $root 'src\lisp\modules') -Filter '*.lsp' | Sort-Object Name
if($files.Count -ne 12){throw 'Expected exactly twelve Lisp modules'}
$text=($files | ForEach-Object {[IO.File]::ReadAllText($_.FullName)}) -join [Environment]::NewLine
[IO.File]::WriteAllText($source,$text,[Text.UTF8Encoding]::new($true))
$fas=Join-Path $out "BHT-$version.fas"
if(Test-Path -LiteralPath $fas){Remove-Item -LiteralPath $fas}
$lines=@('(vl-load-com)','(if (/= (getvar "LISPSYS") 1) (progn (princ "\nCOMPILE-FAIL-LISPSYS") (exit)))',
 ('(setq result (vl-catch-all-apply ''vlisp-compile (list ''st "'+$source.Replace('\','/')+'" "'+$fas.Replace('\','/')+'")))'),
 '(princ (if (eq result T) "\nCOMPILE-PASS" "\nCOMPILE-FAIL"))','_.QUIT','_Y')
$scr=Join-Path $out 'compile.scr';$log=Join-Path $out 'compile.log'
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTProtectedCompile (Join-Path $out 'profile') /s $scr /l en-US > $log
$result=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
if(!(Test-Path -LiteralPath $fas) -or (Get-Item $fas).Length -lt 1000 -or $result -notmatch '(?m)^COMPILE-PASS' -or $result -match '(?m)^COMPILE-FAIL'){throw 'Lisp compilation failed; see compile.log'}
Write-Host "Compiled $fas"
