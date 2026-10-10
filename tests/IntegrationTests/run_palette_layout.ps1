param([string]$AcadDir = 'D:\AutoCAD 2024', [string]$BinDir = '',[string]$RuntimePath='')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$out = Join-Path $root "build\v$version"
if ($BinDir -eq '') { $BinDir = Join-Path $out 'bin' }
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$probe = Join-Path $BinDir 'PaletteLayoutProbe.dll'
& $csc /nologo /target:library /platform:x64 /r:System.Windows.Forms.dll /r:System.Drawing.dll "/r:$BinDir\BHT.Palette.dll" "/r:$BinDir\BHT.Bridge.dll" "/r:$BinDir\BHT.Core.dll" "/r:$AcadDir\acmgd.dll" "/r:$AcadDir\accoremgd.dll" "/r:$AcadDir\acdbmgd.dll" "/out:$probe" (Join-Path $PSScriptRoot 'PaletteLayoutProbe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Palette probe compile failed' }
$result = Join-Path $BinDir 'ui-preview\result.txt'
if (Test-Path -LiteralPath $result) { Remove-Item -LiteralPath $result }
$lines = @('(setvar "SECURELOAD" 0)', '(setvar "LISPSYS" 1)', '_.NETLOAD', ('"' + "$BinDir\BHT.Bridge.dll".Replace('\','/') + '"'), ('(setq *bht-no-launch* T *bht-module-root* "' + "$root\src\lisp".Replace('\','/') + '")'), ('(load "' + "$root\src\lisp\BHT-$version.lsp".Replace('\','/') + '")'), '_.NETLOAD', ('"' + "$BinDir\BHT.Palette.dll".Replace('\','/') + '"'), '_.NETLOAD', ('"' + $probe.Replace('\','/') + '"'), 'BHTPALETTELAYOUTPROBE', '_.QUIT', '_Y')
if($RuntimePath){$lines=@($lines | ForEach-Object {$_.Replace(("$root\src\lisp\BHT-$version.lsp").Replace('\','/'),$RuntimePath.Replace('\','/'))})}
$scr = Join-Path $out 'ui-test.scr'
[IO.File]::WriteAllLines($scr, $lines, [Text.UTF8Encoding]::new($true))
& "$AcadDir\accoreconsole.exe" /isolate BHTUILayout (Join-Path $out 'ui-profile') /s $scr /l en-US > (Join-Path $out 'ui-console.log')
if (-not (Test-Path -LiteralPath $result)) { throw 'Palette probe did not complete' }
$report = [IO.File]::ReadAllText($result)
Write-Host $report
if ($report -notmatch '^PASS') { throw 'Palette layout regression failed' }
