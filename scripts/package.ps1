param(
  [string]$AcadDir = 'D:\AutoCAD 2024',
  [string]$OutRoot = '',
  [string]$BinDir = '',
  [switch]$SkipBuild,
  [switch]$IncludeSource,
  [switch]$ProtectedRuntime,
  [string]$CompiledLisp = ''
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
foreach ($directory in @('src','scripts','packaging','tests','docs','assets')) {
  $trackedFiles += Get-ChildItem -LiteralPath (Join-Path $root $directory) -File -Recurse | Where-Object { $_.FullName -notmatch '\\(obj|bin)\\' -and $_.Extension.ToLowerInvariant() -notin @('.dwg','.dwl','.dwl2','.bak','.sv$','.kmz','.csv','.tsv','.ntd','.jpg','.jpeg') }
}
$trackedFiles += Get-ChildItem -LiteralPath (Join-Path $root 'assets/light-blocks') -Filter '*.dwg' -File
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
if($ProtectedRuntime){
 $proof=Get-Content -LiteralPath (Join-Path $BinDir 'protection.json') -Raw | ConvertFrom-Json
 if($proof.tool -ne 'Obfuscar 2.2.50'){throw 'Missing verified protection build'}
 foreach($assemblyName in @('BHT.Core.dll','BHT.Bridge.dll','BHT.Palette.dll')){
  if((Get-FileHash (Join-Path $BinDir $assemblyName)).Hash -ne $proof.hashes.$assemblyName){throw 'Protected DLL changed after protection'}
 }
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
$lisp = if($ProtectedRuntime){[IO.Path]::GetFullPath($CompiledLisp)}else{Join-Path $root "src\lisp\BHT-$version.lsp"}
if($ProtectedRuntime -and (!(Test-Path -LiteralPath $lisp) -or [IO.Path]::GetFileName($lisp) -ne "BHT-$version.fas")){throw 'Missing compiled runtime for this version'}
Copy-Item -LiteralPath $lisp -Destination $stage
if(!$ProtectedRuntime){Copy-Item -LiteralPath (Join-Path $root 'src\lisp\modules') -Destination $stage -Recurse}
Copy-Item -LiteralPath (Join-Path $bin 'BHT.Core.dll'),(Join-Path $bin 'BHT.Bridge.dll'),(Join-Path $bin 'BHT.Palette.dll') -Destination $stage
if($ProtectedRuntime){Copy-Item -LiteralPath (Join-Path $root 'packaging\README_RUNTIME.md') -Destination (Join-Path $stage 'README.md')}
else{Copy-Item -LiteralPath (Join-Path $root 'README.md') -Destination $stage}
Copy-Item -LiteralPath (Join-Path $root 'CHANGELOG.md') -Destination $stage
if($ProtectedRuntime){
 New-Item -ItemType Directory -Path (Join-Path $stage 'docs') -Force | Out-Null
 foreach($doc in @('HUONG_DAN.md',"RELEASE_NOTES_$version.md")){
  Copy-Item -LiteralPath (Join-Path $root "docs\$doc") -Destination (Join-Path $stage 'docs')
 }
}else{Copy-Item -LiteralPath (Join-Path $root 'docs') -Destination $stage -Recurse}
Copy-Item -LiteralPath (Join-Path $root 'packaging\INSTALL_BHT.ps1'),(Join-Path $root 'packaging\INSTALL_BHT.cmd'),(Join-Path $root 'packaging\README_INSTALL.md') -Destination $stage

# Verified previews are embedded in BHT.Palette.dll; source assets remain available with IncludeSource.
$toolStage = Join-Path $stage 'scripts'
New-Item -ItemType Directory -Force -Path $toolStage | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'scripts\audit_tdt_library.ps1') -Destination $toolStage

# Ban giao kem ma nguon co the build lai, khong kem .git, build, DLL Autodesk hay du lieu khao sat.
if ($IncludeSource) {
$sourceStage = Join-Path $stage 'source\BHT-CAD'
New-Item -ItemType Directory -Force -Path $sourceStage | Out-Null
Copy-Item -LiteralPath (Join-Path $root '.gitignore'),(Join-Path $root 'BHT.sln'),(Join-Path $root 'VERSION'),(Join-Path $root 'README.md'),(Join-Path $root 'CHANGELOG.md'),(Join-Path $root 'AGENTS.md') -Destination $sourceStage
foreach ($sourceDir in @('.github','docs','packaging','scripts','src','tests','assets')) {
  $sourcePath = Join-Path $root $sourceDir
  foreach ($file in (Get-ChildItem -LiteralPath $sourcePath -File -Recurse | Where-Object {
    $_.FullName -notmatch '\\(obj|bin)\\' -and $_.Extension.ToLowerInvariant() -notin @('.dll','.exe','.pdb','.user','.suo')
  })) {
    $relative = $file.FullName.Substring($root.Length + 1)
    $target = Join-Path $sourceStage $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target
  }
}

}
$bundle = Join-Path $stage 'BHT.bundle'
$bundleContents = Join-Path $bundle 'Contents\Windows'
New-Item -ItemType Directory -Force -Path $bundleContents | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'packaging\BHT.bundle\PackageContents.xml') -Destination $bundle
Copy-Item -LiteralPath $lisp,(Join-Path $bin 'BHT.Core.dll'),(Join-Path $bin 'BHT.Bridge.dll'),(Join-Path $bin 'BHT.Palette.dll') -Destination $bundleContents
if(!$ProtectedRuntime){Copy-Item -LiteralPath (Join-Path $root 'src\lisp\modules') -Destination $bundleContents -Recurse}
else{
 $manifestPath=Join-Path $bundle 'PackageContents.xml'
 $manifestText=[IO.File]::ReadAllText($manifestPath).Replace("BHT-$version.lsp","BHT-$version.fas")
 [IO.File]::WriteAllText($manifestPath,$manifestText,[Text.UTF8Encoding]::new($true))
}

