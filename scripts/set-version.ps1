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
  $next = $text.Replace("$old.0", "$Version.0").Replace("BHT-$old.lsp", "BHT-$Version.lsp").Replace("BHT-$old.fas", "BHT-$Version.fas").Replace("BHT-$old.zip", "BHT-$Version.zip").Replace("BHT-Setup-$old.exe", "BHT-Setup-$Version.exe").Replace("BHT $old", "BHT $Version").Replace(('"' + $old + '"'), ('"' + $Version + '"')).Replace(("'" + $old + "'"), ("'" + $Version + "'"))
  if ($file.FullName -eq (Join-Path $root 'README.md') -or $file.FullName -eq (Join-Path $root 'docs\HUONG_DAN.md')) {
    $next = [regex]::Replace($next, '^# BHT v\d+\.\d+\.\d+', ('# BHT v' + $Version))
    $next = [regex]::Replace($next, 'BHT-\d+\.\d+\.\d+\.zip', ('BHT-' + $Version + '.zip'))
    $next = [regex]::Replace($next, 'Bản \d+\.\d+\.\d+ gồm', ('Bản ' + $Version + ' gồm'))
    $next = [regex]::Replace($next, 'tiêu đề hiển thị \d+\.\d+\.\d+', ('tiêu đề hiển thị ' + $Version))
    if ($file.FullName -eq (Join-Path $root 'README.md')) {
      $next = [regex]::Replace($next, 'RELEASE_NOTES_\d+\.\d+\.\d+\.md', ('RELEASE_NOTES_' + $Version + '.md'))
      $next = [regex]::Replace($next, 'build\\v\d+\.\d+\.\d+\\bin', ('build\v' + $Version + '\bin'))
    }
    $next = [regex]::Replace($next, 'Các thay đổi chính của v\d+\.\d+\.\d+', ('Các thay đổi chính của v' + $Version))
  }
  if ($next -ne $text) { [IO.File]::WriteAllText($file.FullName, $next, $utf8Bom) }
}
[IO.File]::WriteAllText((Join-Path $root 'VERSION'), "$Version`n", [Text.Encoding]::ASCII)
& (Join-Path $PSScriptRoot 'check-version.ps1')
Write-Host "Version changed: $old -> $Version. Update CHANGELOG, rebuild, test and package."
