# Báo cáo kiểm thử BHT 0.4.6-fix2

- Ngày kiểm thử: 2026-09-29 (giờ Việt Nam)
- Máy: AutoCAD 2024 Core Console `D:\AutoCAD 2024\accoreconsole.exe`, `ACADVER=24.3`, `LISPSYS=1`
- Lisp kiểm thử: `BHT-0.4.6-fix2.lsp` (bản sao đặt trong thư mục có dấu `thư mục có dấu\BHT-0.4.6-rc.lsp`)
- Thư mục kiểm thử: `C:\Users\Le Bao\BHT_TEST_FIX2\` (bản sao của `BHT_TEST_V044`; chỉ làm việc trên bản sao bản vẽ)
- Build: `scripts\build.ps1 -UseCsc -Test` (csc .NET Framework 4.x, x64, tham chiếu `D:\AutoCAD 2024`) — **PASS**,
  `BHT.Core/BHT.Bridge/BHT.Palette` FileVersion `0.4.6.2`, không cảnh báo.

## Tổng hợp

| Hạng mục | PASS | FAIL | BLOCKED | Ghi chú |
|---|---:|---:|---:|---|
| Core (`BHT.CoreTests`) | 62 | 0 | 0 | gồm C11a/b/c phiên bản 0.4.6-fix2 / 0.4.6.2 |
| Integration (Core Console) | 191 | 0 | 2 | chi tiết bên dưới |
| Kiểm tra tĩnh | 4 | 0 | 0 | xem mục “Kiểm tra tĩnh” |
| Giao diện Palette | – | – | – | **THỦ CÔNG** (Core Console không có UI) |

| Phiên | PASS | FAIL | BLOCKED | Phạm vi |
|---|---:|---:|---:|---|
| S0 | 20 | 0 | 1 | nạp, `*bht-version*`, thông báo APPLOAD, BHTTEST, DCL tĩnh, API, dấu X, block biển báo (T16–T19) |
| A | 41 | 0 | 0 | 526 RTK, nhãn, hồ sơ, ảnh, thứ tự hiển thị |
| B | 8 | 0 | 0 | SAVEAS và mở lại |
| L | 11 | 0 | 0 | bản vẽ 0.3.2 |
| L2 | 2 | 0 | 0 | mở lại bản vẽ legacy |
| R | 30 | 0 | 0 | tuyến, mốc Km, lý trình |
| N | 32 | 0 | 0 | Lisp/.NET, Application.Invoke (`bht:api-version` = OK 0.4.6-fix2) |
| N2 | 5 | 0 | 0 | mở lại dữ liệu .NET ghi |
| NL | 6 | 0 | 0 | Bridge đọc bản vẽ 0.3.2 |
| P | 2 | 0 | 0 | NETLOAD Palette, lệnh BTH trong Core Console |
| D | 7 | 0 | 0 | TDT 9.1: danh mục 412 mã, block W.225, từ chối Polyline thường |
| T | 12 | 0 | 0 | 156 tile IRT |
| F2 (mới) | 11 | 0 | 0 | sửa lỗi `BHTTUYENTDT`, `bht:fn-defined-p`, tự nạp Bridge |
| TX (mới) | 4 | 0 | 1 | tim TDT dạng proxy trên bản sao bản vẽ tuyến thật |

### F2 — `BHTTUYENTDT` (mới)

- F00/F01 PASS: nạp 0.4.6-fix2, thông báo `BHT 0.4.6-fix2 đã nạp thành công.`
- F02 PASS: `bht:fn-defined-p` nhận `SUBR`/`USUBR`, từ chối ký hiệu chưa định nghĩa, biến, `nil`, chuỗi.
- F03 PASS: phiên mới chưa có `BHTTDT91ROUTE`. F03b PASS: `bht:tdt-import-block` không còn lỗi `bad function: BHTTDTBLOCK`.
- F04 PASS: `BHTTUYENTDT` khi không có Bridge không còn lỗi “no function definition”, báo rõ chưa nạp `BHT.Bridge.dll`.
- INFO F05: sau khi chỉ NETLOAD `BHT.Palette.dll` (như Application Bundle), `BHTTDT91ROUTE` **chưa** được đăng ký →
  xác nhận cần cơ chế tự nạp Bridge.
- F06/F08/F08b PASS: `bht:bridge-load` NETLOAD Bridge, `BHTTDT91ROUTE` là `EXRXSUBR`; gọi lại / NETLOAD lần 2 không lỗi.
- F09/F10 PASS: chạy trọn lệnh `BHTTUYENTDT` qua script (chọn Polyline thường tại 5,0): đi hết đường Lisp → Bridge,
  Bridge từ chối “không phải tim tuyến TDTSolution 9.1”, không tạo tuyến/Polyline, Polyline nguồn không đổi.

### BLOCKED

- S0 T05: mở hộp thoại DCL — Core Console không có DCL (như 0.4.6).
- TX X06: `BHTTUYENTDT` trên tim TDT 9.1 “sống”. Thử `arxload TDTObjects.dbx` (chỉ đọc thư mục cài TDT) trong Core
  Console làm tiến trình dừng: `Class 'TdtDbMeasurePointObj' parent named 'TdtDbPointObj' not found`. Cần AutoCAD
  đầy đủ với profile TDT 9.1 và khóa USB. Phần nối nhiều đoạn Line/Arc khi Explode (mới trong Bridge) vì thế chưa được
  chạy với tim TDT thật — nghiệm thu theo `CHECKLIST_NGHIEM_THU_0.4.6-fix2.md`.

## Kiểm tra tĩnh

- PASS: không còn chuỗi `fboundp` trong `src/` và `tests/` (tìm không phân biệt hoa thường).
- PASS: rà mọi lời gọi hàm trong `BHT-0.4.6-fix2.lsp` với danh sách hàm AutoLISP/Visual LISP và các `defun` của BHT:
  hàm ngoài AutoLISP duy nhất ở 0.4.6 là `fboundp` (đã thay). C# chỉ gửi tên hàm `bht:api-*` qua Application.Invoke.
- PASS: ngoặc Lisp cân bằng, 463 biểu thức cấp cao nhất, mọi biểu thức bắt đầu ở cột 0.
- PASS: `BHT-0.4.6-fix2.lsp` là UTF-8 không BOM, xuống dòng LF như 0.4.6; `INSTALL_BHT.cmd` chỉ ASCII + CRLF;
  `INSTALL_BHT.ps1` UTF-8 có BOM.

## Cần nghiệm thu thủ công (AutoCAD 2024 đầy đủ)

Theo `CHECKLIST_NGHIEM_THU_0.4.6-fix2.md`: màu Palette (nền, nút, thanh thẻ phải, danh sách, tiêu đề cột, dòng chọn,
ô nhập, checkbox, vùng trạng thái), tiêu đề `BHT 0.4.6-fix2`, tên nút mới, và `BHTTUYENTDT` trên tim TDT thật.
Thanh cuộn (scrollbar) là điều khiển hệ thống Windows, WinForms không đổi màu được nên vẫn theo giao diện Windows/AutoCAD.
