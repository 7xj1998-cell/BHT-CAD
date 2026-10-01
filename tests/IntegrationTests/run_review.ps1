param([string]$AcadDir = 'D:\AutoCAD 2024', [string]$FixtureRoot = 'C:\Users\Le Bao\BHT_TEST_V044', [string]$RuntimePath = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
if ($RuntimePath -eq '') { $RuntimePath = Join-Path $root "src\lisp\BHT-$version.lsp" }
$out = Join-Path $root "build\v$version\review"
New-Item -ItemType Directory -Force -Path (Join-Path $out 'run'),(Join-Path $out 'profile') | Out-Null
function LispPath($p) { $p.Replace('\','/') }
$utf8 = [Text.UTF8Encoding]::new($true)
$common = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 't_common.lsp'))
$common = $common.Replace('(setq *T-DIR* "C:/Users/Le Bao/BHT_TEST_V044/")','(setq *T-DIR* "' + (LispPath $FixtureRoot) + '/")')
$common = [regex]::Replace($common, '(?m)^\(setq \*T-LSP\*.*$', '(setq *T-LSP* "' + (LispPath $RuntimePath) + '")')
$common = $common.Replace('(strcat *T-DIR* "run/result_', '(strcat "' + (LispPath $out) + '/run/result_')
$common = $common.Replace('(setq *T-BIN* (strcat *T-DIR* "bin/"))','(setq *T-BIN* "' + (LispPath "$root\build\v$version\bin") + '/")')
[IO.File]::WriteAllText((Join-Path $out 't_common.lsp'), $common, $utf8)
foreach ($name in @('REVIEW','S0','V5','TX')) {
  $dwg = ''
  if ($name -eq 'TX') {
    $dwg = Join-Path $FixtureRoot 'tdt\tdt_copy.dwg'
    if (-not (Test-Path -LiteralPath $dwg)) { Write-Host 'BLOCKED TX: missing TDT proxy drawing fixture; original drawing untouched'; continue }
  }
  if ($name -eq 'V5' -and -not (Test-Path -LiteralPath (Join-Path $FixtureRoot 'data\survey.csv'))) { throw 'Missing survey fixture for V5' }
  $test = [IO.File]::ReadAllText((Join-Path $PSScriptRoot "test_$name.lsp"))
  $test = $test.Replace('C:/Users/Le Bao/BHT_TEST_V044/t_common.lsp', (LispPath "$out\t_common.lsp"))
  [IO.File]::WriteAllText((Join-Path $out "test_$name.lsp"), $test, $utf8)
  $lines = @('(setvar "SECURELOAD" 0)', '(setvar "LISPSYS" 1)')
  $lines = @(('(setq *bht-module-root* "' + (LispPath "$root\src\lisp") + '" )')) + $lines
  if ($name -eq 'REVIEW') { $lines += '(load "' + (LispPath $RuntimePath) + '")' }
  $lines += '(load "' + (LispPath "$out\test_$name.lsp") + '")'
  $lines += @('_.QUIT','_Y')
  $scr = Join-Path $out "$name.scr"
  [IO.File]::WriteAllLines($scr,$lines,$utf8)
  $args = @('/isolate','BHTReviewTests',(Join-Path $out 'profile'),'/p','<<Unnamed Profile>>','/s',$scr,'/l','en-US')
  if ($dwg -ne '') { $args += @('/i',$dwg) }
  $raw = Join-Path $out "$name-raw.txt"
  & "$AcadDir\accoreconsole.exe" @args > $raw
  $log = [IO.File]::ReadAllText($raw).Replace([string][char]0,'')
  [IO.File]::WriteAllText((Join-Path $out "$name-console.txt"),$log,$utf8)
  $lines = @(('(setq *bht-module-root* "' + (LispPath "$root\src\lisp") + '" )')) + $lines
  if ($name -eq 'REVIEW') {
    $log -split "`n" | Where-Object { $_ -match '^(PASS|FAIL) REVIEW|REVIEW-FAIL=' } | ForEach-Object { Write-Host $_ }
    if ($log -notmatch 'REVIEW-FAIL=0' -or $log -match 'FAIL REVIEW') { throw 'REVIEW tests failed' }
  } else {
    $result = Join-Path $out "run\result_$name.txt"
    if (-not (Test-Path -LiteralPath $result)) { throw "Missing test result: $name" }
    $report = [IO.File]::ReadAllText($result)
    $report -split "`n" | Where-Object { $_ -match '^FAIL|^TONG' } | ForEach-Object { Write-Host $_ }
    if ($report -match '(?m)^FAIL' -or $report -notmatch 'TONG PHIEN') { throw "$name tests failed" }
  }
}
