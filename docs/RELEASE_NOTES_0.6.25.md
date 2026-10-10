# BHT 0.6.25 — Hai điểm RTK nối vào hai chân biển

Hồ sơ có **Số trụ/chân = 2** nay vẽ đủ hai trụ và hai dấu chân. Gắn hai điểm RTK đo tại hai chân vào cùng hồ sơ để mỗi điểm có một đường nối riêng vào chân tương ứng của ký hiệu. Đường nối dùng tọa độ khảo sát thực tế; điểm RTK giữ nguyên.

## Thao tác

1. Chọn hồ sơ và đặt **Số trụ/chân = 2**.
2. Bấm **Thêm điểm CAD…** để gắn điểm đo chân còn thiếu.
3. Bấm **Lưu hồ sơ**, rồi **Chèn / cập nhật** hoặc **Đặt ký hiệu…**.

Nếu mới gắn một điểm, hồ sơ hiện nhắc **Thiếu 1 điểm chân RTK**; BHTKT cũng cảnh báo. BHT chỉ nối các điểm có thật đã gắn. Số trụ và số mặt biển vẫn tách riêng: một trụ mang hai mặt biển chỉ có một chân.

Đặt lại, xoay, đổi tỷ lệ, thêm/gỡ điểm đều cập nhật đầu đường nối; cập nhật lặp không nhân đôi. Bảng quảng cáo, Khác và Chưa xác định cũng có hình trụ/chân theo số nhập. Block tùy chỉnh giữ hình người dùng đã chọn. Ký hiệu mặc định nhận số trụ 0–100, để trống dùng một trụ.

![Hình xuất trực tiếp từ AutoCAD](HAI_CHAN_BIEN_0.6.25.png)

## Kiểm tra và cài đặt

- 171 kiểm thử Core và 134 kiểm tra giao diện đạt.
- Hồi quy AutoCAD 2024 cho ký hiệu/Unicode/G/T đạt, kèm kiểm tra hai điểm/hai chân, đầu nối riêng, xoay, đổi tỷ lệ, đường gấp khúc, thêm/gỡ điểm, đổi số trụ, không nhân đôi, cảnh báo thiếu điểm và giữ dữ liệu RTK.
- Bộ cài được kiểm tra với 7 trường hợp sao lưu/khôi phục và 39 kiểm tra EXE độc lập.

Đóng AutoCAD rồi chạy **BHT-Setup-0.6.25.exe**. Cài xong hiện thông báo thành công và chỉ còn **Hoàn tất**. Bộ ZIP đầy đủ **BHT-0.6.25.zip** kèm mã nguồn vẫn có để bàn giao. Chưa cài đè hoặc sửa bản vẽ người dùng đang mở.
