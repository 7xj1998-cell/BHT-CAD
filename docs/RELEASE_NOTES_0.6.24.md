# BHT 0.6.24 — Tỷ lệ dấu X và nhãn RTK

Trong thẻ **Điểm RTK**, nút cũ **Đặt dấu X (cỡ 1) + sắp lại nhãn** được thay bằng **Tỷ lệ ký hiệu và nhãn RTK…**. Hai ô cho chọn riêng tỷ lệ X và tỷ lệ nhãn; có mức gợi ý, nhập tùy chỉnh, xem kích thước thực tế và đưa về chuẩn 1:1.

Mức `1` là dấu X cỡ `1` đơn vị bản vẽ và chữ cao `0,5` đơn vị. Giá trị từ `0,01` đến `100`, tối đa 3 chữ số thập phân, nhận dấu phẩy hoặc dấu chấm. Tỷ lệ lưu theo bản vẽ; hủy hộp thoại giữ cài đặt cũ. Đổi tỷ lệ giữ vị trí nhãn và dữ liệu khảo sát.

**Cập nhật nhãn RTK** là nút riêng để cập nhật nội dung, tạo nhãn thiếu và sắp lại nhãn tự động. Chọn điểm để sắp nhãn của chúng hoặc bỏ chọn để sắp toàn bộ; nhãn dời tay giữ vị trí. Nhãn mới dùng cỡ đã lưu. Danh sách giữ các điểm đang chọn và dòng đầu đang xem sau làm mới.

Cỡ dấu X áp dụng chung cho POINT trong bản vẽ theo `PDMODE/PDSIZE` của AutoCAD. Cỡ chữ chỉ áp dụng TEXT mang XData `BHT_NHAN`; ký hiệu và nhãn biển báo dùng nút tỷ lệ riêng.

## Cài đặt

Gửi **BHT-Setup-0.6.24.exe**, đóng AutoCAD rồi mở file để cài. Cài xong hiện thông báo thành công và chỉ còn **Hoàn tất**. Gói đầy đủ **BHT-0.6.24.zip** kèm mã nguồn vẫn có để bàn giao.

## Kiểm tra

- 171 kiểm thử Core và 131 kiểm tra giao diện đạt.
- Hồi quy AutoCAD 2024 cho ký hiệu, nhãn, Unicode và lệnh G/T đạt; tỷ lệ RTK kiểm tra độc lập X/chữ, giữ tọa độ/vị trí/XData, dữ liệu không hợp lệ, gọi lặp, độ chính xác và nhãn mới.
- Bộ cài được kiểm tra riêng về sao lưu/khôi phục, giao diện hoàn tất và tính toàn vẹn file EXE.

Chưa cài đè lên phiên AutoCAD người dùng đang mở. Bundle hỗ trợ AutoCAD 2021–2024 trên Windows 64-bit, kiểm thử trực tiếp bằng AutoCAD 2024.
