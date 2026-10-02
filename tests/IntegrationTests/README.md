# Kiểm thử tích hợp — AutoCAD Core Console (accoreconsole.exe)

Chạy trên máy có AutoCAD 2024 (mặc định `D:\AutoCAD 2024\accoreconsole.exe`, `LISPSYS = 1`).
Thư mục làm việc cố định trong kịch bản: `C:\Users\Le Bao\BHT_TEST_V044\` (đổi `*T-DIR*` trong `t_common.lsp`
và `$w` trong `run_session.ps1` / `run_all.ps1` nếu chạy ở máy khác).

**Không có dữ liệu thật trong repo.** Trước khi chạy cần tự chuẩn bị trong thư mục làm việc:
`thư mục có dấu\BHT-0.6.9.lsp` (bản Lisp cần kiểm, đặt trong đường dẫn có dấu), `bin\BHT.*.dll` (kết quả build),
`data\survey.csv` (+ các file trong data), `anh_da_doi\kmz_out\` (205 JPG + BHT_PHOTO.tsv), `irt\google_sat_18_x.jpg`,
`irt\anh_khac.jpg`, `run\route_src.dwg`, `run\legacy_032_src.dwg` (bản sao bản vẽ làm bằng 0.3.2),
`run\v033_A_out.dwg` (bản vẽ do bộ kiểm 0.3.3 tạo). Kịch bản chỉ làm việc trên **bản sao** bản vẽ.

| Phiên | Nội dung |
|---|---|
| S0 | nạp từ đường dẫn có dấu, BHTTEST, API Lisp, xác nhận bỏ DCL và BHTLOAD khi chưa có plugin |
| A, B, L, R, L2 | hồi quy bộ kiểm 0.3.3 trên BHT-0.6.9.lsp (nhãn, hồ sơ, ký hiệu, thứ tự, ảnh, bản vẽ 0.3.2, lưu / mở lại) |
| N, N2 | bản vẽ 0.3.3 + NETLOAD BHT.Bridge: C# đọc = Lisp, C# tạo/sửa hồ sơ Lisp đọc giống hệt, Application.Invoke, lưu / mở lại |
| NL | bản vẽ 0.3.2 + BHT.Bridge |
| P | NETLOAD BHT.Palette.dll trong Core Console, lệnh chính BTH |
| R5 | Route Model V5 A–O: StartPoint/direction/closed/revision/station break/left-right/offset/legacy + scanner cọc Km chỉ đọc |
| T | ảnh nền IRT dạng lưới 156 tile, layer khóa, tile trên layer 0 trong thư mục `IRT\` |

```powershell
powershell -ExecutionPolicy Bypass -Command "& .\run_all.ps1"            # tất cả
powershell -ExecutionPolicy Bypass -Command "& .\run_all.ps1 -Only N,N2" # một số phiên
```
Kết quả: `run\result_<phiên>.txt` (PASS / FAIL / SKIP / BLOCKED từng mục, dòng `TONG PHIEN`).

## Kiểm tra review từ v0.5.5

Chạy `run_review.ps1` sau khi build DLL vào `build/v<phiên-bản>/bin`. Runner đọc fixture qua `-FixtureRoot`, ghi script/log vào `build/v<phiên-bản>/review` và dùng profile Core Console riêng. Các phiên REVIEW, S0, V5 chạy trên bản vẽ mới; TX chỉ chạy khi có `tdt/tdt_copy.dwg` và không lưu bản vẽ.

`test_REVIEW.lsp` kiểm tra bỏ DCL, giữ tìm kiếm/tình trạng, đọc trạng thái, lệnh BHTTRANGTHAI, BHTTEST và hướng dẫn BHTLOAD khi DLL không nạp được. `run_signs.ps1` kiểm tra biển báo, phông, chèn tự do tương tác và WinForms picker.
## Kiểm tra cọc TDT từ v0.6.9

`TdtStakeProbe.cs` chạy lệnh `BHTSTAKEREGRESSION` trong AutoCAD/Core Console, với BHT.Bridge đã nạp. Ca thử tạo cơ sở dữ liệu riêng trong bộ nhớ và kiểm tra block lồng nhau, phép biến đổi, từng thuộc tính, MTEXT, lý trình sai, lọc offset và quét lặp. Đặt biến môi trường `BHT_QA_OUTPUT` để chỉ định tệp kết quả.

`test_TDT_ROUTE.lsp` chỉ chạy trên **bản sao** bản vẽ khi TDT và BHT đã nạp. Cấu hình `*qa-tdt-source*` (handle tuyến TDT), `*qa-tdt-count*` (số cọc đã đối chiếu) và `*qa-output*` (tệp kết quả). Ca thử kiểm tra tạo/cập nhật cùng handle, vị trí vạch cọc, nguồn không đổi, hình mũi tên qua bước xác nhận/REGEN, UCS xoay, hai đầu tuyến, dọn hình và nạp lại không trùng. Việc xác nhận nạp mốc trong ca thử được mô phỏng trên bản sao.

