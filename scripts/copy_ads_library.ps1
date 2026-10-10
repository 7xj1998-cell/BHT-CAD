param([string]$AdsRoot = 'C:\Program Files\BZS\ADSCivil NW 2026 For Autocad', [Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$source = if (Test-Path -LiteralPath (Join-Path $AdsRoot 'BIEN_CAM.txt')) { $AdsRoot } else { Join-Path $AdsRoot 'TrafficSignal' }
if (-not (Test-Path -LiteralPath (Join-Path $source 'BIEN_CAM.txt'))) { throw "Thiếu danh mục ADSCivil: $source" }
$source = [IO.Path]::GetFullPath($source).TrimEnd('\')
$target = [IO.Path]::GetFullPath($Destination).TrimEnd('\')
if ($target.StartsWith($source + '\', [StringComparison]::OrdinalIgnoreCase) -or $source.StartsWith($target + '\', [StringComparison]::OrdinalIgnoreCase) -or $target -eq $source) { throw 'Thư mục sao chép phải tách khỏi thư viện gốc.' }
New-Item -ItemType Directory -Force -Path $target | Out-Null
$inventory = New-Object System.Collections.Generic.List[object]
foreach ($file in Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object { $_.Extension.ToLowerInvariant() -in '.dwg','.png','.jpg','.jpeg','.txt','.xml','.json' }) {
  $relative = $file.FullName.Substring($source.Length + 1)
  $output = Join-Path $target $relative
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $output) | Out-Null
  $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  Copy-Item -LiteralPath $file.FullName -Destination $output -Force
  if ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash -ne $hash) { throw "Bản sao không khớp: $relative" }
  $inventory.Add([pscustomobject]@{ path=$relative.Replace('\','/'); sha256=$hash; bytes=$file.Length })
}
$inventory | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $target 'BHT_ADS_MANIFEST.json') -Encoding UTF8
Write-Host "Đã sao chép và kiểm SHA-256 $($inventory.Count) tài nguyên ADSCivil."
