# BHT 0.6.27 — Sửa hình biển và tự đếm số mặt

W.207a đã có hai nhánh đường không ưu tiên đối diện. R.415a/b được vẽ lại theo mẫu đã gửi: hình xe mượt hơn, rõ cửa kính và bánh xe, vạch phân làn thẳng. Hình trong thư viện lấy từ cùng đường CAD để khớp với ký hiệu được chèn.

## Thao tác

- DP.134 và R.306 có ô **Tốc độ trên biển (km/h)**, nhập số nguyên từ 5 đến 130; ảnh xem trước hiển thị số đã nhập. Thêm từng mặt để lưu các tốc độ khác nhau trên cùng trụ.
- **Số mặt biển** tự tính: một biển là một mặt, hai tấm cùng mã là hai mặt. Thêm hoặc bỏ mặt trong **Chọn biển…**, không cần nhập tay số lượng.
- Chọn lại một biển ở chế độ một mặt thay danh sách nhiều mặt trước đó. **Số trụ/chân** vẫn nhập riêng theo hiện trạng.
- Với hồ sơ đã có ký hiệu cũ, bấm **Chèn / cập nhật** sau khi nâng cấp để nhận hình mới và giữ vị trí đã đặt.

![Hình xuất trực tiếp từ AutoCAD 2024](BIEN_BAO_0.6.27.png)

## Kiểm tra và cài đặt

176 kiểm thử Core và 139 kiểm tra giao diện đạt; kiểm tra thư viện chọn biển, giao diện, hình CAD tô màu/chỉ nét, tốc độ từng mặt, Unicode, đặt G/T và hai điểm RTK nối hai chân đạt. Bộ cài được kiểm tra sao lưu/khôi phục và chạy độc lập.

Đóng AutoCAD, chạy **BHT-Setup-0.6.27.exe**. Cài xong hiện thông báo thành công và chỉ còn **Hoàn tất**. Có gói ZIP kèm mã nguồn để bàn giao. Bản 0.6.25 được chuyển vào **Old**; bản vẽ khảo sát giữ nguyên.
