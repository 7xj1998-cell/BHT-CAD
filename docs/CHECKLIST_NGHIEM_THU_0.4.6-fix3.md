# Checklist nghiệm thu thủ công BHT 0.4.6-fix3 (AutoCAD 2024 đầy đủ, trên BẢN SAO DWG)

AutoCAD Core Console không có giao diện nên các mục sau phải kiểm tra bằng mắt.

## Palette (gõ `BTH`)

- [ ] Tiêu đề Palette: `BHT 0.4.6-fix3 — QUẢN LÝ HIỆN TRẠNG TUYẾN`; trạng thái `BHT Lisp 0.4.6-fix3 đã nạp`; thẻ Tổng quan `PLUGIN: BHT.Palette 0.4.6.3`.
- [ ] Thanh thẻ dọc bên phải có đủ 5 tên: Tổng quan / Điểm RTK / Ảnh hiện trường / Hồ sơ đối tượng / Tuyến & báo cáo (tên dài xuống 2 dòng, không bị cắt).
- [ ] Thẻ thường nền `#065F46` chữ `#D1FAE5`; thẻ đang chọn nền `#D1FAE5` chữ `#065F46` + vạch đậm bên trái; bấm từng thẻ, nội dung đúng thẻ.
- [ ] Rê chuột lên thẻ: hiện mô tả ngắn (tooltip).
- [ ] Bố cục phần nội dung, bảng màu fix2 giữ nguyên.

## Cửa sổ thông báo lỗi

- [ ] Bản vẽ chưa có tuyến: gõ `BHTMOCKM` → cửa sổ **BHT** (biểu tượng cảnh báo) “BHT: chưa có tuyến. Dùng BHTTUYEN trước.”; dòng lệnh cũng in câu này.
- [ ] Gõ `BHTMOCKM` rồi nhấn Esc ở lời nhắc bất kỳ (khi đã có tuyến) → chỉ dòng lệnh “BHT: lệnh bị hủy…”, KHÔNG có cửa sổ.
- [ ] AutoCAD mở KHÔNG qua profile TDT, bản vẽ có tim TDT (proxy): Palette › Tuyến & báo cáo › “1. Lấy hoặc cập nhật tim từ TDT 9.1” › chọn tim → cửa sổ lỗi **BHT** nêu “phiên AutoCAD này chưa nạp TDTSolution 9.1 … mở lại bằng biểu tượng / profile TDTSolution 9.1 (cắm khóa USB TDT …)”; vùng trạng thái Palette nền đỏ “Lệnh BHTTUYENTDT THẤT BẠI. …” (không còn “đã kết thúc. 1 dòng kết quả.”); chỉ 1 cửa sổ (không lặp).
- [ ] `(setq *bht-popup* nil)` rồi lặp lại bước trên → không cửa sổ, dòng lệnh vẫn in lỗi. `(setq *bht-popup* T)` để bật lại.
- [ ] Thẻ Hồ sơ đối tượng: nhập lý trình sai (vd `abc`) › Ghi tay → cửa sổ cảnh báo **BHT** “Lý trình không hợp lệ…”.
- [ ] Thông tin thường (vd Làm mới, Thu phóng) không hiện cửa sổ.

## Tim TDT 9.1 (mở AutoCAD bằng profile TDT 9.1, cắm khóa) — như fix2

- [ ] “1. Lấy hoặc cập nhật tim từ TDT 9.1” › chọn tim TDT: tạo/cập nhật Polyline trên layer `BHT_TUYEN_TDT` trùng toàn bộ tim; tim gốc không bị sửa, điểm RTK không di chuyển.
