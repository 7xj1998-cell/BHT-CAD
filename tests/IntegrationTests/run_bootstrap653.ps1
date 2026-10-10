param([Parameter(Mandatory=$true)][string]$BinDir,[Parameter(Mandatory=$true)][string]$RuntimePath,[ValidateSet("success","missing","broken","mismatch")][string]$Mode="success",[switch]$WithSupportPath)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$v=(Get-Content "$root\VERSION" -Raw).Trim()
$work=Join-Path $env:TEMP ('BHT nạp lõi '+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
foreach($n in @('BHT.Core.dll','BHT.Bridge.dll','BHT.Palette.dll')){Copy-Item -LiteralPath "$BinDir\$n" -Destination $work}
[IO.File]::WriteAllText("$work\mode.txt",$Mode)
if($Mode -eq 'success'){Copy-Item -LiteralPath $RuntimePath -Destination $work}
if($Mode -eq 'broken'){[IO.File]::WriteAllText("$work\BHT-$v.lsp",'(error "QA_LOAD_FAILED")')}
if($Mode -eq 'mismatch'){[IO.File]::WriteAllText("$work\BHT-$v.lsp",'(vl-load-com) (defun bht:api-version () (list "OK" "0.0.1" "0")) (vl-acad-defun ''bht:api-version)')}
$acad='D:\AutoCAD 2024'
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:library /platform:x64 "/r:$work\BHT.Core.dll" "/r:$work\BHT.Bridge.dll" "/r:$acad\accoremgd.dll" "/r:$acad\acdbmgd.dll" "/out:$work\RuntimeBootstrapProbe.dll" "$PSScriptRoot\RuntimeBootstrapProbe.cs"
if($LASTEXITCODE -ne 0){throw 'Probe compile failed'}
$lines=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+("$work\BHT.Bridge.dll").Replace('\','/')+'"'),'_.NETLOAD',('"'+("$work\RuntimeBootstrapProbe.dll").Replace('\','/')+'"'),'BHTBOOTTEST')
if($WithSupportPath){
 $lines=@('(setenv "ACAD" (strcat (getenv "ACAD") ";'+$work.Replace('\','/')+'"))')+$lines
}
$scr="$work\bootstrap.scr"
[IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
$p=Start-Process "$acad\accoreconsole.exe" -ArgumentList @('/isolate','BHTBootstrap',('"'+$work+'\profile"'),'/s',('"'+$scr+'"'),'/l','en-US') -RedirectStandardOutput "$work\console.log" -RedirectStandardError "$work\stderr.log" -WindowStyle Hidden -PassThru
$deadline=(Get-Date).AddSeconds(60)
try {
 while((Get-Date) -lt $deadline -and !(Test-Path "$work\bootstrap.txt")){Start-Sleep -Milliseconds 250}
 while((Get-Date) -lt $deadline){
  if((Get-Content "$work\bootstrap.txt" -Raw) -match 'DONE'){break}
  Start-Sleep -Milliseconds 250
 }
 $report=Get-Content "$work\bootstrap.txt" -Raw
 Write-Host $report
 Write-Host "Bootstrap QA: $work"
 if($report -notmatch 'DONE' -or $report -match 'FAIL'){throw 'Runtime bootstrap failed'}
} finally {if(!$p.HasExited){Stop-Process -Id $p.Id}}
