param([Parameter(Mandatory=$true)][string]$PackageRoot,[string]$AcadDir='D:\AutoCAD 2024')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$v=(Get-Content (Join-Path $root 'VERSION') -Raw).Trim()
# Fresh runtime-only location outside the source tree; no source fallback.
$work=Join-Path $env:TEMP ('BHT-runtime-qa-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $work | Out-Null
$bundle=Join-Path $work 'BHT.bundle'
Copy-Item -LiteralPath (Join-Path $PackageRoot 'BHT.bundle') -Destination $bundle -Recurse
$files=Get-ChildItem -LiteralPath $bundle -Recurse -File
if($files | Where-Object {$_.Extension -in '.lsp','.cs','.pdb' -or $_.Name -match 'Mapping|obfuscar'}){throw 'Runtime includes source/debug files'}
$bin=Join-Path $bundle 'Contents\Windows'
function LP($s){$s.Replace('\','/')}
$dwg=Join-Path $work 'roundtrip.dwg'
$boot=@('(setvar "SECURELOAD" 0)','_.NETLOAD',('"'+(LP "$bin\BHT.Bridge.dll")+'"'),
 '(setq *bht-no-launch* T *bht-module-root* nil)',
 ('(load "'+(LP "$bin\BHT-$v.fas")+'")'),
 '(setq package-fails 0)',
 '(defun package-check (name ok) (if (not ok) (setq package-fails (1+ package-fails))) (princ (strcat "\n" (if ok "PASS PACKAGE " "FAIL PACKAGE ") name)))',
 ('(package-check "runtime-directory" (= (strcase (vl-string-translate "\\" "/" *bht-lsp-dir*)) (strcase "'+(LP $bin)+'")))'),
 ('(package-check "version-api" (= (cadr (bht:api-version)) "'+$v+'"))'))
$create=@(
 '(setq pp (entmakex ''((0 . "POINT") (10 10.0 20.0 0.0))))',
 '(bht:pt-write-xdata pp "PACK-PT" "QA" "1" "1" 20.0 10.0 0.0 "BIEN_BAO" "test" "" "")',
 '(bht:obj-create "PACK-OBJ" ''(("nhom" . "BIEN_BAO") ("ma_hieu" . "W.207a") ("so_tru" . "1")) ''("PACK-PT") T)',
 '(bht:kh-free-apply "PACK-OBJ" ''(12.0 22.0 0.0) 0.7 nil)',
 '(package-check "native-sign-insert" (assoc "PACK-OBJ" (bht:tagged-pairs "INSERT" "BHT_KH" 1)))',
 '(princ (strcat "\nPACKAGE-FAIL=" (itoa package-fails)))',
 '_.QSAVE',('"'+(LP $dwg)+'"'),'_.QUIT')
$reopen=@(
 '(package-check "saved-record" (= (bht:get (bht:obj-read "PACK-OBJ") "ma_hieu") "W.207a"))',
 '(bht:symbol-sync ''("PACK-OBJ"))',
 '(package-check "update-after-reopen" (assoc "PACK-OBJ" (bht:tagged-pairs "INSERT" "BHT_KH" 1)))',
 '(princ (strcat "\nPACKAGE-FAIL=" (itoa package-fails)))','_.QUIT','_Y')
foreach($phase in @('create','reopen')){
 $scr=Join-Path $work "$phase.scr";$log=Join-Path $work "$phase.log"
 $steps=if($phase -eq 'create'){$create}else{$reopen}
 [IO.File]::WriteAllLines($scr,($boot+$steps),[Text.UTF8Encoding]::new($true))
 $args=@('/isolate','BHTRuntimeQA',(Join-Path $work 'profile'),'/s',$scr,'/l','en-US')
 if($phase -eq 'reopen'){$args+=@('/i',$dwg)}
 & "$AcadDir\accoreconsole.exe" @args > $log
 $text=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
 if($text -notmatch '(?m)^PACKAGE-FAIL=0' -or $text -match '(?m)^FAIL PACKAGE|; error:'){throw "Runtime QA failed: $log"}
 if(!(Test-Path $dwg)){throw 'Drawing not saved'}
}
Write-Host "PASS standalone FAS runtime, Unicode API, native sign, save/reopen: $work"
