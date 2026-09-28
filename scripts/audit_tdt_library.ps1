<#
.SYNOPSIS
  Lap chi muc thu vien bien bao tu ban TDT da cai tren may dang chay.
.DESCRIPTION
  TDT luu nam ban ve thu vien trong Data\Bien bao\bienbao.set. Script chi doc
  goi nay, tach cac DWG vao thu muc build de kiem tra va xuat danh muc XML thanh
  CSV UTF-8 co BOM. Khong sua tep cai dat va khong dong goi tai san TDT vao BHT.
#>
param(
  [string]$TdtRoot = '',
  [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($OutDir -eq '') { $OutDir = Join-Path $repoRoot 'build\tdt-library-audit\extracted' }

if ($TdtRoot -eq '') {
  $candidates = @(
    'C:\Program Files (x86)\TDT Solution 2022',
    'C:\Program Files\TDT Solution 2022',
    'C:\Program Files (x86)\TDT Solution 9.1',
    'C:\Program Files\TDT Solution 9.1'
  )
  $TdtRoot = $candidates |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ 'Data\Bien bao\bienbao.set') } |
    Select-Object -First 1
}
if (-not $TdtRoot) { throw 'Khong tim thay Data\Bien bao\bienbao.set trong ban TDT da cai.' }

$libraryDir = Join-Path $TdtRoot 'Data\Bien bao'
$setPath = Join-Path $libraryDir 'bienbao.set'
$xmlPath = Join-Path $libraryDir 'Bienbao.xml'
if (-not (Test-Path -LiteralPath $xmlPath)) { throw "Thieu danh muc: $xmlPath" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$bytes = [IO.File]::ReadAllBytes($setPath)
if ($bytes.Length -lt 12) { throw 'bienbao.set qua ngan hoac khong hop le.' }
$formatVersion = [BitConverter]::ToInt32($bytes, 0)
$entryCount = [BitConverter]::ToInt32($bytes, 4)
$names = @(
  'Bien bao cam.dwg',
  'Bien bao nguy hiem.dwg',
  'Bien hieu lenh.dwg',
  'Bien chi dan.dwg',
  'Bien phu.dwg'
)

$offset = 8
$drawings = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $entryCount; $i++) {
  if ($offset + 4 -gt $bytes.Length) { throw "Thieu truong kich thuoc tai muc $i." }
  $size = [BitConverter]::ToInt32($bytes, $offset)
  $start = $offset + 4
  $end = $start + $size
  if ($size -lt 0 -or $end -gt $bytes.Length) { throw "Kich thuoc muc $i khong hop le: $size." }
  if ($size -gt 0) {
    if ($i -ge $names.Count) { throw "Goi co DWG ngoai danh sach da biet tai muc $i." }
    $payload = New-Object byte[] $size
    [Array]::Copy($bytes, $start, $payload, 0, $size)
    $signature = [Text.Encoding]::ASCII.GetString($payload, 0, [Math]::Min(6, $payload.Length))
    if (-not $signature.StartsWith('AC10')) { throw "Muc $i khong co chu ky DWG AC10." }
    $target = Join-Path $OutDir $names[$i]
    [IO.File]::WriteAllBytes($target, $payload)
    $drawings.Add([pscustomobject]@{
      Index = $i
      Name = $names[$i]
      Bytes = $size
      Signature = $signature
      SHA256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
      Path = $target
    })
  }
  $offset = $end
}
if ($offset -ne $bytes.Length) { throw "Con $($bytes.Length - $offset) byte chua doc trong bienbao.set." }

[xml]$xml = Get-Content -LiteralPath $xmlPath -Encoding UTF8
$catalog = New-Object System.Collections.Generic.List[object]
foreach ($group in $xml.SelectNodes('//*[@dataSource]')) {
  foreach ($sign in $group.ChildNodes) {
    if ($sign.NodeType -ne [Xml.XmlNodeType]::Element) { continue }
    $catalog.Add([pscustomobject]@{
      NhomId = $group.GetAttribute('id')
      Nhom = $group.Attributes[1].Value
      Ma = $sign.Attributes[0].Value
      MoTa = $sign.Attributes[1].Value
      HinhDang = $sign.Attributes[2].Value
      DwgNguon = $group.GetAttribute('dataSource')
      AnhXemTruoc = Join-Path $group.GetAttribute('imgSource') ($sign.Attributes[0].Value + '.bmp')
    })
  }
}

$catalogPath = Join-Path $OutDir 'tdt_bien_bao_catalog.csv'
$csvLines = $catalog | ConvertTo-Csv -NoTypeInformation
[IO.File]::WriteAllLines($catalogPath, $csvLines, (New-Object Text.UTF8Encoding($true)))

Write-Host "TDT root: $TdtRoot"
Write-Host "Container format: $formatVersion | entries: $entryCount | extracted: $($drawings.Count) DWG"
Write-Host "XML catalog: $($catalog.Count) signs | CSV UTF-8 BOM: $catalogPath"
$drawings | Format-Table Index, Name, Bytes, Signature, SHA256 -AutoSize