# Ship a verified local BHT sign snapshot for offline use; compiled vendor plugins are never loaded.
$adsLocal = Join-Path $root 'ads_library_local\TrafficSignal'
if (-not (Test-Path -LiteralPath (Join-Path $adsLocal 'BIEN_CAM.txt'))) {
  & (Join-Path $root 'scripts\copy_ads_library.ps1') -Destination $adsLocal
}
$adsBundle = Join-Path $bundleContents 'SignLibrary\BHT'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $adsBundle) | Out-Null
Copy-Item -LiteralPath $adsLocal -Destination $adsBundle -Recurse
$adsLoose = Join-Path $stage 'SignLibrary\BHT'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $adsLoose) | Out-Null
Copy-Item -LiteralPath $adsLocal -Destination $adsLoose -Recurse

$lightSource = Join-Path $root 'assets\light-blocks'
$lightBundle = Join-Path $bundleContents 'LightLibrary'
$lightLoose = Join-Path $stage 'LightLibrary'
if (-not (Test-Path -LiteralPath (Join-Path $lightSource 'DEN_TIN_HIEU_3_MAU.dwg'))) { throw 'Thiếu thư viện đèn BHT.' }
Copy-Item -LiteralPath $lightSource -Destination $lightBundle -Recurse
Copy-Item -LiteralPath $lightSource -Destination $lightLoose -Recurse


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
$libraryRoots = @($adsBundle, $adsLoose, $lightBundle, $lightLoose)
if ($IncludeSource) { $libraryRoots += Join-Path $sourceStage 'assets\light-blocks' }
$libraryPrefixes = $libraryRoots | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') + '\' }
Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object {
  $filePath = $_.FullName
  ($forbiddenExtensions -contains $_.Extension.ToLowerInvariant()) -and
    -not ($libraryPrefixes | Where-Object { $filePath.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) })
} | Remove-Item -Force

if ($IncludeSource) { @{ version = $version; contentHash = $contentHash; artifact = ('BHT-' + $version + '.zip') } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $sourceStage 'RELEASE_STATE.json') -Encoding UTF8 }

if($ProtectedRuntime){
 foreach($doc in Get-ChildItem -LiteralPath $stage -Recurse -File -Filter '*.md'){
  $text=[IO.File]::ReadAllText($doc.FullName)
  [IO.File]::WriteAllText($doc.FullName,$text.Replace("BHT-$version.lsp","BHT-$version.fas"),[Text.UTF8Encoding]::new($true))
 }
 $leaks=@(Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object {$_.Extension -in '.lsp','.cs','.pdb','.sln','.csproj','.fasmap' -or $_.Name -match '^(Mapping|obfuscar)\.'})
 if($leaks.Count -gt 0 -or (Test-Path (Join-Path $stage 'source'))){throw 'Protected package contains private source/debug files'}
}
$hashFile = Join-Path $stage 'SHA256SUMS.txt'
$hashTargets = Get-ChildItem -LiteralPath $stage -File -Recurse | Where-Object { $_.FullName -ne $hashFile }
$basePath = $stage.TrimEnd('\') + '\'
$hashLines = foreach ($f in $hashTargets) {
  $relative = $f.FullName.Substring($basePath.Length).Replace('\', '/')
  '{0}  {1}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash, $relative
}
$hashLines | Set-Content -LiteralPath $hashFile -Encoding UTF8
$singleInstaller = Join-Path $resolvedOut ('BHT-Setup-' + $version + '.exe')
& (Join-Path $PSScriptRoot 'build-installer.ps1') -PackageRoot $stage -OutFile $singleInstaller
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal

@{ version = $version; contentHash = $contentHash; artifact = $zip; installer = $singleInstaller } | ConvertTo-Json | Set-Content -LiteralPath $releaseStatePath -Encoding UTF8
Get-Item -LiteralPath $stage,$zip,$singleInstaller | Select-Object FullName,Length,LastWriteTime
