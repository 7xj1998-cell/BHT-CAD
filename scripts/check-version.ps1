param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "Invalid semantic version: $version" }
$assemblyVersion = "$version.0"
function Require([bool]$condition, [string]$message) { if (-not $condition) { throw $message } }
$core = Get-Content -LiteralPath (Join-Path $root 'src\dotnet\BHT.Core\Models.cs') -Raw
Require ($core.Contains('Version = "' + $version + '"')) 'BhtVersion.Version differs from VERSION'
Require ($core.Contains('AssemblyVersion = "' + $assemblyVersion + '"')) 'BhtVersion.AssemblyVersion differs from VERSION'
Require ($core.Contains('FileVersion = "' + $assemblyVersion + '"')) 'BhtVersion.FileVersion differs from VERSION'
foreach ($project in @('BHT.Core','BHT.Bridge','BHT.Palette')) {
  $info = Get-Content -LiteralPath (Join-Path $root "src\dotnet\$project\AssemblyInfo.cs") -Raw
  Require ($info.Contains('AssemblyVersion("' + $assemblyVersion + '")')) "$project AssemblyVersion mismatch"
  Require ($info.Contains('AssemblyFileVersion("' + $assemblyVersion + '")')) "$project AssemblyFileVersion mismatch"
  Require ($info.Contains('AssemblyInformationalVersion("' + $version + '")')) "$project informational version mismatch"
}
$props = [xml](Get-Content -LiteralPath (Join-Path $root 'src\dotnet\Directory.Build.props') -Raw)
Require ($props.Project.PropertyGroup.Version -eq $assemblyVersion) 'Directory.Build.props version mismatch'
$lispPath = Join-Path $root "src\lisp\BHT-$version.lsp"
Require (Test-Path -LiteralPath $lispPath) 'Versioned Lisp file missing'
$lisp = Get-Content -LiteralPath $lispPath -Raw
Require ($lisp.Contains('(setq *bht-version* "' + $version + '")')) 'Lisp runtime version mismatch'
Require ($lisp.Contains('(findfile "BHT-' + $version + '.lsp")')) 'Lisp loader filename mismatch'
$manifest = [xml](Get-Content -LiteralPath (Join-Path $root 'packaging\BHT.bundle\PackageContents.xml') -Raw)
Require ($manifest.ApplicationPackage.AppVersion -eq $version) 'Bundle AppVersion mismatch'
Require (@($manifest.ApplicationPackage.Components.ComponentEntry | Where-Object { $_.AppName -eq 'BHT.Lisp' })[0].ModuleName -eq "./Contents/Windows/BHT-$version.lsp") 'Bundle Lisp filename mismatch'
$installer = Get-Content -LiteralPath (Join-Path $root 'packaging\INSTALL_BHT.ps1') -Raw
Require ($installer.Contains("`$bhtVersion = '$version'")) 'Installer version mismatch'
Write-Host "VERSION CHECK PASSED: $version / $assemblyVersion"
