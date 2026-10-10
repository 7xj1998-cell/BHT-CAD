param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($BinDir -eq '') { $BinDir=Join-Path $root "build\v$version\bin" }
$out=Join-Path $root "build\v$version"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$probe=Join-Path $BinDir 'Cap1Probe.dll'
& $csc /nologo /target:library /platform:x64 "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Bridge.dll" "/out:$probe" (Join-Path $PSScriptRoot 'Cap1Probe.cs')
if($LASTEXITCODE -ne 0) { throw 'CAP1 probe compile failed' }
$result=Join-Path $BinDir 'cap1-probe.txt'
if(Test-Path -LiteralPath $result) { Remove-Item -LiteralPath $result }
$lines=@('(setvar "SECURELOAD" 0)','(setvar "LISPSYS" 1)','_.NETLOAD',('"'+"$BinDir\BHT.Bridge.dll".Replace('\','/')+'"'),('(setq *bht-no-launch* T *bht-module-root* "'+"$root\src\lisp".Replace('\','/')+'")'),('(load "'+"$root\src\lisp\BHT-$version.lsp".Replace('\','/')+'")'),'_.NETLOAD',('"'+$probe.Replace('\','/')+'"'),'BHTCAP1PROBE',
 '(setq cap1-rec (bht:obj-read "CAP1-QA"))',
 '(setq cap1-block (bht:kh-base-block cap1-rec))',
 '(if (and (= (bht:get cap1-rec "sign_layout") "CAP1_9") (> (strlen (bht:get cap1-rec "sign_content")) 100) (wcmatch cap1-block "BHT_SIGN_LAYOUT_V0641_*") (= (length (BHTSIGNFEET cap1-block)) 6)) (princ "\nCAP1-LISP-PASS") (princ "\nCAP1-LISP-FAIL"))',
 ('(load "'+(Join-Path $PSScriptRoot 'test_CAP1.lsp').Replace('\','/')+'")'),
 '_.QUIT','_Y')
$scr=Join-Path $out 'cap1.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$log=Join-Path $out 'cap1-console.log'
& "$AcadDir\accoreconsole.exe" /isolate BHTCap1 (Join-Path $out 'cap1-profile') /s $scr /l en-US > $log
if(-not(Test-Path -LiteralPath $result)) { throw 'CAP1 probe did not complete' }
$report=[IO.File]::ReadAllText($result);$console=[IO.File]::ReadAllText($log).Replace([string][char]0,'')
if($report -match '(?m)^FAIL' -or $console -notmatch 'CAP1-LISP-PASS' -or $console -notmatch '(?m)^CAP1-RTK-FAIL=0' -or $console -match '(?m)^FAIL CAP1|; error:' -or $console -match '\nCAP1-LISP-FAIL') { Write-Host $report;throw 'CAP1 regression failed' }
Write-Host ('PASS CAP1: '+(@($report -split "`n" | Where-Object {$_ -match '^PASS'}).Count)+' CAD checks and Lisp persistence/layout/feet API')
