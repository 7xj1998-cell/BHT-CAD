param([Parameter(Mandatory=$true)][string]$Version)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Use major.minor.patch, e.g. 0.5.2' }
$old = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ([version]$Version -le [version]$old) { throw "New version $Version must exceed $old" }
$oldLisp = [IO.Path]::GetFullPath((Join-Path $root "src\lisp\BHT-$old.lsp"))
$newLisp = [IO.Path]::GetFullPath((Join-Path $root "src\lisp\BHT-$Version.lsp"))
$lispRoot = [IO.Path]::GetFullPath((Join-Path $root 'src\lisp')).TrimEnd('\') + '\'
if (-not $oldLisp.StartsWith($lispRoot, [StringComparison]::OrdinalIgnoreCase) -or -not $newLisp.StartsWith($lispRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Lisp path outside source directory' }
if (Test-Path -LiteralPath $newLisp) { throw 'Target Lisp already exists' }
Move-Item -LiteralPath $oldLisp -Destination $newLisp
$files = @()
foreach ($dir in @('src','packaging','tests')) {
  $files += Get-ChildItem -LiteralPath (Join-Path $root $dir) -Recurse -File | Where-Object { $_.Extension -in '.cs','.lsp','.xml','.props','.ps1','.cmd','.md' }
}
$files += Get-Item -LiteralPath (Join-Path $root 'README.md'),(Join-Path $root 'docs\HUONG_DAN.md')
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
foreach ($file in $files) {
  $text = [IO.File]::ReadAllText($file.FullName)
  $next = $text.Replace("$old.0", "$Version.0").Replace("BHT-$old.lsp", "BHT-$Version.lsp").Replace("BHT $old", "BHT $Version").Replace(('"' + $old + '"'), ('"' + $Version + '"')).Replace(("'" + $old + "'"), ("'" + $Version + "'"))
  if ($next -ne $text) { [IO.File]::WriteAllText($file.FullName, $next, $utf8Bom) }
}
[IO.File]::WriteAllText((Join-Path $root 'VERSION'), "$Version`n", [Text.Encoding]::ASCII)
& (Join-Path $PSScriptRoot 'check-version.ps1')
Write-Host "Version changed: $old -> $Version. Update CHANGELOG, rebuild, test and package."
