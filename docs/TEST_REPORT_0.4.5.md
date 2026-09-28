# Báo cáo kiểm thử BHT 0.4.5

- Ngày kiểm thử: 2026-09-29
- AutoCAD Core Console: 2024 (`ACADVER=24.3`)
- Hệ Lisp: `LISPSYS=1`

## Kết quả phát hành

- Build `BHT.Core`, `BHT.Bridge`, `BHT.Palette`: **PASS**; ba DLL có `FileVersion=0.4.5.0`.
- Logic thuần .NET: **62 PASS, 0 FAIL**.
- Integration trên AutoCAD Core Console: **172 PASS, 0 FAIL, 1 BLOCKED, 0 SKIP**.
- Tổng kiểm thử tự động đạt: **234 PASS, 0 FAIL**.
- Mục BLOCKED: mở cửa sổ DCL bằng `load_dialog/new_dialog/start_dialog`. Core Console không có UI nên không thể xác nhận thao tác thật; cấu trúc DCL, 42 nút, khóa và hàm đích đã PASS kiểm tra tĩnh. Mục này nằm trong checklist nghiệm thu AutoCAD đầy đủ.

## Kết quả từng phiên Integration

| Phiên | PASS | FAIL | BLOCKED | Nội dung chính |
|---|---:|---:|---:|---|
| S0 | 16 | 0 | 1 | Nạp/version, thông báo APPLOAD, BHTTEST, DCL tĩnh, API, POINT mặc định, DWG block tùy chọn |
| A | 41 | 0 | 0 | 526 RTK, nhãn, hồ sơ, ký hiệu/leader, 205 ảnh, draw order, không dời RTK |
| B | 8 | 0 | 0 | Mở lại bản vẽ đã SAVEAS, dữ liệu/vị trí/trạng thái giữ nguyên |
| L | 11 | 0 | 0 | Nâng cấp bản vẽ 0.3.2, Model/Layout, sắp nhãn, BHTKT |
| L2 | 2 | 0 | 0 | Mở lại bản vẽ 0.3.2 đã nâng cấp |
| R | 30 | 0 | 0 | Tuyến, mốc Km, lý trình, phía và phân đoạn |
| N | 32 | 0 | 0 | Cầu nối Lisp/.NET, đọc/ghi chéo, hồ sơ/ảnh, Application.Invoke |
| N2 | 5 | 0 | 0 | Mở lại dữ liệu do .NET ghi |
| NL | 6 | 0 | 0 | Bridge đọc bản vẽ 0.3.2 |
| P | 2 | 0 | 0 | NETLOAD Palette và đăng ký lệnh trong Core Console |
| D | 7 | 0 | 0 | TDTSolution 9.1 thường, 412 mã, block W.225, scale 0.2/cột 0.6, từ chối Polyline thường |
| T | 12 | 0 | 0 | Lưới 156 tile IRT, layer khóa, draw order, không sửa dữ liệu ảnh/POINT |

## Phạm vi đã xác nhận

- `BHT-0.4.5.lsp`, Core, Bridge, Palette và Application Bundle dùng cùng phiên bản 0.4.5; thông báo APPLOAD là `BHT 0.4.5 đã nạp thành công.`
- 526 POINT RTK giữ nguyên X/Y/Z sau các thao tác nhãn, hồ sơ, ký hiệu, ảnh, tuyến và draw order; không làm tròn tọa độ.
- `BHTTUYENTDT`/`Tdt91Interop` chỉ nhận đối tượng tim TDT; Polyline thường bị từ chối ở giao diện này.
- Phát hiện đúng TDTSolution 9.1 bản thường tại `C:\Program Files (x86)\TDT Solution 2022\`, đọc catalog 412 mã và nạp lại block không tạo định nghĩa trùng.
- Block TDT W.225 được clone từ nguồn TDT, wrapper dùng scale mặt `0.2` và cột cao `0.6` đơn vị.
- Báo cáo Excel có đủ thành phần XLSX, giữ tiếng Việt có dấu và mọi phần XML đều parse hợp lệ.
- Bản vẽ BHT 0.3.2/0.3.3 mở, cập nhật, SAVEAS và mở lại mà không mất bản ghi hoặc đổi tọa độ RTK.

## Việc cần nghiệm thu bằng AutoCAD đầy đủ

Thực hiện [CHECKLIST_NGHIEM_THU_0.4.5.md](CHECKLIST_NGHIEM_THU_0.4.5.md) để xác nhận Palette, DCL, hộp thoại báo cáo, chọn tim TDT và xuất/mở Excel bằng thao tác chuột thật.
