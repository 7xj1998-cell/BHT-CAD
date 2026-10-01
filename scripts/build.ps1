<#
.SYNOPSIS
  Build BHT .NET (BHT.Core, BHT.CoreTests, BHT.Bridge, BHT.Palette) - .NET Framework 4.8, x64.
.DESCRIPTION
  - Tim tham chieu AutoCAD theo -AcadDir, bien moi truong ACAD_INSTALL_DIR, mac dinh D:\AutoCAD 2024.
    KHONG chep DLL cua Autodesk vao ma nguon / thu muc build.
  - Neu co .NET SDK (dotnet --list-sdks) -> dotnet build (csproj SDK-style, LangVersion 5).
  - Neu khong co SDK (hoac -UseCsc) -> dung csc.exe cua .NET Framework 4.x
    (%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe, C# 5).
  - Khong co tham chieu AutoCAD -> chi build BHT.Core + BHT.CoreTests va BAO RO la bo qua plugin.
  - -Test: chay BHT.CoreTests.exe (ma thoat = so FAIL).
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Test
  powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -AcadDir "C:\Program Files\Autodesk\AutoCAD 2024" -UseCsc
#>
param(
  [string]$AcadDir = '',
  [string]$OutDir = '',
  [switch]$UseCsc,
  [switch]$CoreOnly,
  [switch]$Test
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'check-version.ps1')
if ($AcadDir -eq '') { if ($env:ACAD_INSTALL_DIR) { $AcadDir = $env:ACAD_INSTALL_DIR } else { $AcadDir = 'D:\AutoCAD 2024' } }
if ($OutDir -eq '') { $OutDir = Join-Path $root 'build\bin' }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$expectedOutputs = @('BHT.Core.dll', 'BHT.CoreTests.exe', 'BHT.Bridge.dll', 'BHT.Palette.dll')
foreach ($name in $expectedOutputs) {
  $oldOutput = Join-Path $OutDir $name
  if (Test-Path -LiteralPath $oldOutput) { Remove-Item -LiteralPath $oldOutput -Force }
}
$logFile = Join-Path (Split-Path -Parent $OutDir) 'build_log.txt'
$script:log = New-Object System.Collections.Generic.List[string]
function Log([string]$s) { $script:log.Add($s); Write-Host $s }

Log ("BHT build " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + " | root=" + $root)
Log ("AcadDir=" + $AcadDir)
$refs = @{ acdbmgd = Join-Path $AcadDir 'acdbmgd.dll'; accoremgd = Join-Path $AcadDir 'accoremgd.dll'; acmgd = Join-Path $AcadDir 'acmgd.dll' }
$haveBridgeRefs = (Test-Path -LiteralPath $refs.acdbmgd) -and (Test-Path -LiteralPath $refs.accoremgd)
$havePaletteRefs = $haveBridgeRefs -and (Test-Path -LiteralPath $refs.acmgd)
foreach ($k in $refs.Keys) { Log ("  " + $k + ": " + $(if (Test-Path -LiteralPath $refs[$k]) { 'CO' } else { 'KHONG CO' })) }

$sdk = $false
if (-not $UseCsc -and (Get-Command dotnet -ErrorAction SilentlyContinue)) {
  $s = (& dotnet --list-sdks 2>$null) | Out-String
  if ($s.Trim() -ne '') { $sdk = $true; Log ("dotnet SDK: " + $s.Trim()) } else { Log "dotnet co mat nhung KHONG co SDK -> dung csc.exe" }
}

$failed = $false
function Run-Tool([string]$exe, [string[]]$argv, [string]$label) {
  Log ("--- " + $label)
  if ([IO.Path]::GetFileName($exe) -eq 'csc.exe') {
    $responseFile = Join-Path $OutDir 'compile.rsp'
    [IO.File]::WriteAllLines($responseFile, @($argv | Where-Object { $_ -ne '/noconfig' } | ForEach-Object { '"' + $_ + '"' }), [Text.UTF8Encoding]::new($true))
    $argv = @('/noconfig', ('@' + $responseFile))
  }
  $out = & $exe @argv 2>&1 | ForEach-Object { $_.ToString() }
  $code = $LASTEXITCODE
  foreach ($l in $out) { Log ("    " + $l) }
  Log ("    => exit " + $code)
  return $code
}

if ($sdk) {
  $p = @('build', (Join-Path $root 'tests\CoreTests\BHT.CoreTests.csproj'), '-c', 'Release', '-p:Platform=x64', ('-p:OutDir=' + $OutDir + '\'))
  if ((Run-Tool 'dotnet' $p 'dotnet build BHT.Core + BHT.CoreTests') -ne 0) { $failed = $true }
  if (-not $CoreOnly -and $havePaletteRefs) {
    $p = @('build', (Join-Path $root 'src\dotnet\BHT.Palette\BHT.Palette.csproj'), '-c', 'Release', '-p:Platform=x64', ('-p:AcadDir=' + $AcadDir), ('-p:OutDir=' + $OutDir + '\'))
    if ((Run-Tool 'dotnet' $p 'dotnet build BHT.Bridge + BHT.Palette') -ne 0) { $failed = $true }
  }
} else {
  $fw = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319'
  $csc = Join-Path $fw 'csc.exe'
  if (-not (Test-Path -LiteralPath $csc)) { Log "KHONG tim thay csc.exe cua .NET Framework va khong co .NET SDK -> khong build duoc."; exit 2 }
  Log ("csc: " + $csc)
  $common = @('/nologo', '/noconfig', '/platform:x64', '/optimize+', '/debug:pdbonly', '/warn:4', '/langversion:5', '/utf8output',
              ('/r:' + (Join-Path $fw 'System.dll')), ('/r:' + (Join-Path $fw 'System.Core.dll')),
              ('/r:' + (Join-Path $fw 'System.Xml.dll')), ('/r:' + (Join-Path $fw 'System.Xml.Linq.dll')),
              ('/r:' + (Join-Path $fw 'System.IO.Compression.dll')))
  function Src([string]$dir) { Get-ChildItem -LiteralPath $dir -Recurse -Filter *.cs | Where-Object { $_.FullName -notmatch '\\(obj|bin)\\' } | ForEach-Object { $_.FullName } }
  $core = Join-Path $OutDir 'BHT.Core.dll'
  $a = $common + @('/target:library', ('/out:' + $core)) + (Src (Join-Path $root 'src\dotnet\BHT.Core'))
  if ((Run-Tool $csc $a 'csc BHT.Core') -ne 0) { $failed = $true }
  $t = Join-Path $OutDir 'BHT.CoreTests.exe'
  $a = $common + @('/target:exe', ('/out:' + $t), ('/r:' + $core)) + (Src (Join-Path $root 'tests\CoreTests'))
  if ((Run-Tool $csc $a 'csc BHT.CoreTests') -ne 0) { $failed = $true }
  if (-not $CoreOnly) {
    if ($haveBridgeRefs) {
      $br = Join-Path $OutDir 'BHT.Bridge.dll'
      $a = $common + @('/target:library', ('/out:' + $br), ('/r:' + $core), ('/r:' + $refs.acdbmgd), ('/r:' + $refs.accoremgd)) + (Src (Join-Path $root 'src\dotnet\BHT.Bridge'))
      $bridgeCode = Run-Tool $csc $a 'csc BHT.Bridge (AcDbMgd + AcCoreMgd)'
      if ($bridgeCode -ne 0) { $failed = $true }
      if ($havePaletteRefs -and $bridgeCode -eq 0) {
        $pl = Join-Path $OutDir 'BHT.Palette.dll'
        $a = $common + @('/target:library', ('/out:' + $pl), ('/r:' + $core), ('/r:' + $br), ('/r:' + $refs.acdbmgd), ('/r:' + $refs.accoremgd), ('/r:' + $refs.acmgd),
                         ('/r:' + (Join-Path $fw 'System.Windows.Forms.dll')), ('/r:' + (Join-Path $fw 'System.Drawing.dll')),
                         ('/r:' + (Join-Path $fw 'WPF\PresentationCore.dll')), ('/r:' + (Join-Path $fw 'WPF\PresentationFramework.dll')),
                         ('/r:' + (Join-Path $fw 'WPF\WindowsBase.dll')), ('/r:' + (Join-Path $fw 'System.Xaml.dll'))) + (Src (Join-Path $root 'src\dotnet\BHT.Palette'))
        $a += Get-ChildItem -LiteralPath (Join-Path $root 'assets\sign-previews') -Filter *.png | ForEach-Object { '/resource:' + $_.FullName + ',BHT.SignPreviews.' + $_.Name }
        if ((Run-Tool $csc $a 'csc BHT.Palette (+ AcMgd, WinForms)') -ne 0) { $failed = $true }
      } elseif (-not $havePaletteRefs) { Log "SKIP BHT.Palette: khong co acmgd.dll trong AcadDir." }
      else { Log "SKIP BHT.Palette: BHT.Bridge build that bai, khong dung DLL cu." }
    } else { Log "SKIP BHT.Bridge + BHT.Palette: khong co tham chieu AutoCAD (acdbmgd/accoremgd) trong AcadDir - KHONG phai build thanh cong plugin." }
  }
}

# Dam bao khong co DLL Autodesk trong thu muc build
Get-ChildItem -LiteralPath $OutDir -Filter 'ac*mgd.dll' -ErrorAction SilentlyContinue | ForEach-Object { Log ("XOA DLL Autodesk bi chep nham: " + $_.Name); Remove-Item -LiteralPath $_.FullName -Force }

Log "--- San pham:"
Get-ChildItem -LiteralPath $OutDir -File | Where-Object { $_.Extension -in '.dll', '.exe' } | ForEach-Object {
  $h = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
  $v = $_.VersionInfo.FileVersion
  Log ("    " + $_.Name + "  " + $_.Length + " byte  FileVersion=" + $v + "  SHA256=" + $h)
}

$testCode = 0
if ($Test -and -not $failed) {
  $t = Join-Path $OutDir 'BHT.CoreTests.exe'
  $testCode = Run-Tool $t @($OutDir) 'BHT.CoreTests'
}
$script:log | Set-Content -LiteralPath $logFile -Encoding UTF8
if ($failed) { Log "BUILD THAT BAI"; exit 1 }
if ($testCode -ne 0) { Log ("TEST THAT BAI: " + $testCode + " FAIL"); exit 3 }
Log "BUILD XONG"
exit 0
