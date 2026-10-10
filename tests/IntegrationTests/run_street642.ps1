param([string]$BinDir,[string]$AcadDir='D:\AutoCAD 2024')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$out=Join-Path $root 'build\v0.6.42'
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$probe=Join-Path $BinDir 'Street642Probe.dll'
& $csc /nologo /target:library /platform:x64 "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Bridge.dll" "/out:$probe" (Join-Path $PSScriptRoot 'Street642Probe.cs')
if($LASTEXITCODE -ne 0){throw 'Street probe compile failed'}
$report=Join-Path $BinDir 'street642-report.txt'
if(Test-Path -LiteralPath $report){Remove-Item -LiteralPath $report}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+("$BinDir\BHT.Bridge.dll").Replace('\','/')+'"'),'_.NETLOAD',('"'+$probe.Replace('\','/')+'"'),'STREET642PROBE','_.QUIT','_Y')
$scr=Join-Path $out 'street642.scr'
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTStreet642 (Join-Path $out 'street642-profile') /s $scr /l en-US > (Join-Path $out 'street642.log')
if(!(Test-Path -LiteralPath $report)){throw 'Street probe report missing'}
$s=Get-Content -LiteralPath $report -Raw
Write-Output $s
if($s -match 'FAIL' -or ([regex]::Matches($s,'(?m)^PASS ')).Count -lt 13){throw 'Street probe failed'}
