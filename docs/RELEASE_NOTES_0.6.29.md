# BHT 0.6.29 — Nhãn đèn tín hiệu và biển trạm thu phí

Nhãn đèn chiếu sáng/tín hiệu được đặt bên dưới ký hiệu, căn giữa theo khung block và quay theo ký hiệu. Cỡ nhãn của nhóm này giữ theo tỷ lệ ký hiệu hiện có. Với hồ sơ cũ, bấm **Chèn / cập nhật** để chuyển nhãn xuống dưới và giữ vị trí ký hiệu.

## Chọn biển và thao tác CAD

**Chọn biển…** mở thư viện song song với CAD. Có thể chuyển sang bản vẽ để zoom, pan và xem trong khi thư viện vẫn mở. Bấm lại **Chọn biển…** đưa cửa sổ đang mở lên trước; không mở nhiều cửa sổ cho cùng hồ sơ.

Bấm **Chọn biển** trong thư viện để nhận lựa chọn vào hồ sơ đang sửa, sau đó **Lưu hồ sơ** và **Chèn / cập nhật**. Bấm **Đóng**, Escape hoặc dấu X hủy lựa chọn. Khi đổi hồ sơ hoặc đổi/đóng bản vẽ, thư viện đóng để tránh ghi lựa chọn vào hồ sơ khác. Chọn đối tượng trên CAD khi xem không tự đổi hồ sơ trong Palette.

## Biển trạm thu phí

- **IE.472a**: bảng trên ghi TRẠM THU PHÍ / TOLL PLAZA; bảng dưới ghi khoảng cách. Ô **Giá trị thực tế (m)** mặc định 750, nhận số lớn hơn 0 đến 100000, tối đa 3 số thập phân. Có thể dùng dấu phẩy hoặc dấu chấm.
- **IE.472b**: bảng TRẠM THU PHÍ / TOLL PLAZA tại vị trí trạm, không có bảng mét.
- Hai mẫu đã được kiểm tra với hai trụ/chân và ghép nhiều mặt, không giữ lại trụ giữa thừa. Hai mẫu là block CAD riêng của BHT, nền xanh có hatch, khung trắng bo góc và chữ trắng cố định. Chế độ bỏ tô màu vẫn giữ khung và chữ. Không cần cài TDT để dùng hai mẫu này.
- Chọn nhiều mặt: nhập mét rồi bấm **Thêm mặt** cho từng tấm. Mỗi mặt giữ số riêng, ví dụ `IE.472a@500`.

![Mẫu xuất trực tiếp từ AutoCAD 2024](TRAM_THU_PHI_0.6.29.png)

## Kiểm tra và cài đặt

178 kiểm thử Core và 144 kiểm tra giao diện đạt. Kiểm tra native AutoCAD xác nhận chữ Unicode màu trắng, hatch nền xanh, khung bo góc, khoảng cách từng mặt, chế độ chỉ nét, nhãn đèn quay theo block và cập nhật lặp giữ điểm RTK. Kiểm tra giao diện chạy trong Core Console/WinForms, gồm lệnh ZOOM khi thư viện vẫn mở; chưa thử thao tác chuột zoom/pan trong AutoCAD giao diện đầy đủ. Hai mẫu cũng được kiểm tra khi không có TDT. Bộ cài được kiểm tra tính toàn vẹn và chạy độc lập, không cài lên bản vẽ khảo sát.

Đóng AutoCAD và chạy **BHT-Setup-0.6.29.exe**. Khi cài xong chỉ còn **Hoàn tất**. Bộ cài, ZIP và thư mục 0.6.29 được đặt ở thư mục BHT; bản 0.6.27 được lưu vào **Old**.
