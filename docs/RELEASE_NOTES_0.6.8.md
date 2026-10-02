# BHT v0.6.8 — 2026-10-02

Đã rà soát mã nguồn từ v0.6.7, tinh giản các lệnh trùng và kiểm tra luồng chèn biển báo.

## Thay đổi

- Đã bỏ 16 bí danh dư. Mở bảng bằng `BHT` hoặc `BTH`; xem [lệnh thay thế](COMMANDS_0.6.8.md) để cập nhật script CAD. Các lệnh `BHTNET*` được giữ để kiểm thử và chẩn đoán.
- Đã chặn mã tốc độ sai như `P.127-800` trước khi chèn, tránh vẽ biển tốc độ mặc định. Tốc độ hợp lệ từ 5 đến 130 km/h. Các cách ghi cũ `P.127 - 20`, `P.127/40`, `P12780` được chuẩn hoá.
- Đã bỏ khớp chuỗi con tuỳ ý trong danh mục và block tích hợp. Mã thiếu hậu tố biến thể vẫn chọn được biến thể đầu tiên; mã lạ dùng ký hiệu chưa xác định. Giữ mã ghép cũ `W.239a + S.509a`.
- Đã kiểm tra mọi mã mặt biển trước khi xác nhận, giới hạn 20 mặt/trụ; không chấp nhận cụm rỗng hay tên block thiếu.
- Đã kiểm tra giá trị mét lớn hơn 0, tối đa 100000, tối đa 3 chữ số thập phân. Giá trị quá chính xác được báo lỗi, không làm tròn âm thầm về 0 hoặc một số khác.
- Đã bỏ một control không sử dụng, loại tệp biên dịch khỏi phần source và bỏ hai thư mục ảnh lặp trong gói. Ảnh biển báo được nhúng trong DLL; phần source vẫn chứa ảnh để build lại.
- Đã đồng bộ số phiên bản và tên ZIP trong hướng dẫn cài đặt; thêm kiểm tra để phát hiện tài liệu ghi sai phiên bản.

## Kiểm thử

- Build ba DLL Core, Bridge, Palette bằng tham chiếu AutoCAD 2024: không có lỗi/cảnh báo compiler; 139 kiểm tra Core đạt.
- CAD Core Console: kiểm tra thư viện, Hatch, chiều cao chuẩn, số tốc độ/mét, cụm nhiều mặt, thứ tự mặt và cập nhật lặp qua API Palette đạt.
- WinForms: 376 mã có ảnh thật, không có ảnh thiếu; tìm/lọc, nhập tốc độ/mét, huỷ, thứ tự mặt và giới hạn 20 mặt đạt.
- Chế độ không có TDT: danh mục dự phòng, block tích hợp, Unicode/TCVN3 và bộ chọn đạt.
- Hồi quy REVIEW: 10 ca đạt; S0: 20 ca đạt; V5: 21 ca đạt. Bộ cài: 7 kiểm tra đạt.
- Chưa kiểm tra thao tác chuột trực tiếp trên Palette trong AutoCAD. TX chưa chạy vì thiếu bản vẽ mẫu proxy TDT; không suy ra TX đạt từ các kiểm tra khác.

## Cài đặt

Đóng toàn bộ AutoCAD, giải nén đầy đủ `BHT-0.6.8.zip`, chạy `INSTALL_BHT.cmd`, mở CAD và gõ `BHT` hoặc `BTH`. Kiểm tra tiêu đề 0.6.8. Nếu script cũ dùng bí danh đã bỏ, thay bằng lệnh chính theo bảng lệnh.
