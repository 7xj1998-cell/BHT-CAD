param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot);$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($BinDir -eq ''){$BinDir=Join-Path $root "build\v$version\bin"};$out=Join-Path $root "build\v$version"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe';$probe=Join-Path $BinDir 'SignParameter633Probe.dll'
& $csc /nologo /target:library /platform:x64 "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Bridge.dll" "/out:$probe" (Join-Path $PSScriptRoot 'SignParameter633Probe.cs')
if($LASTEXITCODE -ne 0){throw 'Parameter633 compile failed'}
$result=Join-Path $BinDir 'parameter-probe.txt';if(Test-Path -LiteralPath $result){Remove-Item -LiteralPath $result}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+"$BinDir\BHT.Bridge.dll".Replace('\','/')+'"'),'_.NETLOAD',('"'+$probe.Replace('\','/')+'"'),'BHTPARAM633PROBE','_.QUIT','_Y')
$scr=Join-Path $out 'parameter633.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTParameter633 (Join-Path $out 'parameter633-profile') /s $scr /l en-US > (Join-Path $out 'parameter633-console.log')
if(-not(Test-Path -LiteralPath $result)){throw 'Parameter633 probe did not complete'}
$report=[IO.File]::ReadAllText($result);if($report -match '(?m)^FAIL'){Write-Host ($report -split "`n" | Where-Object {$_ -match '^FAIL'});throw 'Parameter633 regression failed'}
Write-Host ('PASS all-library parameter audit: '+(@($report -split "`n"|Where-Object {$_ -match '^PASS'}).Count)+' checks')
