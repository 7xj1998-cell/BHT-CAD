param([string]$BinDir,[string]$Drawing)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
$out=Join-Path $root "build/v$version"
$acad='D:\AutoCAD 2024'
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:library /platform:x64 /r:System.Windows.Forms.dll /r:System.Drawing.dll "/r:$acad\acdbmgd.dll" "/r:$acad\accoremgd.dll" "/r:$acad\acmgd.dll" "/r:$BinDir\BHT.Bridge.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Palette.dll" "/out:$BinDir\RouteDataProbe.dll" (Join-Path $PSScriptRoot 'RouteDataProbe.cs')
if($LASTEXITCODE -ne 0){throw 'Compile route probe failed'}
$scr=Join-Path $out 'route-data.scr'
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+"$BinDir\BHT.Bridge.dll".Replace('\','/')+'"'),'_.NETLOAD',('"'+"$BinDir\BHT.Palette.dll".Replace('\','/')+'"'),'_.NETLOAD',('"'+"$BinDir\RouteDataProbe.dll".Replace('\','/')+'"'),'BHTROUTEDATAPROBE','_.QUIT','_Y')
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$acad\accoreconsole.exe" /isolate BHTRouteData (Join-Path $out 'route-data-profile') /i $Drawing /s $scr /l en-US > (Join-Path $out 'route-data.log')
$report=Get-Content -LiteralPath (Join-Path $BinDir 'route-data-probe.txt')
$report | ForEach-Object {Write-Host $_}
if($report -match '^FAIL' -or @($report | Where-Object {$_ -like 'PASS*'}).Count -lt 7){throw 'Route data test failed'}
