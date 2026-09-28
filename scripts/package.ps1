param(
  [string]$AcadDir = 'D:\AutoCAD 2024',
  [string]$OutRoot = '',
  [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ($version -ne '0.4.5') { throw "VERSION phải là 0.4.5, đang là $version" }

if (-not $SkipBuild) {
  & (Join-Path $PSScriptRoot 'build.ps1') -AcadDir $AcadDir -UseCsc -Test
  if ($LASTEXITCODE -ne 0) { throw "Build/test thất bại: $LASTEXITCODE" }
}

if ($OutRoot -eq '') { $OutRoot = Join-Path $root 'build\release' }
$safeRoot = [IO.Path]::GetFullPath((Join-Path $root 'build')).TrimEnd('\') + '\'
$resolvedOut = [IO.Path]::GetFullPath($OutRoot)
if (-not $resolvedOut.StartsWith($safeRoot, [StringComparison]::OrdinalIgnoreCase)) {
  throw "OutRoot phải nằm trong thư mục build: $resolvedOut"
}

$name = 'BHT-' + $version
$stage = Join-Path $resolvedOut $name
$zip = Join-Path $resolvedOut ($name + '.zip')
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$bin = Join-Path $root 'build\bin'
$lisp = Join-Path $root ('src\lisp\BHT-' + $version + '.lsp')
Copy-Item -LiteralPath $lisp -Destination $stage
Copy-Item -LiteralPath (Join-Path $bin 'BHT.Core.dll'),(Join-Path $bin 'BHT.Bridge.dll'),(Join-Path $bin 'BHT.Palette.dll') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'README.md'),(Join-Path $root 'CHANGELOG.md') -Destination $stage
Copy-Item -LiteralPath (Join-Path $root 'docs') -Destination $stage -Recurse
Copy-Item -LiteralPath (Join-Path $root 'packaging\INSTALL_BHT.ps1'),(Join-Path $root 'packaging\INSTALL_BHT.cmd'),(Join-Path $root 'packaging\README_INSTALL.md') -Destination $stage

$toolStage = Join-Path $stage 'scripts'
New-Item -ItemType Directory -Force -Path $toolStage | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'scripts\audit_tdt_library.ps1') -Destination $toolStage

# Ban giao kem ma nguon co the build lai, khong kem .git, build, DLL Autodesk hay du lieu khao sat.
$sourceStage = Join-Path $stage 'source\BHT-CAD'
New-Item -ItemType Directory -Force -Path $sourceStage | Out-Null
Copy-Item -LiteralPath (Join-Path $root '.gitignore'),(Join-Path $root 'BHT.sln'),(Join-Path $root 'VERSION'),(Join-Path $root 'README.md'),(Join-Path $root 'CHANGELOG.md') -Destination $sourceStage
foreach ($sourceDir in @('.github','docs','packaging','scripts','src','tests')) {
  Copy-Item -LiteralPath (Join-Path $root $sourceDir) -Destination $sourceStage -Recurse
}

$bundle = Join-Path $stage 'BHT.bundle'
$bundleContents = Join-Path $bundle 'Contents\Windows'
New-Item -ItemType Directory -Force -Path $bundleContents | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'packaging\BHT.bundle\PackageContents.xml') -Destination $bundle
Copy-Item -LiteralPath $lisp,(Join-Path $bin 'BHT.Core.dll'),(Join-Path $bin 'BHT.Bridge.dll'),(Join-Path $bin 'BHT.Palette.dll') -Destination $bundleContents

# Khong dua ban ve/du lieu/anh khao sat hoac gallery DWG vao goi phat hanh,
# ke ca khi tep nam trong thu muc tai lieu hay source ban giao.
$forbiddenExtensions = @('.dwg','.dwl','.dwl2','.bak','.sv$','.kmz','.csv','.tsv','.ntd','.jpg','.jpeg')
Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object {
  $forbiddenExtensions -contains $_.Extension.ToLowerInvariant()
} | Remove-Item -Force

$hashFile = Join-Path $stage 'SHA256SUMS.txt'
$hashTargets = Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object { $_.FullName -ne $hashFile }
$basePath = $stage.TrimEnd('\') + '\'
$hashLines = foreach ($f in $hashTargets) {
  $relative = $f.FullName.Substring($basePath.Length).Replace('\', '/')
  '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash, $relative
}
$hashLines | Set-Content -LiteralPath $hashFile -Encoding UTF8
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal

Get-Item -LiteralPath $stage,$zip | Select-Object FullName,Length,LastWriteTime
