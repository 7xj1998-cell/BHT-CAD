# Kiểm tra BHT 0.6.38 — 10/10/2026

- Build .NET Framework 4.8/AutoCAD 2024 thành công; Core: 233 PASS.
- Quản lý tuyến: 19 PASS, gồm trùng ID, ngoại suy âm, đổi ID và liên kết hướng biển, xóa giữ đường/RTK/góc biển, thay hình học bỏ mốc cũ, hủy xóa, lệnh sửa/xóa thực và Undo khôi phục.
- Bảng tuyến/zoom trên bản sao đầy đủ `D:/lisp/BHT/15doan-full-637.dwg`: 10 PASS. Đọc được TUYEN1 dài 4.021,28 m, báo thiếu hình học, mở lớp/đường ẩn, extents nằm trọn trong góc nhìn xoay; đổi tab, làm mới ngoài tab tuyến và Unbind bỏ trạng thái làm sáng cũ.
- Hướng biển: 25 PASS. Điểm đầu và chiều tuyến: 10 PASS, gồm luồng TDT dùng mock Bridge trong bài kiểm thử.
- Thư viện 467 biển: run_signs với BHT_TEST_ADS=1 hoàn thành; kiểm tra hình học, hatch, thứ tự vẽ, bỏ nền, tái sử dụng block và các lệnh chèn biển. Thư viện đèn và CAP1 đạt; không sửa nguồn tài nguyên gốc.
- Giao diện/nội dung: 663 kiểm tra đạt trên DLL cuối. Đo mở thư viện: 444 / 335 / 331 ms; 60 ảnh thu nhỏ, 11.197.440 byte pixel. Resize, đổi trang, bộ lọc rỗng và đóng cửa sổ đạt. Số đo trong CoreConsole cục bộ, không đại diện mọi bản vẽ.
- Rà soát 54 lệnh Lisp công khai: không trùng tên. Giữ các lệnh tương thích. Kiểm tra các điểm gọi First/Single và xử lý vòng đời ảnh/tuyến trong mã nguồn; không thay đổi chỉ vì trùng từ khóa.
- Phạm vi: bộ run_all lịch sử dùng đường dẫn/fixture riêng BHT_TEST_V044 chưa chạy lại; không khẳng định mọi lỗi trong app đã được loại bỏ. Bản này được kiểm tra bằng tiến trình CAD riêng và bản sao bản vẽ, chưa thay DLL đang nạp trong AutoCAD của người dùng. Chưa đối chiếu trực quan cách tô sáng với lệnh DLBD gốc của TDT.
- Lỗi Undo ban đầu của harness do nhóm Undo từ NETLOAD còn mở: kết thúc nhóm thiết lập trước bài kiểm thử; không thay đổi hành vi Undo của người dùng để che lỗi.