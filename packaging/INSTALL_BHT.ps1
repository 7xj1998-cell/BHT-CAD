# BHT 0.5.5 - bo cai Application Bundle
# File nay PHAI luu UTF-8 co BOM de Windows PowerShell 5.1 doc dung tieng Viet.
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }

$bhtVersion = '0.5.5'

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

  $runningAcad = @(Get-Process -Name 'acad','accoreconsole' -ErrorAction SilentlyContinue)
  if ($runningAcad.Count -gt 0) {
    $ids = ($runningAcad | ForEach-Object { "$($_.Name) $($_.Id)" }) -join ', '
    throw "AutoCAD đang chạy ($ids). Hãy đóng TẤT CẢ cửa sổ AutoCAD (kiểm tra cả Task Manager) rồi chạy lại bộ cài. DLL .NET đã nạp không thể thay thế khi AutoCAD còn mở."
  }

  # Bỏ đánh dấu "tải từ Internet" để AutoCAD nạp được DLL.
  Get-ChildItem -LiteralPath $source -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

  New-Item -ItemType Directory -Force -Path $pluginsRoot | Out-Null
  if (Test-Path -LiteralPath $target) {
    $resolvedRoot   = [IO.Path]::GetFullPath($pluginsRoot).TrimEnd('\') + '\'
    $resolvedTarget = [IO.Path]::GetFullPath($target)
    if (-not $resolvedTarget.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
      throw "Đường dẫn gỡ bản cũ không an toàn: $resolvedTarget"
    }
    Write-Info 'Đang gỡ bản BHT.bundle cũ...'
    Remove-Item -LiteralPath $resolvedTarget -Recurse -Force
  }

  Write-Info 'Đang chép BHT.bundle...'
  Copy-Item -LiteralPath $source -Destination $target -Recurse

  # Kiểm tra lại: mọi file đã chép phải trùng SHA256 với nguồn.
  $bad = @()
  foreach ($f in Get-ChildItem -LiteralPath $source -Recurse -File) {
    $rel = $f.FullName.Substring($source.Length).TrimStart('\')
    $dst = Join-Path $target $rel
    if (-not (Test-Path -LiteralPath $dst)) { $bad += "thiếu $rel"; continue }
    $h1 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $h2 = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
    if ($h1 -ne $h2) { $bad += "khác $rel" }
  }
  if ($bad.Count -gt 0) { throw ('Chép chưa đầy đủ: ' + ($bad -join '; ')) }

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
