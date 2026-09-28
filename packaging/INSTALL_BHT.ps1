$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'BHT.bundle'
$pluginsRoot = Join-Path $env:APPDATA 'Autodesk\ApplicationPlugins'
$target = Join-Path $pluginsRoot 'BHT.bundle'

if (-not (Test-Path -LiteralPath (Join-Path $source 'PackageContents.xml'))) {
  throw 'Không tìm thấy BHT.bundle cạnh bộ cài.'
}

$runningAcad = @(Get-Process -Name 'acad' -ErrorAction SilentlyContinue)
if ($runningAcad.Count -gt 0) {
  $ids = ($runningAcad | ForEach-Object { $_.Id }) -join ', '
  throw "AutoCAD đang chạy (PID: $ids). Hãy đóng TẤT CẢ cửa sổ AutoCAD rồi chạy lại bộ cài. DLL .NET đã nạp không thể thay thế đúng phiên bản khi AutoCAD còn mở."
}

New-Item -ItemType Directory -Force -Path $pluginsRoot | Out-Null
if (Test-Path -LiteralPath $target) {
  $resolvedRoot = [IO.Path]::GetFullPath($pluginsRoot).TrimEnd('\') + '\'
  $resolvedTarget = [IO.Path]::GetFullPath($target)
  if (-not $resolvedTarget.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Đường dẫn gỡ bản cũ không an toàn: $resolvedTarget"
  }
  Remove-Item -LiteralPath $resolvedTarget -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $target -Recurse
Write-Host "Đã cài BHT 0.4.5 vào $target"
Write-Host 'Mở lại AutoCAD rồi gõ BTH hoặc BHT. Không cần NETLOAD.'
