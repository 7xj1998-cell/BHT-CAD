# Báo cáo kiểm thử BHT 0.4.6-fix3

- Ngày kiểm thử: 2026-09-29, 21:05–21:12 (giờ Việt Nam)
- Máy: AutoCAD 2024 Core Console `D:\AutoCAD 2024\accoreconsole.exe`, `ACADVER=24.3`, `LISPSYS=1`
- Lisp kiểm thử: `BHT-0.4.6-fix3.lsp` (bản sao đặt trong thư mục có dấu `thư mục có dấu\BHT-0.4.6-rc.lsp`)
- Thư mục kiểm thử: `C:\Users\Le Bao\BHT_TEST_FIX2\` (thư mục kiểm thử của fix2, dùng lại; chỉ làm việc trên bản sao bản vẽ)
- Build: `scripts\build.ps1 -UseCsc -Test` (csc .NET Framework 4.x, x64, tham chiếu `D:\AutoCAD 2024`) — **PASS**,
  `BHT.Core/BHT.Bridge/BHT.Palette` FileVersion `0.4.6.3`, không cảnh báo.

## Tổng hợp

| Hạng mục | PASS | FAIL | BLOCKED | Ghi chú |
|---|---:|---:|---:|---|
| Core (`BHT.CoreTests`) | 62 | 0 | 0 | C11a/b/c phiên bản 0.4.6-fix3 / 0.4.6.3 (không nhận Lisp 0.4.6, fix1, fix2) |
| Integration (Core Console) | 213 | 0 | 2 | toàn bộ 15 phiên chạy lại bằng `run_all.ps1` |
| Thanh thẻ Palette (dựng hình ngoài AutoCAD) | 1 | 0 | 0 | xem mục “Thanh thẻ” |
| Kiểm tra tĩnh | 4 | 0 | 0 | xem mục “Kiểm tra tĩnh” |
| Giao diện trong AutoCAD, cửa sổ thông báo thật | – | – | – | **THỦ CÔNG** (Core Console không có UI) |

| Phiên | PASS | FAIL | BLOCKED | Phạm vi |
|---|---:|---:|---:|---|
| S0 | 20 | 0 | 1 | nạp, phiên bản, APPLOAD, BHTTEST, DCL tĩnh, 15 hàm API (thêm `bht:api-problems`), dấu X, block biển báo |
| A | 41 | 0 | 0 | 526 RTK, nhãn, hồ sơ, ảnh, thứ tự hiển thị |
| B | 8 | 0 | 0 | SAVEAS và mở lại |
| L | 11 | 0 | 0 | bản vẽ 0.3.2 |
| L2 | 2 | 0 | 0 | mở lại bản vẽ legacy |
| R | 30 | 0 | 0 | tuyến, mốc Km, lý trình |
| N | 32 | 0 | 0 | Lisp/.NET, Application.Invoke (`bht:api-version` = OK 0.4.6-fix3), 15 hàm API |
| N2 | 5 | 0 | 0 | mở lại dữ liệu .NET ghi |
| NL | 6 | 0 | 0 | Bridge đọc bản vẽ 0.3.2 |
| P | 2 | 0 | 0 | NETLOAD Palette, lệnh BTH trong Core Console |
| D | 7 | 0 | 0 | TDT 9.1: danh mục 412 mã, block W.225, từ chối Polyline thường |
| T | 12 | 0 | 0 | 156 tile IRT |
| F2 | 12 | 0 | 0 | `BHTTUYENTDT` (fix2) + F11 mới: lỗi Bridge được ghi cho Palette (`ERROR|…`) |
| F3 (mới) | 20 | 0 | 0 | cửa sổ thông báo lỗi / cảnh báo, tự tắt trong Core Console và script |
| TX | 5 | 0 | 1 | tim TDT dạng proxy trên bản sao bản vẽ tuyến thật + X04b thông báo mới |

### F3 — cửa sổ thông báo (mới)

- F3-00 PASS: nạp 0.4.6-fix3, `BHT 0.4.6-fix3 đã nạp thành công.`
- F3-01 PASS: Core Console được nhận ra vì `(vlax-get-acad-object)` trả `nil` (lưu ý: `(getvar "PROGRAM")` trong Core
  Console vẫn là `"acad"`, không dùng để phân biệt được — đã kiểm chứng).
- F3-02 PASS: khi chạy script `CMDACTIVE` = 4 → `bht:popup-enabled-p` = nil (không cửa sổ).
- F3-03/04 PASS: `bht:err` / `bht:warn` in dòng lệnh, giữ cho Palette, ghi `ERROR|…` / `WARN|…`.
- F3-05/06 PASS: `bht:api-problems` PEEK/DRAIN đúng thứ tự; `bht:api-messages DRAIN` xóa luôn lỗi cũ.
- F3-07/08 PASS: `*error*` của BHT: lỗi thật → `BHT lỗi: …` + ERROR; hủy lệnh → chỉ “lệnh bị hủy”, không ghi lỗi.
- F3-09…F3-13 PASS (giả lập AutoCAD đầy đủ bằng `BHTPOPUP` giả): lỗi → cửa sổ ERROR, cảnh báo → WARN, nội dung nguyên văn;
  `*Cancel*` / “Function cancelled” / thông tin thường → không cửa sổ; `*error*` lỗi thật → cửa sổ;
  đường thật `bht:ask-route` khi chưa có tuyến → cửa sổ WARN “BHT: chưa có tuyến. Dùng BHTTUYEN trước.”;
  `(setq *bht-popup* nil)` → không cửa sổ, vẫn in dòng lệnh.
- F3-14 PASS: không có `BHTPOPUP` (Palette chưa nạp) → dùng `alert` dự phòng; Core Console tự trả lời OK, không treo.
- F3-15 PASS: khôi phục hàm gốc → Core Console lại tắt cửa sổ.
- F3-16/17/18 PASS: sau NETLOAD `BHT.Palette.dll`, `BHTPOPUP` là `EXRXSUBR`, trả `"SKIP"` trong Core Console
  (không mở MessageBox, không treo), `bht:warn` qua `BHTPOPUP` thật không lỗi và không rơi về `alert`.
- F3-19 PASS: `bht:api-problems` nằm trong danh sách hàm API Palette gọi được.

### Không có cửa sổ nào chặn Core Console

Rà console của cả 15 phiên: chỉ có **1** hộp `MessageBox` (tự trả lời OK) — đó là F3-14, nơi kiểm thử cố ý ép bật cửa
sổ để thử `alert` dự phòng. Các phiên còn lại: 0. Không phiên nào hết giờ (TIMEOUT); cả 15 phiên ghi dòng TONG.

### TX — tim TDT proxy

- X04/X05 PASS: Bridge từ chối tim proxy, không tạo Polyline, không sửa đối tượng gốc.
- X04b PASS: thông báo mới: “không nhận ra tim tuyến TDT (đối tượng đang hiển thị dạng proxy - ACAD_PROXY_ENTITY/
  AcDbZombieEntity vì phiên AutoCAD này chưa nạp TDTSolution 9.1). Cách xử lý: lưu và đóng AutoCAD, mở lại bằng biểu
  tượng / profile TDTSolution 9.1 (cắm khóa USB TDT nếu phần mềm yêu cầu), mở bản vẽ rồi chạy lại "1. Lấy hoặc cập nhật
  tim từ TDT 9.1" (lệnh BHTTUYENTDT). BHT không sửa tim TDT gốc.”

### BLOCKED

- S0 T05: mở hộp thoại DCL — Core Console không có DCL (như 0.4.6).
- TX X06: `BHTTUYENTDT` trên tim TDT 9.1 “sống” — Core Console không nạp được module TDT (`TDTObjects.dbx`); cần
  AutoCAD đầy đủ với profile TDT 9.1 và khóa USB.

## Thanh thẻ Palette

- Nguyên nhân ô trống (tái hiện được): `ItemSize(34, 86)` với thẻ dọc cho ô thẻ **86 × 34 px**; mã fix2 xoay chữ −90° rồi
  vẽ bằng `TextRenderer` (GDI) vào ô 34 × 86 — GDI bỏ qua phép xoay của `Graphics`, chữ bị vẽ lệch/cắt mất.
- PASS (dựng hình ngoài AutoCAD): biên dịch `PaletteTheme.cs` với một form thử (WinForms, không AutoCAD), chụp bằng
  `DrawToBitmap`: bản fix2 → 5 ô trống (`docs/evidence/fix3_the_doc_truoc_fix2.png`); bản fix3 → đủ 5 tên, chữ ngang,
  tên dài xuống 2 dòng (`docs/evidence/fix3_the_doc_sau.png`). Kích thước ô thẻ 86 × 38 px, vùng nội dung giữ 320 px.
- Chưa kiểm trong AutoCAD thật (tooltip, chọn thẻ, DPI) → thủ công.

## Kiểm tra tĩnh

- PASS: không còn chuỗi `fboundp` trong `src/` và `tests/`.
- PASS: ngoặc Lisp cân bằng, 473 biểu thức cấp cao nhất, mọi biểu thức bắt đầu ở cột 0; rà hàm: không có hàm ngoài
  AutoLISP/Visual LISP mới (chỉ thêm `defun` của BHT: `bht:core-console-p`, `bht:popup-enabled-p`, `bht:popup`,
  `bht:problem-add`, `bht:err`, `bht:warn`, `bht:api-problems`; hàm .NET mới `BHTPOPUP` được kiểm tra tồn tại trước khi gọi).
- PASS: `BHT-0.4.6-fix3.lsp` UTF-8 không BOM, LF như 0.4.6; `INSTALL_BHT.cmd` chỉ ASCII + CRLF; `INSTALL_BHT.ps1` UTF-8 có BOM.
- PASS: `PackageContents.xml` `AppVersion="0.4.6.3"`, `ModuleName=…BHT-0.4.6-fix3.lsp`, ProductCode/UpgradeCode giữ nguyên.

## Cần nghiệm thu thủ công (AutoCAD 2024 đầy đủ)

Theo `CHECKLIST_NGHIEM_THU_0.4.6-fix3.md`: tên thẻ và màu thẻ, tooltip; cửa sổ **BHT** khi lỗi (proxy TDT, chưa có
tuyến, dữ liệu nhập sai), không cửa sổ khi Esc; trạng thái Palette “THẤT BẠI” nền đỏ sau lỗi `BHTTUYENTDT`, chỉ một cửa
sổ cho một lỗi; `BHTTUYENTDT` trên tim TDT thật.
