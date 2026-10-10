param([Parameter(Mandatory=$true)][string]$RuntimePath,[string]$AcadDir='D:\AutoCAD 2024')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$v=(Get-Content "$root\VERSION" -Raw).Trim()
$work=Join-Path $env:TEMP ('BHT-paths-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$fasDir=Join-Path $work 'FAS có dấu'
New-Item -ItemType Directory $fasDir | Out-Null
Copy-Item -LiteralPath $RuntimePath -Destination $fasDir
# FAS takes precedence when both names are found.
[IO.File]::WriteAllText("$fasDir\BHT-$v.lsp",'(error "WRONG_LSP_SELECTED")')
foreach($phase in @('fas','source')){
 $dir=if($phase -eq 'fas'){$fasDir}else{"$root\src\lisp"}
 $path=if($phase -eq 'fas'){"$dir\BHT-$v.fas"}else{"$dir\BHT-$v.lsp"}
 $lp=$path.Replace('\','/');$ld=$dir.Replace('\','/')
 $lines=@('(setvar "SECURELOAD" 0)',('(setenv "ACAD" (strcat (getenv "ACAD") ";'+$ld+'"))'),
 '(setq *bht-module-root* nil)',
 ('(setq qa-result (vl-catch-all-apply ''load (list "'+$lp+'")))'),
 '(if (vl-catch-all-error-p qa-result) (princ (strcat "\nPATH-FAIL: " (vl-catch-all-error-message qa-result))))',
 ('(if (and (= (type *bht-lsp-file*) ''STR) (= (strcase (vl-string-translate "\\" "/" *bht-lsp-file*)) (strcase "'+$lp+'")) (= (strcase (vl-string-translate "\\" "/" *bht-lsp-dir*)) (strcase "'+$ld+'")) (= (cadr (bht:api-version)) "'+$v+'")) (princ "\nPATH-PASS") (princ "\nPATH-FAIL"))'),
 '_.QUIT','_Y')
 $scr="$work\$phase.scr";$log="$work\$phase.log"
 [IO.File]::WriteAllLines($scr,$lines,[Text.UTF8Encoding]::new($true))
 & "$AcadDir\accoreconsole.exe" /isolate BHTPaths "$work\$phase-profile" /s $scr /l en-US > $log
 $text=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
 if($text -notmatch '(?m)^PATH-PASS' -or $text -match '(?m)^PATH-FAIL|^; error:'){throw "Load path regression: $phase, $log"}
 Write-Host "PASS $phase support-path, path string, directory, API; Bridge not preloaded"
}
Write-Host "Load-path QA: $work"
