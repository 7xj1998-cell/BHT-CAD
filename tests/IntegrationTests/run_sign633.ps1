param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot);$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($BinDir -eq ''){$BinDir=Join-Path $root "build\v$version\bin"};$out=Join-Path $root "build\v$version"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe';$probe=Join-Path $BinDir 'Sign633Probe.dll'
& $csc /nologo /target:library /platform:x64 "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Bridge.dll" "/out:$probe" (Join-Path $PSScriptRoot 'Sign633Probe.cs')
if($LASTEXITCODE -ne 0){throw 'Sign633 compile failed'}
$result=Join-Path $BinDir 'print-probe.txt';foreach($name in @('print-probe.txt','print-live.txt','print-progress.txt')){$old=Join-Path $BinDir $name;if(Test-Path -LiteralPath $old){Remove-Item -LiteralPath $old}}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+"$BinDir\BHT.Bridge.dll".Replace('\','/')+'"'),'_.NETLOAD',('"'+$probe.Replace('\','/')+'"'),'BHTSIGN633PROBE','_.QUIT','_Y')
$scr=Join-Path $out 'sign633.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTSign633 (Join-Path $out 'sign633-profile') /s $scr /l en-US > (Join-Path $out 'sign633-console.log')
if(-not(Test-Path -LiteralPath $result)){throw 'Sign633 probe did not complete'}
$report=[IO.File]::ReadAllText($result);if($report -match '(?m)^FAIL'){Write-Host ($report -split "`n" | Where-Object {$_ -match '^FAIL'});throw 'Sign633 regression failed'}
Write-Host ('PASS all-library print audit: '+(@($report -split "`n"|Where-Object {$_ -match '^PASS'}).Count)+' checks')
