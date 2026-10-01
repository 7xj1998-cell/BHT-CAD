# BHT 0.6.7 - bo cai Application Bundle
# File nay PHAI luu UTF-8 co BOM de Windows PowerShell 5.1 doc dung tieng Viet.
param([switch]$ValidateOnly)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

$bhtVersion = '0.6.7'

function Test-BhtPackage([string]$PackageRoot) {
  $rootPath = [IO.Path]::GetFullPath($PackageRoot).TrimEnd('\') + '\'
  $manifest = Join-Path $rootPath 'SHA256SUMS.txt'
  if (-not (Test-Path -LiteralPath $manifest)) { throw 'Thiếu SHA256SUMS.txt: bộ cài không nhận gói không có bảng kiểm tra.' }
  $expected = @{}
  foreach ($line in [IO.File]::ReadAllLines($manifest)) {
    if ($line.Trim() -eq '') { continue }
    if ($line -notmatch '^([A-Fa-f0-9]{64})  (.+)$') { throw 'Bảng SHA256 không hợp lệ.' }
    $hash = $Matches[1]; $relative = $Matches[2].Replace('/', '\')
    $path = [IO.Path]::GetFullPath((Join-Path $rootPath $relative))
    if (-not $path.StartsWith($rootPath, [StringComparison]::OrdinalIgnoreCase)) { throw 'Đường dẫn trong manifest nằm ngoài gói.' }
    if ($expected.ContainsKey($path)) { throw 'Manifest chứa đường dẫn trùng.' }
    $expected[$path] = $hash
  }
  $bundle = Join-Path $rootPath 'BHT.bundle'
  $files = @(Get-ChildItem -LiteralPath $bundle -File -Recurse)
  if ((Get-Item -LiteralPath $bundle).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Bundle nguồn là liên kết: dừng.' }
  $bundlePrefix = $bundle.TrimEnd('\') + '\'
  $listed = @($expected.Keys | Where-Object { $_.StartsWith($bundlePrefix,[StringComparison]::OrdinalIgnoreCase) })
  if ($listed.Count -ne $files.Count) { throw 'Bundle thiếu file hoặc có file ngoài manifest.' }
  foreach ($entry in Get-ChildItem -LiteralPath $bundle -Recurse) {
    if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Không nhận liên kết/reparse point trong bundle.' }
  }
  foreach ($f in $files) {
    if (-not $expected.ContainsKey($f.FullName)) { throw ('File không có trong manifest: ' + $f.Name) }
    if ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne $expected[$f.FullName]) { throw ('File đã thay đổi: ' + $f.Name) }
  }
  $xml = [xml][IO.File]::ReadAllText((Join-Path $bundle 'PackageContents.xml'))
  if ($xml.ApplicationPackage.AppVersion -ne $bhtVersion) { throw 'Phiên bản bundle không khớp bộ cài.' }
  foreach ($name in @('BHT.Core','BHT.Bridge','BHT.Palette')) {
    if ([Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $bundle "Contents\Windows\$name.dll")).FileVersion -ne "$bhtVersion.0") { throw ('DLL khác phiên bản: ' + $name) }
  }
  return $files.Count
}
function Install-BhtBundle([string]$Source, [string]$PluginsRoot) {
  $safeRoot = [IO.Path]::GetFullPath($PluginsRoot).TrimEnd('\') + '\'
  New-Item -ItemType Directory -Force -Path $safeRoot | Out-Null
  $target = Join-Path $safeRoot 'BHT.bundle'
  $stage = Join-Path $safeRoot ('BHT-stage-' + [guid]::NewGuid().ToString('N'))
  $backup = Join-Path $safeRoot ('BHT-backup-' + [guid]::NewGuid().ToString('N'))
  foreach ($path in @($target,$stage,$backup)) {
    if (-not [IO.Path]::GetFullPath($path).StartsWith($safeRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Đường dẫn cài đặt không an toàn.' }
  }
  if ((Test-Path -LiteralPath $target) -and ((Get-Item -LiteralPath $target).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Đích cài đặt là liên kết: dừng.' }
  Copy-Item -LiteralPath $Source -Destination $stage -Recurse
  foreach ($f in Get-ChildItem -LiteralPath $Source -File -Recurse) {
    $rel = $f.FullName.Substring($Source.Length).TrimStart('\')
    if ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath (Join-Path $stage $rel) -Algorithm SHA256).Hash) { throw 'Bản sao cài đặt không khớp nguồn.' }
  }
  $moved = $false
  try {
    if (Test-Path -LiteralPath $target) { Move-Item -LiteralPath $target -Destination $backup; $moved = $true }
    Move-Item -LiteralPath $stage -Destination $target
  } catch {
    if ($moved -and -not (Test-Path -LiteralPath $target)) { Move-Item -LiteralPath $backup -Destination $target }
    throw
  }
  return $target
}
function Write-Ok([string]$m)   { Write-Host $m -ForegroundColor Green }
function Write-Info([string]$m) { Write-Host $m }

try {
  $source      = Join-Path $PSScriptRoot 'BHT.bundle'
  $pluginsRoot = Join-Path $env:APPDATA 'Autodesk\ApplicationPlugins'
  $target      = Join-Path $pluginsRoot 'BHT.bundle'

  Write-Info "=== Cài đặt BHT $bhtVersion ==="
  Write-Info "Nguồn : $source"
  Write-Info "Đích  : $target"
  Write-Info ''

  if (-not (Test-Path -LiteralPath (Join-Path $source 'PackageContents.xml'))) {
    throw 'Không tìm thấy BHT.bundle\PackageContents.xml cạnh bộ cài. Hãy giải nén đủ thư mục rồi chạy lại.'
  }

  $verified = Test-BhtPackage $PSScriptRoot
  Write-Info "Đã xác minh $verified file trong bundle."
  if ($ValidateOnly) { Write-Ok 'Gói cài đặt hợp lệ; chưa thay đổi máy.'; exit 0 }

  $runningAcad = @(Get-Process -Name 'acad','accoreconsole' -ErrorAction SilentlyContinue)
  if ($runningAcad.Count -gt 0) {
    $ids = ($runningAcad | ForEach-Object { "$($_.Name) $($_.Id)" }) -join ', '
    throw "AutoCAD đang chạy ($ids). Hãy đóng TẤT CẢ cửa sổ AutoCAD (kiểm tra cả Task Manager) rồi chạy lại bộ cài. DLL .NET đã nạp không thể thay thế khi AutoCAD còn mở."
  }

  $target = Install-BhtBundle $source $pluginsRoot

  $lsp = Join-Path $target "Contents\Windows\BHT-$bhtVersion.lsp"
  if (-not (Test-Path -LiteralPath $lsp)) { throw "Không thấy BHT-$bhtVersion.lsp trong bundle đã cài." }

  # 5.0: phông TrueType của thư viện biển TDT 9.1 (giaothong1.ttf, giaothong2.ttf - kiểu chữ
  # GiaoThong1/GiaoThong2 trong block biển). AutoCAD chỉ chắc chắn tìm thấy TTF khi phông đã
  # đăng ký với Windows -> cài RIÊNG cho người dùng hiện tại (không cần quyền quản trị):
  # chép vào %LOCALAPPDATA%\Microsoft\Windows\Fonts + khóa HKCU\...\Fonts. Phông .shx
  # (VNRomancUpdate.shx) nằm trong BHT.bundle\Contents\Fonts, được thêm vào Support File Search Path.
  # Lỗi cài phông chỉ là CẢNH BÁO, không làm hỏng cài đặt BHT.
  $fontDir = Join-Path $target 'Contents\Fonts'
  if (Test-Path -LiteralPath $fontDir) {
    $userFonts = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $regPath   = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    foreach ($ttf in @(Get-ChildItem -LiteralPath $fontDir -Filter '*.ttf' -File)) {
      try {
        if (Test-Path -LiteralPath (Join-Path $env:WINDIR ('Fonts\' + $ttf.Name))) { Write-Info "Phông $($ttf.Name) đã có trong Windows\Fonts - bỏ qua."; continue }
        Add-Type -AssemblyName System.Drawing
        $pfc = New-Object System.Drawing.Text.PrivateFontCollection
        $pfc.AddFontFile($ttf.FullName)
        $family = if ($pfc.Families.Count -gt 0) { $pfc.Families[0].Name } else { [IO.Path]::GetFileNameWithoutExtension($ttf.Name) }
        $pfc.Dispose()
        New-Item -ItemType Directory -Force -Path $userFonts | Out-Null
        $dst = Join-Path $userFonts $ttf.Name
        $same = (Test-Path -LiteralPath $dst) -and ((Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $ttf.FullName -Algorithm SHA256).Hash)
        if (-not $same) { Copy-Item -LiteralPath $ttf.FullName -Destination $dst -Force }
        if (-not (Test-Path -LiteralPath $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        New-ItemProperty -Path $regPath -Name ($family + ' (TrueType)') -Value $dst -PropertyType String -Force | Out-Null
        Write-Ok "Đã cài phông $family ($($ttf.Name)) cho người dùng hiện tại."
      }
      catch {
        Write-Host ("CẢNH BÁO: chưa cài được phông " + $ttf.Name + ": " + $_.Exception.Message) -ForegroundColor Yellow
      }
    }
  } else {
    Write-Host 'CẢNH BÁO: bundle không có Contents\Fonts (thiếu phông giaothong1/2.ttf, VNRomancUpdate.shx) - block biển TDT có thể báo thiếu phông khi không chạy TDT.' -ForegroundColor Yellow
  }

  Write-Info ''
  Write-Ok "Đã cài BHT $bhtVersion vào $target"
  Write-Ok 'Mở lại AutoCAD rồi gõ BTH hoặc BHT. Không cần NETLOAD.'
  exit 0
}
catch {
  Write-Host ''
  Write-Host ('LỖI: ' + $_.Exception.Message) -ForegroundColor Red
  Write-Host 'Chưa cài được BHT.' -ForegroundColor Red
  exit 1
}
