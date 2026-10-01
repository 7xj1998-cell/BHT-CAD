param(
  [string]$AcadDir = 'D:\AutoCAD 2024',
  [string]$OutRoot = '',
  [string]$BinDir = '',
  [switch]$SkipBuild
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ($BinDir -eq '') { $BinDir = Join-Path $root 'build\bin' }
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION phải theo dạng major.minor.patch: $version" }
& (Join-Path $PSScriptRoot 'check-version.ps1')

# A released version is immutable when source or documentation changes.
$releaseStatePath = Join-Path $root 'RELEASE_STATE.json'
$trackedFiles = @()
foreach ($directory in @('src','scripts','packaging','tests','docs')) {
  $trackedFiles += Get-ChildItem -LiteralPath (Join-Path $root $directory) -File -Recurse | Where-Object { $_.FullName -notmatch '\\(obj|bin)\\' -and $_.Extension.ToLowerInvariant() -notin @('.dwg','.dwl','.dwl2','.bak','.sv$','.kmz','.csv','.tsv','.ntd','.jpg','.jpeg') }
}
foreach ($name in @('VERSION','README.md','CHANGELOG.md','AGENTS.md')) { $trackedFiles += Get-Item -LiteralPath (Join-Path $root $name) }
$hashInput = ($trackedFiles | Sort-Object FullName | ForEach-Object { $_.FullName.Substring($root.Length) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }) -join "`n"
$hashAlgorithm = [Security.Cryptography.SHA256]::Create()
try { $contentHash = [BitConverter]::ToString($hashAlgorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($hashInput))).Replace('-', '') }
finally { $hashAlgorithm.Dispose() }
if (Test-Path -LiteralPath $releaseStatePath) {
  $lastRelease = Get-Content -LiteralPath $releaseStatePath -Raw | ConvertFrom-Json
  if ($lastRelease.version -eq $version -and $lastRelease.contentHash -ne $contentHash) { throw "Nội dung đã đổi. Phải tăng phiên bản sau $version trước khi phát hành." }
  if ($lastRelease.version -ne $version -and [version]$version -le [version]$lastRelease.version) { throw 'Phiên bản phát hành mới phải lớn hơn bản trước.' }
}

if (-not $SkipBuild) {
  & (Join-Path $PSScriptRoot 'build.ps1') -AcadDir $AcadDir -OutDir $BinDir -UseCsc -Test
  if ($LASTEXITCODE -ne 0) { throw "Build/test thất bại: $LASTEXITCODE" }
}

foreach ($assemblyName in @('BHT.Core.dll','BHT.Bridge.dll','BHT.Palette.dll')) {
  $assembly = Join-Path $BinDir $assemblyName
  if (-not (Test-Path -LiteralPath $assembly)) { throw "Thiếu DLL: $assemblyName" }
  if ([Diagnostics.FileVersionInfo]::GetVersionInfo($assembly).FileVersion -ne "$version.0") { throw "DLL $assemblyName chưa được build cho phiên bản $version" }
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

$bin = $BinDir
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
Copy-Item -LiteralPath (Join-Path $root '.gitignore'),(Join-Path $root 'BHT.sln'),(Join-Path $root 'VERSION'),(Join-Path $root 'README.md'),(Join-Path $root 'CHANGELOG.md'),(Join-Path $root 'AGENTS.md') -Destination $sourceStage
foreach ($sourceDir in @('.github','docs','packaging','scripts','src','tests')) {
  Copy-Item -LiteralPath (Join-Path $root $sourceDir) -Destination $sourceStage -Recurse
}

$bundle = Join-Path $stage 'BHT.bundle'
$bundleContents = Join-Path $bundle 'Contents\Windows'
New-Item -ItemType Directory -Force -Path $bundleContents | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'packaging\BHT.bundle\PackageContents.xml') -Destination $bundle
Copy-Item -LiteralPath $lisp,(Join-Path $bin 'BHT.Core.dll'),(Join-Path $bin 'BHT.Bridge.dll'),(Join-Path $bin 'BHT.Palette.dll') -Destination $bundleContents

# 5.0: phong chu cho block bien TDT va nhan ky hieu. Ban sao CUC BO (chi dung tren may nguoi dung),
# KHONG dua vao git (.gitignore: fonts_local/, *.ttf, *.shx). Nguon: fonts_local\ canh repo, neu
# khong co thi chep tu thu muc cai TDT (CHI DOC). Thieu phong -> canh bao, van dong goi.
$fontNames = @('giaothong1.ttf','giaothong2.ttf','VNRomancUpdate.shx','vnromanc.shx')
$fontSources = @((Join-Path $root 'fonts_local'), 'C:\Program Files (x86)\TDT Solution 2022', (Join-Path $AcadDir 'Fonts'))
$bundleFonts = Join-Path $bundle 'Contents\Fonts'
New-Item -ItemType Directory -Force -Path $bundleFonts | Out-Null
foreach ($fn in $fontNames) {
  $src = $null
  foreach ($d in $fontSources) { $p = Join-Path $d $fn; if (Test-Path -LiteralPath $p) { $src = $p; break } }
  if ($src) { Copy-Item -LiteralPath $src -Destination (Join-Path $bundleFonts $fn) -Force; Write-Host "Phông: $fn <- $src" }
  else { if ($fn -eq 'VNRomancUpdate.shx') { throw 'Thiếu VNRomancUpdate.shx: không phát hành bản thiếu phông mặc định.' }; Write-Warning "Không tìm thấy phông $fn (fonts_local / TDT / AutoCAD Fonts) - bundle thiếu phông này." }
}

# Khong dua ban ve/du lieu/anh khao sat hoac gallery DWG vao goi phat hanh,
# ke ca khi tep nam trong thu muc tai lieu hay source ban giao.
$forbiddenExtensions = @('.dwg','.dwl','.dwl2','.bak','.sv$','.kmz','.csv','.tsv','.ntd','.jpg','.jpeg')
Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object {
  $forbiddenExtensions -contains $_.Extension.ToLowerInvariant()
} | Remove-Item -Force

@{ version = $version; contentHash = $contentHash; artifact = ('BHT-' + $version + '.zip') } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $sourceStage 'RELEASE_STATE.json') -Encoding UTF8

$hashFile = Join-Path $stage 'SHA256SUMS.txt'
$hashTargets = Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object { $_.FullName -ne $hashFile }
$basePath = $stage.TrimEnd('\') + '\'
$hashLines = foreach ($f in $hashTargets) {
  $relative = $f.FullName.Substring($basePath.Length).Replace('\', '/')
  '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash, $relative
}
$hashLines | Set-Content -LiteralPath $hashFile -Encoding UTF8
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal

@{ version = $version; contentHash = $contentHash; artifact = $zip } | ConvertTo-Json | Set-Content -LiteralPath $releaseStatePath -Encoding UTF8
Get-Item -LiteralPath $stage,$zip | Select-Object FullName,Length,LastWriteTime
