param([Parameter(Mandatory=$true)][string]$PackageRoot,[string]$AcadDir=$env:ACAD_INSTALL_DIR)
$ErrorActionPreference='Stop'
if(!$AcadDir){throw 'Set ACAD_INSTALL_DIR'}
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$v=(Get-Content "$root\VERSION" -Raw).Trim()
$bad=@(Get-ChildItem $PackageRoot -Recurse -File | Where-Object {$_.Extension.ToLowerInvariant() -in '.dwg','.png','.jpg','.jpeg','.ttf','.shx','.fas','.vlx','.pdb'})
if($bad.Count){throw 'Public package includes excluded assets'}
foreach($required in @('LICENSE','COPYING_SCOPE.md','source/BHT-CAD/LICENSE','source/BHT-CAD/src/dotnet/BHT.Palette/BhtPaletteControl.cs')){
 if(!(Test-Path (Join-Path $PackageRoot $required))){throw "Missing corresponding source/license: $required"}
}
$work=Join-Path $env:TEMP ('BHT public '+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $work | Out-Null
Copy-Item -LiteralPath "$PackageRoot\BHT.bundle" -Destination $work -Recurse
$bin="$work\BHT.bundle\Contents\Windows"
function LP($s){$s.Replace('\','/')}
$dwg="$work\roundtrip.dwg"
$boot=@('(setvar "SECURELOAD" 0)',('(setenv "ACAD" (strcat (getenv "ACAD") ";'+(LP $bin)+'"))'),
 '_.NETLOAD',('"'+(LP "$bin\BHT.Bridge.dll")+'"'),('(load "'+(LP "$bin\BHT-$v.lsp")+'")'),
 '(setq public-fails 0)',
 '(defun public-check (name ok) (if (not ok) (setq public-fails (1+ public-fails))) (princ (strcat "\n" (if ok "PASS PUBLIC " "FAIL PUBLIC ") name)))',
 ('(public-check "version" (= (cadr (bht:api-version)) "'+$v+'"))'))
$create=@(
 '(setq pp (entmakex ''((0 . "POINT") (10 10.0 20.0 0.0))))',
 '(bht:pt-write-xdata pp "PUB-PT" "QA" "1" "1" 20.0 10.0 0.0 "BIEN_BAO" "test" "" "")',
 '(bht:obj-create "PUB-OBJ" ''(("nhom" . "BIEN_BAO") ("ma_hieu" . "W.207a") ("so_tru" . "1")) ''("PUB-PT") T)',
 '(public-check "record-created" (= (bht:get (bht:obj-read "PUB-OBJ") "ma_hieu") "W.207a"))',
 '(princ (strcat "\nPUBLIC-FAIL=" (itoa public-fails)))','_.QSAVE',('"'+(LP $dwg)+'"'),'_.QUIT')
$reopen=@(
 '(public-check "record-reopened" (= (bht:get (bht:obj-read "PUB-OBJ") "ma_hieu") "W.207a"))',
 '(public-check "point-position" (equal (cdr (assoc 10 (entget (ssname (ssget "_X" ''((0 . "POINT"))) 0)))) ''(10.0 20.0 0.0) 1e-9))',
 '(princ (strcat "\nPUBLIC-FAIL=" (itoa public-fails)))','_.QUIT','_Y')
foreach($phase in @('create','reopen')){
 $scr="$work\$phase.scr";$log="$work\$phase.log"
 $steps=if($phase -eq 'create'){$create}else{$reopen}
 [IO.File]::WriteAllLines($scr,($boot+$steps),[Text.UTF8Encoding]::new($true))
 $args=@('/isolate','BHTPublicQA',"$work\profile",'/s',$scr,'/l','en-US')
 if($phase -eq 'reopen'){$args+=@('/i',$dwg)}
 & "$AcadDir\accoreconsole.exe" @args > $log
 $text=[IO.File]::ReadAllText($log,[Text.Encoding]::Unicode)
 if($text -notmatch '(?m)^PUBLIC-FAIL=0' -or $text -match '(?m)^FAIL PUBLIC|^; error:'){throw "Public runtime failed: $log"}
 Write-Host "PASS PUBLIC $phase"
}
Write-Host "PASS source/license/excluded-files; QA: $work"
