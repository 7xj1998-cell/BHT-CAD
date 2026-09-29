# Báo cáo kiểm thử BHT 0.4.6

- Ngày kiểm thử: 2026-09-29
- AutoCAD Core Console 2024: `ACADVER=24.3`, `LISPSYS=1`
- Build x64: `BHT.Core`, `BHT.Bridge`, `BHT.Palette` **PASS**, `FileVersion=0.4.6.0`

## Kết quả

- Core: **62 PASS, 0 FAIL**.
- Integration: **172 PASS, 0 FAIL, 1 BLOCKED**.
- Tổng kiểm thử tự động đạt: **234 PASS, 0 FAIL**.
- BLOCKED: mở DCL bằng Core Console vì môi trường không có UI. Cấu trúc DCL, 42 nút, khóa
  và hàm đích đã PASS kiểm tra tĩnh.

| Phiên | PASS | FAIL | BLOCKED | Phạm vi |
|---|---:|---:|---:|---|
| S0 | 16 | 0 | 1 | Nạp/version, APPLOAD, BHTTEST, DCL tĩnh, API, dấu X |
| A | 41 | 0 | 0 | 526 RTK, 1.574 nhãn, hồ sơ, ảnh, draw order |
| B | 8 | 0 | 0 | SAVEAS và mở lại |
| L | 11 | 0 | 0 | Bản vẽ 0.3.2, bảo toàn nhãn legacy |
| L2 | 2 | 0 | 0 | Mở lại bản vẽ legacy đã nâng cấp |
| R | 30 | 0 | 0 | Tuyến, Km, lý trình, phía, phân đoạn |
| N | 32 | 0 | 0 | Cầu nối Lisp/.NET và Application.Invoke |
| N2 | 5 | 0 | 0 | Mở lại dữ liệu .NET ghi |
| NL | 6 | 0 | 0 | Bridge đọc bản vẽ 0.3.2 |
| P | 2 | 0 | 0 | NETLOAD Palette và đăng ký lệnh |
| D | 7 | 0 | 0 | TDT 9.1, catalog/block/scale biển |
| T | 12 | 0 | 0 | 156 tile IRT và draw order |

## Xác nhận dữ liệu và trình bày điểm

- `BHT-0.4.6.lsp`, assemblies và bundle cùng phiên bản 0.4.6.
- 526 POINT RTK giữ nguyên X/Y/Z; dữ liệu không bị làm tròn.
- Bản vẽ mới: 28/1.574 nhãn còn chồng lấn, giảm từ 620/1.574 ở vị trí legacy.
- Lưới dày 60 điểm: giảm từ 160/160 xuống 21/160 nhãn còn chồng lấn.
- Bản vẽ 0.3.2: lần cập nhật đầu không dời 2.119 nhãn cũ; phiên L đạt 11/11 PASS.

Màu Palette, thanh tab phải và thao tác chuột cần nghiệm thu theo
`CHECKLIST_NGHIEM_THU_0.4.6.md` trong AutoCAD đầy đủ.
