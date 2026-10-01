# BHT v0.5.3 — Chèn biển tự do theo hướng và điểm trung gian

Ngày 01/10/2026. DLL 0.5.3.0; Lisp BHT-0.5.3.lsp. Giữ phông VNRomancUpdate.shx/Unicode và thư viện chọn biển của v0.5.2.

## Thao tác

1. Chọn hồ sơ **Biển báo** đã lưu, có điểm RTK. Bấm **Chèn biển tự do** trên thẻ Hồ sơ đối tượng. Có thể gõ `BHTBIENTUDO` rồi nhập ID hồ sơ.
2. Chỉ hướng hoặc nhập góc xoay biển. Enter dùng góc 0 trong UCS hiện tại. Đây là góc đặt block; hướng theo tim tuyến vẫn thuộc chế độ tự động.
3. Chọn từng **điểm trung gian** cho đường dẫn. Gõ `Xoa` để bỏ điểm cuối. Gõ `Dat` hoặc Enter để chuyển sang đặt biển. Có thể bỏ qua toàn bộ điểm trung gian để dùng đường thẳng.
4. Chọn **vị trí đặt biển**. BHT lưu hướng, vị trí và các điểm gấp khúc, rồi chèn/cập nhật block và nhãn. Enter ở bước cuối hoặc Esc trong lúc chọn hủy thao tác; trước khi hoàn tất chọn, hồ sơ và ký hiệu không đổi.
5. **Chèn/Cập nhật ký hiệu** sau đó giữ bố trí tự do. MOVE/ROTATE biển vẫn được giữ; đường dẫn cập nhật đầu cuối, giữ các điểm trung gian.
6. Muốn trở về bố trí theo tuyến: chạy `BHTKYHIEU`, chọn `R`, chọn ký hiệu/nhãn. BHT bỏ cấu hình tự do của hồ sơ đó và tính lại vị trí/hướng theo tuyến.

Đường dẫn có điểm trung gian là LWPOLYLINE trên BHT_DUONG_DAN, theo mặt phẳng XY của điểm khảo sát. Mốc RTK, ảnh, mã biển và liên kết tuyến giữ nguyên. Biển tự do có thể thuộc tuyến để tính lý trình nhưng vị trí trình bày/hướng được chọn riêng. Tự chèn lại cũng áp dụng khi ký hiệu bị xóa nhưng hồ sơ còn cấu hình tự do.

## Kiểm tra

- Build Core/Bridge/Palette 0.5.3.0 thành công; 122 kiểm tra Core đạt.
- 20 kiểm tra hình học/đồng bộ ký hiệu đạt, gồm vị trí/góc tự do, 2 điểm gấp khúc, cập nhật lặp không đổi, MOVE cập nhật đầu cuối, đổi về đường thẳng và trả về tuyến.
- 3 kiểm tra nhập tương tác thật trong AutoCAD Core Console đạt: hủy không ghi hồ sơ; thêm/xóa điểm trung gian; góc 45° trong UCS xoay 30° thành 75° trong WCS.
- 24 kiểm tra phông và các kiểm tra WinForms thư viện biển của v0.5.2 tiếp tục đạt.
- Nguồn và bản ZIP cùng phiên bản 0.5.3; bộ đóng gói vẫn chặn phát hành nội dung đã đổi dưới số phiên bản cũ.

Phần chọn hướng và điểm trung gian tương ứng hành vi TDT do người dùng xác nhận, cũng phù hợp prompt tìm thấy trong RoadSignsUI.arx. Chưa xác nhận toàn bộ giao diện TDT trực tiếp do lỗi ProjectDH.arx khi khởi động ở lần nghiên cứu trước. Bản này bổ sung luồng cho BHT; chưa cài vào phiên AutoCAD đang mở.
