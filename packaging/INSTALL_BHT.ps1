$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'BHT.bundle'
$pluginsRoot = Join-Path $env:APPDATA 'Autodesk\ApplicationPlugins'
$target = Join-Path $pluginsRoot 'BHT.bundle'

if (-not (Test-Path -LiteralPath (Join-Path $source 'PackageContents.xml'))) {
  throw 'Không tìm thấy BHT.bundle cạnh bộ cài.'
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
Write-Host "Đã cài BHT 0.4.1 vào $target"
Write-Host 'Mở lại AutoCAD rồi gõ BTH hoặc BHT. Không cần NETLOAD.'
