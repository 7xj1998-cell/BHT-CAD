# BHT 0.6.30 — Tô màu, R.415, cập nhật biển và xóa hồ sơ

**Tô màu tất cả biển** áp dụng cả biển báo, bảng chỉ dẫn, bảng quảng cáo, Khác và Chưa xác định. Bỏ chọn chuyển các block đã đặt sang bản chỉ nét, không còn hatch, nền MText hoặc bề rộng nét tô. Chữ trên biển vẫn được giữ để đọc. Chọn lại khôi phục bản màu. Hồ sơ chưa đặt ký hiệu dùng trạng thái này khi chèn sau.

R.415a/b được dựng lại bằng đường CAD có cung tròn và đường cong mượt, đủ sáu hình xe theo mẫu. Vạch phân làn thẳng, đều; dải hủy R.415b nằm phía trên hình xe. Thư viện và hình chèn dùng cùng dữ liệu vector. Nguồn hình học được lưu trong SVG để chỉnh sửa về sau; tài nguyên TDT gốc giữ nguyên.

![R.415 màu và chỉ nét, xuất từ AutoCAD 2024](BIEN_R415_0.6.30.png)

Sau khi cài phiên bản mới và mở CAD/bản vẽ, BHT chờ CAD rảnh và lõi Lisp nạp đúng phiên bản rồi cập nhật ký hiệu biển/đèn đã có. Điểm chèn, góc xoay, tỷ lệ và chế độ đặt giữ nguyên; ký hiệu chưa đặt không được tự tạo. BHT báo kết quả trên dòng lệnh. **Lưu bản vẽ** để giữ thay đổi; không lưu tự động. Bản vẽ chỉ đọc được bỏ qua. Đánh dấu phiên bản trong từng DWG giúp tránh cập nhật lặp.

**Xóa hồ sơ…** nằm cạnh Thông tin ở cuối tab Hồ sơ đối tượng. Chọn hồ sơ đã lưu rồi bấm nút; xác nhận xóa hồ sơ, ký hiệu, nhãn và đường nối. RTK và ảnh gốc được giữ; chỉ gỡ liên kết ảnh của hồ sơ đã xóa. Nút bị vô hiệu hóa khi đang tạo hồ sơ, chưa nạp lõi hoặc đang chạy thao tác BHT.

Đóng AutoCAD rồi chạy **BHT-Setup-0.6.30.exe**. Bộ cài thông báo hoàn tất và chỉ còn nút Hoàn tất. Mở lại CAD, kiểm tra tiêu đề 0.6.30 rồi mở DWG cần cập nhật. Bản 0.6.29 được lưu trong Old.

Đã kiểm tra 178 ca Core, 149 ca giao diện, hồi quy AutoCAD 2024, cập nhật hình cũ qua cùng API mà trình tự nạp sử dụng và xóa hồ sơ trên bản vẽ thử. Luồng sự kiện Idle khi mở AutoCAD giao diện đầy đủ chưa được kiểm tra trực tiếp; Core Console kiểm tra việc gọi API, dấu phiên bản và bảo toàn dữ liệu. Chi tiết trong `QA_0.6.30.md`.
