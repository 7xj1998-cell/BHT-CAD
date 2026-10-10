# BHT 0.6.33 — Bỏ nền, giữ biểu tượng và nhập thông số thực tế

Đã sửa **Tô nền tất cả biển**: khi tắt, chỉ bỏ nền màu; mũi tên, đường nhánh, hình xe và các phần hatch biểu tượng vẫn giữ để in trắng đen. Vùng rỗng trong hình giữ trắng.

Đã giữ đầy đủ viền tròn, tam giác và chữ nhật khi bỏ nền. Các viền có bề rộng dùng đường bao trong/ngoài của mẫu gốc; nét khung dùng 0,25 mm khi in.

Đã rà 469 DWG nguồn / 467 mẫu trong thư viện. **Nội dung / CAP1…** cho sửa thông số trong attribute và TEXT/MTEXT, gồm số, giờ, khoảng cách, kích thước, tải trọng, tốc độ theo làn, độ dốc và tần số. Mỗi mặt giữ nội dung riêng. Nhập số có dấu phẩy thập phân, giữ đơn vị mẫu; hỗ trợ khoảng cách 0 và giờ qua đêm.

Chọn biển → Nội dung / CAP1 → Áp dụng → Chọn biển → Lưu hồ sơ → Chèn / cập nhật ký hiệu. Bố trí CAP1 2D và liên kết điểm RTK tiếp tục được giữ. Ảnh trong thư viện là mẫu; CAD áp dụng nội dung đã lưu.

Đóng AutoCAD rồi chạy `BHT-Setup-0.6.33.exe`. Mở lại và kiểm tra phiên bản 0.6.33. Bản vẽ có ký hiệu cũ được cập nhật sang cache mới, giữ vị trí/góc/tỷ lệ; lưu DWG sau khi kiểm tra.

CAP1 là bố trí trình bày 2D. Chữ dài được thu hẹp theo ô mẫu; kiểm tra độ rõ trước khi in. Địa danh cần nhập theo hồ sơ thực tế.
