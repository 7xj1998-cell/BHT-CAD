param([Parameter(Mandatory=$true)][string]$PackageRoot, [Parameter(Mandatory=$true)][string]$OutFile)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
$package = [IO.Path]::GetFullPath($PackageRoot).TrimEnd('\')
$output = [IO.Path]::GetFullPath($OutFile)
if ((Test-Path -LiteralPath $output)) { throw ('Installer output already exists: ' + $output) }
$buildRoot = [IO.Path]::GetFullPath((Join-Path $root 'build')).TrimEnd('\') + '\'
if (-not $output.StartsWith($buildRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Installer output must be under build.' }
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $package 'INSTALL_BHT.ps1') -ValidateOnly
if ($LASTEXITCODE -ne 0) { throw 'Installer source package failed validation.' }
$bundleXml = [xml][IO.File]::ReadAllText((Join-Path $package 'BHT.bundle\PackageContents.xml'))
if ($bundleXml.ApplicationPackage.AppVersion -ne $version) { throw 'Installer payload version differs from VERSION.' }
$work = Join-Path $root ('build\setup-' + $version + '-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$payload = Join-Path $work 'payload.zip'
Add-Type -AssemblyName System.IO.Compression
$stream = [IO.File]::Create($payload)
$zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
try {
  $files = @(Get-ChildItem -LiteralPath (Join-Path $package 'BHT.bundle') -Recurse -File)
  $files += Get-Item -LiteralPath (Join-Path $package 'INSTALL_BHT.ps1'), (Join-Path $package 'README_INSTALL.md')
  foreach ($file in $files) {
    $entry = $zip.CreateEntry($file.FullName.Substring($package.Length + 1).Replace('\','/'), [IO.Compression.CompressionLevel]::Optimal)
    $target = $entry.Open(); $input = [IO.File]::OpenRead($file.FullName)
    try { $input.CopyTo($target) } finally { $input.Dispose(); $target.Dispose() }
  }
  $manifest = @($files | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash + '  ' + $_.FullName.Substring($package.Length + 1).Replace('\','/') })
  $entry = $zip.CreateEntry('SHA256SUMS.txt'); $target = $entry.Open()
  try { $bytes = [Text.Encoding]::UTF8.GetBytes(($manifest -join "`r`n") + "`r`n"); $target.Write($bytes, 0, $bytes.Length) } finally { $target.Dispose() }
} finally { $zip.Dispose(); $stream.Dispose() }
$payloadHash = (Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash
$generated = Join-Path $work 'SetupMetadata.cs'
$metadata = @"
using System.Reflection;
[assembly: AssemblyTitle("BHT Installer")]
[assembly: AssemblyProduct("BHT")]
[assembly: AssemblyVersion("$version.0")]
[assembly: AssemblyFileVersion("$version.0")]
namespace BHT.Setup { internal static class SetupPayload { internal const string Sha256 = "$payloadHash"; } }
"@
[IO.File]::WriteAllText($generated, $metadata, [Text.UTF8Encoding]::new($true))
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$arguments = @('/nologo','/target:winexe','/platform:x64','/optimize+', '/r:System.dll','/r:System.Core.dll','/r:System.Windows.Forms.dll','/r:System.Drawing.dll','/r:System.IO.Compression.dll','/r:System.IO.Compression.FileSystem.dll', "/out:$output", "/resource:$payload,BHT.Setup.Payload.zip", ('/win32manifest:' + (Join-Path $root 'packaging\Setup.manifest')), (Join-Path $root 'packaging\SingleFileInstaller.cs'), $generated)
$response = Join-Path $work 'compile.rsp'
[IO.File]::WriteAllLines($response, @($arguments | ForEach-Object { '"' + $_ + '"' }), [Text.UTF8Encoding]::new($true))
& $csc /noconfig ('@' + $response)
if ($LASTEXITCODE -ne 0) { throw 'Single-file installer compile failed.' }
$report = Join-Path $work 'validation.txt'
$process = Start-Process -FilePath $output -ArgumentList @('--validate-only','--report',('"' + $report + '"')) -WindowStyle Hidden -Wait -PassThru
if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $report)) { throw 'Single-file installer validation failed.' }
Get-Content -LiteralPath $report
Get-Item -LiteralPath $output | Select-Object FullName,Length
