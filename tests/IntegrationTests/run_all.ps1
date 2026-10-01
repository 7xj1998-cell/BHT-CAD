# BHT 0.6.6 - chay toan bo kiem thu Core Console
#  Hoi quy 0.3.3 tren BHT-0.6.6.lsp: S0, A, B, L, R, L2
#  Plugin .NET: N (ban ve 0.3.3 + BHT.Bridge), N2 (mo lai), NL (ban ve 0.3.2 + BHT.Bridge), P (thu NETLOAD BHT.Palette)
# Can: $w\thu muc co dau\BHT-0.6.6.lsp, $w\bin\BHT.*.dll, $w\data\survey.csv, $w\run\route_src.dwg,
#      $w\run\legacy_032_src.dwg, $w\run\v033_A_out.dwg (A_out.dwg cua bo kiem thu 0.3.3), $w\anh_da_doi\kmz_out, $w\irt\*.jpg
param([string[]]$Only = @())
$w = 'C:\Users\Le Bao\BHT_TEST_V044'
Set-Location $w
function Want($n) { return ($Only.Count -eq 0) -or ($Only -contains $n) }
$r = "C:/Users/Le Bao/BHT_TEST_V044/run/"
function Inv([string]$fn, [string]$arg, [string]$file) { return @('BHTNETLISP', $fn, $arg, ($r + $file)) }
if (Want 'S0') { & .\run_session.ps1 -Name test_S0 -TimeoutSec 300 }
if (Want 'A') {
  New-Item -ItemType Directory "$w\khac" -Force | Out-Null; Copy-Item "$w\irt\anh_khac.jpg" "$w\khac\anh_khac.jpg" -Force
  Copy-Item run\route_src.dwg run\A_in.dwg -Force; Remove-Item run\A_out.dwg -ErrorAction SilentlyContinue
  & .\run_session.ps1 -Name test_A -Dwg "$w\run\A_in.dwg" -TimeoutSec 1200 -After @('_.SAVEAS','2018',"`"$w\run\A_out.dwg`"") -Saved
}
if (Want 'B') { Copy-Item run\A_out.dwg run\A_out_mo_lai.dwg -Force; & .\run_session.ps1 -Name test_B -Dwg "$w\run\A_out_mo_lai.dwg" -TimeoutSec 900 }
if (Want 'L') {
  Copy-Item run\legacy_032_src.dwg run\L_in.dwg -Force; Remove-Item run\L_out.dwg -ErrorAction SilentlyContinue
  & .\run_session.ps1 -Name test_L -Dwg "$w\run\L_in.dwg" -TimeoutSec 1200 -After @('_.SAVEAS','2018',"`"$w\run\L_out.dwg`"") -Saved
}
if (Want 'R') { Copy-Item run\route_src.dwg run\R_in.dwg -Force; & .\run_session.ps1 -Name test_R -Dwg "$w\run\R_in.dwg" -TimeoutSec 1200 }
if (Want 'L2') { Copy-Item run\L_out.dwg run\L_out_mo_lai.dwg -Force; & .\run_session.ps1 -Name test_L2 -Dwg "$w\run\L_out_mo_lai.dwg" -TimeoutSec 900 }
if (Want 'N') {
  Copy-Item run\v033_A_out.dwg run\N_in.dwg -Force; Remove-Item run\N_out.dwg -ErrorAction SilentlyContinue
  Remove-Item run\N_*.txt -ErrorAction SilentlyContinue
  $after = @('(t-n-prep-invoke)')
  $after += Inv 'bht:api-version' '.' 'N_inv_version.txt'
  $after += Inv 'bht:api-info-object' '@USERS1' 'N_inv_info.txt'
  $after += Inv 'bht:api-symbol-sync' '@USERS1' 'N_inv_sym.txt'
  $after += Inv 'bht:api-symbol-sync' '@USERS1' 'N_inv_sym2.txt'
  $after += Inv 'bht:api-photo-path' '@USERS2' 'N_inv_path.txt'
  $after += Inv 'bht:api-label-sync' '@USERS3' 'N_inv_lbl.txt'
  $after += Inv 'bht:api-check' '.' 'N_inv_check.txt'
  $after += Inv 'bht:api-draworder' '.' 'N_inv_dro.txt'
  $after += Inv 'bht:api-info-photo' '@USERS2' 'N_inv_iph.txt'
  $after += Inv 'bht:khong-co-ham' '.' 'N_inv_bad.txt'
  $after += @('BHTNETPING', 'BHTTHUTUVE', '', '(t-n-check-invoke)', '(t-n-final)', '_.SAVEAS', '2018', "`"$w\run\N_out.dwg`"")
  & .\run_session.ps1 -Name test_N -Dwg "$w\run\N_in.dwg" -TimeoutSec 1500 -After $after -Saved
}
if (Want 'N2') { Copy-Item run\N_out.dwg run\N_out_mo_lai.dwg -Force; & .\run_session.ps1 -Name test_N2 -Dwg "$w\run\N_out_mo_lai.dwg" -TimeoutSec 900 }
if (Want 'NL') { Copy-Item run\legacy_032_src.dwg run\NL_in.dwg -Force; & .\run_session.ps1 -Name test_NL -Dwg "$w\run\NL_in.dwg" -TimeoutSec 900 }
if (Want 'P') { & .\run_session.ps1 -Name test_P -TimeoutSec 300 -After @('BTH', '(t-p-after)') }
if (Want 'D') { & .\run_session.ps1 -Name test_D -TimeoutSec 600 }
if ((Want 'TX') -and (Test-Path "$w\tdt\tdt_copy.dwg")) { Copy-Item "$w\tdt\tdt_copy.dwg" run\TX_in.dwg -Force; & .\run_session.ps1 -Name test_TX -Dwg "$w\run\TX_in.dwg" -TimeoutSec 300 -Profile 'TDT2022' }
if (Want 'F2') { & .\run_session.ps1 -Name test_F2 -TimeoutSec 300 -After @('BHTTUYENTDT', '5,0', 'TUYENF2', '100', '0', '(t-f2-after)') }
if (Want 'F3') { & .\run_session.ps1 -Name test_F3 -TimeoutSec 300 }
if (Want 'V5') { & .\run_session.ps1 -Name test_V5 -TimeoutSec 600 }
if (Want 'R5') { & .\run_session.ps1 -Name test_R5 -TimeoutSec 600 }
Get-ChildItem run\result_*.txt | % { Get-Content -Encoding UTF8 $_.FullName | Select-String '^TONG' }
if (Want 'T') {
  $td = "$w\nen\tiles"; New-Item -ItemType Directory $td -Force | Out-Null
  for ($r2 = 0; $r2 -lt 12; $r2++) { for ($c2 = 0; $c2 -lt 12; $c2++) { Copy-Item "$w\irt\google_sat_18_x.jpg" "$td\L18_${r2}_${c2}.jpg" -Force } }
  for ($c2 = 0; $c2 -lt 12; $c2++) { Copy-Item "$w\irt\google_sat_18_x.jpg" "$td\L18_K_${c2}.jpg" -Force }
  New-Item -ItemType Directory "$w\gia_irt\IRT\sat\18","$w\khac" -Force | Out-Null
  Copy-Item "$w\irt\google_sat_18_x.jpg" "$w\gia_irt\IRT\sat\18\t_1.jpg" -Force
  Copy-Item "$w\irt\anh_khac.jpg" "$w\khac\anh_khac_0.jpg" -Force
  & .\run_session.ps1 -Name test_T -TimeoutSec 900
  Get-Content -Encoding UTF8 run\result_T.txt | Select-String '^TONG'
}
