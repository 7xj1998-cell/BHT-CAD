# Kiểm thử tích hợp — AutoCAD Core Console (accoreconsole.exe)

Chạy trên máy có AutoCAD 2024 (mặc định `D:\AutoCAD 2024\accoreconsole.exe`, `LISPSYS = 1`).
Thư mục làm việc cố định trong kịch bản: `C:\Users\Le Bao\BHT_TEST_V040\` (đổi `*T-DIR*` trong `t_common.lsp`
và `$w` trong `run_session.ps1` / `run_all.ps1` nếu chạy ở máy khác).

**Không có dữ liệu thật trong repo.** Trước khi chạy cần tự chuẩn bị trong thư mục làm việc:
`thư mục có dấu\BHT-0.4.0-rc.lsp` (bản Lisp cần kiểm, đặt trong đường dẫn có dấu), `bin\BHT.*.dll` (kết quả build),
`data\survey.csv` (+ các file trong data), `anh_da_doi\kmz_out\` (205 JPG + BHT_PHOTO.tsv), `irt\google_sat_18_x.jpg`,
`irt\anh_khac.jpg`, `run\route_src.dwg`, `run\legacy_032_src.dwg` (bản sao bản vẽ làm bằng 0.3.2),
`run\v033_A_out.dwg` (bản vẽ do bộ kiểm 0.3.3 tạo). Kịch bản chỉ làm việc trên **bản sao** bản vẽ.

| Phiên | Nội dung |
|---|---|
| S0 | nạp từ đường dẫn có dấu, BHTTEST, API Lisp, BHTPALETTE khi chưa có plugin |
| A, B, L, R, L2 | hồi quy bộ kiểm 0.3.3 trên BHT-0.4.0.lsp (nhãn, hồ sơ, ký hiệu, thứ tự, ảnh, bản vẽ 0.3.2, lưu / mở lại) |
| N, N2 | bản vẽ 0.3.3 + NETLOAD BHT.Bridge: C# đọc = Lisp, C# tạo/sửa hồ sơ Lisp đọc giống hệt, Application.Invoke, lưu / mở lại |
| NL | bản vẽ 0.3.2 + BHT.Bridge |
| P | NETLOAD BHT.Palette.dll trong Core Console, lệnh BHTPALETTE |
| T | ảnh nền IRT dạng lưới 156 tile, layer khóa, tile trên layer 0 trong thư mục `IRT\` |

```powershell
powershell -ExecutionPolicy Bypass -Command "& .\run_all.ps1"            # tất cả
powershell -ExecutionPolicy Bypass -Command "& .\run_all.ps1 -Only N,N2" # một số phiên
```
Kết quả: `run\result_<phiên>.txt` (PASS / FAIL / SKIP / BLOCKED từng mục, dòng `TONG PHIEN`).
