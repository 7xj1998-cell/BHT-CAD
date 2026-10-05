param(
  [Parameter(Mandatory=$true)][string]$Drawing,
  [Parameter(Mandatory=$true)][string]$ProfileDirectory,
  [string]$ProfileKey = 'BHTSignQA',
  [string]$AcadDir = 'D:\AutoCAD 2024',
  [string]$BinDir = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
if ($BinDir -eq '') { $BinDir = Join-Path $root 'build\bin' }
$stage = Join-Path $root ('build\qa0611-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -LiteralPath $Drawing -Destination (Join-Path $stage 'input.dwg')
$before = (Get-FileHash -LiteralPath $Drawing).Hash
Copy-Item -LiteralPath (Join-Path $root "src\lisp\BHT-$version.lsp") -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'src\lisp\modules') -Destination $stage -Recurse
Copy-Item -Path (Join-Path $PSScriptRoot 'test_SIGN061*.lsp') -Destination $stage
$bin = Join-Path $stage 'bin'; New-Item -ItemType Directory -Path $bin | Out-Null
Copy-Item -Path (Join-Path $BinDir 'BHT*.dll') -Destination $bin
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
& $csc /nologo /target:library "/out:$bin\Sign0611Probe.dll" "/r:$bin\BHT.Bridge.dll" "/r:$bin\BHT.Core.dll" "/r:$AcadDir\acdbmgd.dll" "/r:$AcadDir\accoremgd.dll" (Join-Path $PSScriptRoot 'Sign0611Probe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Probe compilation failed' }
& $csc /nologo /target:library /platform:x64 "/out:$bin\PaletteEditorProbe.dll" "/r:$bin\BHT.Core.dll" "/r:$bin\BHT.Palette.dll" "/r:$AcadDir\accoremgd.dll" /r:System.Windows.Forms.dll (Join-Path $PSScriptRoot 'PaletteEditorProbe.cs')
if ($LASTEXITCODE -ne 0) { throw 'Palette probe compilation failed' }
$scr = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sign0611-template.scr')).Replace('@STAGE@',$stage.Replace('\','/')).Replace('@BIN@','bin').Replace('@GALLERY@','gallery.dwg').Replace('@LOADER@',"BHT-$version.lsp")
[IO.File]::WriteAllText((Join-Path $stage 'run.scr'), $scr + "`n", [Text.UTF8Encoding]::new($true))
$oldOutput = $env:BHT_QA_OUTPUT; $oldPdf = $env:BHT_QA_PDF
try {
  $env:BHT_QA_OUTPUT = Join-Path $stage 'probe.txt'; $env:BHT_QA_PDF = Join-Path $stage 'gallery.pdf'
  # Reuse an explicitly supplied test profile. Do not change security settings.
  & "$AcadDir\accoreconsole.exe" /i "$stage\input.dwg" /s "$stage\run.scr" /isolate $ProfileKey $ProfileDirectory /p AutoCAD > "$stage\console.log"
} finally { $env:BHT_QA_OUTPUT = $oldOutput; $env:BHT_QA_PDF = $oldPdf }
$log = [IO.File]::ReadAllText("$stage\console.log").Replace([string][char]0,'')
if ($before -ne (Get-FileHash -LiteralPath $Drawing).Hash) { throw 'Source drawing changed' }
if ($log -match '(?m)^FAIL |; error:|SIGN0610-FAIL=[1-9]' -or $log -notmatch 'SIGN0611-FINAL-FAIL=0') { throw 'CAD test failed; inspect console.log' }
$probe = Get-Content "$stage\probe.txt"
if ($probe -match '^FAIL' -or -not (Test-Path "$stage\gallery.pdf") -or -not (Test-Path "$stage\gallery.dwg")) { throw 'Native geometry/plot test failed' }
if (-not (Test-Path ("$stage\probe.txt-palette.txt")) -or (Get-Content "$stage\probe.txt-palette.txt" -Raw) -notmatch '^PASS ') { throw 'Palette editor probe failed' }
$probe; Write-Host "PASS AutoCAD QA: $stage"