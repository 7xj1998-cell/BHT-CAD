param([string]$AcadDir='D:\AutoCAD 2024',[string]$BinDir='')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version=(Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if($BinDir -eq '') { $BinDir=Join-Path $root "build\v$version\bin" }
$out=Join-Path $root "build\v$version"
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$probe=Join-Path $BinDir 'PickerNativeProbe.dll'
& $csc /nologo /target:library /platform:x64 /r:System.Windows.Forms.dll /r:System.Drawing.dll "/r:$AcadDir\accoremgd.dll" "/r:$AcadDir\acdbmgd.dll" "/r:$BinDir\BHT.Core.dll" "/r:$BinDir\BHT.Bridge.dll" "/r:$BinDir\BHT.Palette.dll" "/out:$probe" (Join-Path $PSScriptRoot 'PickerProbe.cs')
if($LASTEXITCODE -ne 0) { throw 'Native picker compile failed' }
$result=Join-Path $BinDir 'picker-probe.txt'
if(Test-Path -LiteralPath $result) { Remove-Item -LiteralPath $result }
$lines=@('(setvar "SECURELOAD" 0)','(setvar "LISPSYS" 1)','_.NETLOAD',('"'+"$BinDir\BHT.Bridge.dll".Replace('\','/')+'"'),('(setq *bht-no-launch* T *bht-module-root* "'+"$root\src\lisp".Replace('\','/')+'")'),('(load "'+"$root\src\lisp\BHT-$version.lsp".Replace('\','/')+'")'),'_.NETLOAD',('"'+"$BinDir\BHT.Palette.dll".Replace('\','/')+'"'),'_.NETLOAD',('"'+$probe.Replace('\','/')+'"'),'BHTPICKERPROBE','_.QUIT','_Y')
$scr=Join-Path $out 'picker-native.scr';[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTNativePicker (Join-Path $out 'picker-native-profile') /s $scr /l en-US > (Join-Path $out 'picker-native-console.log')
if(-not(Test-Path -LiteralPath $result)) { throw 'Native picker did not complete' }
$report=[IO.File]::ReadAllText($result);Write-Host $report
if($report -notmatch '^PASS') { throw 'Native picker regression failed' }
