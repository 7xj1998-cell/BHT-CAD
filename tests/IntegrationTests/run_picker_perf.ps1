param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='', [switch]$Baseline)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$out=Join-Path $root "build\v$version\perf"
if($BinDir -eq ''){$BinDir=Join-Path $root "build\v$version\bin-final"}
New-Item -ItemType Directory -Force -Path $out | Out-Null
$probe=Join-Path $BinDir 'PickerPerfProbe.dll'
$source=Join-Path $PSScriptRoot 'PickerPerfProbe.cs'
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:library /platform:x64 /r:System.Windows.Forms.dll /r:System.Drawing.dll "/r:$AcadDir\accoremgd.dll" "/r:$BinDir\BHT.Palette.dll" "/out:$probe" $source
if($LASTEXITCODE -ne 0){throw 'Compile failed'}
$env:BHT_PICKER_PERF_FOLDER=$out
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+("$BinDir\BHT.Bridge.dll").Replace('\','/')+'"'),'_.NETLOAD',('"'+("$BinDir\BHT.Palette.dll").Replace('\','/')+'"'),'_.NETLOAD',('"'+$probe.Replace('\','/')+'"'),'BHTPICKERPERF','_.QUIT','_Y')
$scr=Join-Path $out 'perf.scr'
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTPickerPerf $out /s $scr /l en-US > (Join-Path $out 'console.log')
$report=Get-Content -LiteralPath (Join-Path $out 'picker-perf.txt')
$report | ForEach-Object {Write-Host $_}
if(@($report | Where-Object {$_ -match '^open='}).Count -ne 3){throw 'Performance probe did not finish'}
if(-not $Baseline){foreach($line in $report){if($line -match 'images=(\d+) pixel_bytes=(\d+)' -and ([int]$Matches[1] -gt 61 -or [long]$Matches[2] -gt 15000000)){throw 'Picker image allocation exceeded bounds'}}}

if($report -match "^FAIL"){throw "Picker lifecycle failed"}
