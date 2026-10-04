# BHT 0.6.11 - chay 1 phien AutoCAD Core Console (accoreconsole) voi 1 file kiem thu .lsp
# -Name  : ten file kiem thu (khong duoi) trong $w ; -Dwg : ban ve mo (BAN SAO), trong = ban ve moi
# -After : cac dong script them sau khi nap .lsp (lenh .NET, bieu thuc Lisp, SAVEAS ...)
# -Saved : ban ve da SAVEAS trong -After -> chi QUIT (khong can _Y)
param(
  [string]$Name,
  [string]$Dwg = '',
  [int]$TimeoutSec = 600,
  [string[]]$After = @(),
  [switch]$Saved,
  [string]$Profile = 'AutoCAD'
)
$w = 'C:\Users\Le Bao\BHT_TEST_V044'
$scr = Join-Path $w "run\$Name.scr"
$lines = @("(load `"C:/Users/Le Bao/BHT_TEST_V044/$Name.lsp`")")
$lines += $After
$lines += '_.QUIT'
if (-not $Saved) { $lines += '_Y' }
Set-Content -LiteralPath $scr -Value ($lines -join "`r`n") -Encoding ASCII
$al = @()
if ($Dwg -ne '') { $al += '/i'; $al += "`"$Dwg`"" }
$al += '/p'; $al += "`"$Profile`""
$al += '/s'; $al += "`"$scr`""; $al += '/l'; $al += 'en-US'
$out = Join-Path $w "run\$Name.console.txt"
$t0 = Get-Date
$p = Start-Process -FilePath 'D:\AutoCAD 2024\accoreconsole.exe' -ArgumentList $al -PassThru -NoNewWindow -RedirectStandardOutput $out -WorkingDirectory (Join-Path $w 'run')
if (-not $p.WaitForExit($TimeoutSec * 1000)) { $p.Kill(); "TIMEOUT after $TimeoutSec s" }
"$Name exit=$($p.ExitCode) elapsed=$([int]((Get-Date)-$t0).TotalSeconds)s start=$($t0.ToString('yyyy-MM-dd HH:mm:ss'))"
