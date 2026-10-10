# Kiểm tra BHT 0.6.32

Đã build trên Windows x64 với .NET Framework và AutoCAD 2024 Core Console. Kiểm tra phiên bản đồng bộ Lisp/DLL/bundle đạt 0.6.32 / 0.6.32.0.

- Core: 212 PASS, 0 FAIL; gồm 10 bố trí, khoảng cách mặt, thứ tự xếp dọc, giới hạn số, XML Unicode và hồ sơ nhiều mặt cùng mã.
- CAP1 CAD: 60 PASS; nội dung riêng, tag trùng, chữ dài, nguồn giữ nguyên, đủ mặt/chân, khoảng cách đáy, không chồng extents, cache và chỉ nét.
- CAP1 Lisp: nạp nội dung từ XRecord, tạo khung cổng qua API, trả đúng hai chân. Sáu kiểm tra RTK đạt: chèn, nối chân sau xoay, di chuyển, đồng bộ lặp, giữ nội dung và giữ POINT/XData.
- Thư viện: 2.832 kiểm tra CAD nguồn biển đạt; hồi quy Lisp/TCVN3/đặt G/T/biến đổi UCS/nâng cấp/xóa/tô màu/hai chân không có lỗi.
- Picker: kiểm tra trong AutoCAD đạt; thao tác nhập tốc độ/mét/giờ/tên cầu, nhiều mặt, giới hạn 20 và nút Đóng.
- Giao diện: 160 kiểm tra đạt; bộ lọc cao tốc, tiêu đề BHT, bỏ bộ lọc trống, chỉnh nội dung hai mặt cùng mã, sơ đồ CAP1 và bản nháp theo bản vẽ.
- Bộ cài: kiểm tra bảo vệ gói, bộ cài một file và đối chiếu SHA-256 trước bàn giao; không cài đè ứng dụng đang dùng trong quá trình kiểm tra.

Ảnh kiểm tra: [10 bố trí CAP1](CAP1_0.6.32.png). Bản vẽ kiểm tra sinh trong build, không đưa vào gói phát hành.

Giới hạn: bố trí 2D theo extents; chưa tính kết cấu/móng và chưa tự đối chiếu địa danh với hồ sơ ngoài. Chữ dài được thu hẹp ngang theo ô mẫu; cần kiểm tra độ rõ trước khi in.
