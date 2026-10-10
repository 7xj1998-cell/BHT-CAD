# Kiểm tra 0.6.37

- Core: 233 PASS. Giao diện và nội dung: 663 kiểm tra PASS; native picker PASS.
- Kiểm tra ảnh tất cả 467 mẫu trên các trang trước khi nhấp; đổi trang, tìm kiếm rỗng, resize và đóng cửa sổ không phát sinh ThreadException.
- Bài đo CoreConsole: mở thư viện 522 / 441 / 453 ms; 60 ảnh, 11.197.440 byte pixel. Đây là đo cục bộ, không phải cam kết thời gian trên mọi bản vẽ.
- 25 kiểm tra hướng đạt: tương thích chế độ cũ, vuông góc theo tuyến/A→B, UCS xoay, Undo, hủy thao tác, cập nhật giữ hướng, đổi A/B đảo phía.
- Bản vẽ test 15doan.dwg: 790 điểm RTK, 65 hồ sơ, 64 ký hiệu, tuyến TUYEN1 dài khoảng 4.021 m. Đã thử xoay OBJ-000001/OBJ-000002 ngay trong CAD đang mở: góc và vị trí đúng, Undo khôi phục hồ sơ và INSERT. Báo cáo mới có 10 dòng. Đã trả hai biển về trạng thái ban đầu và lưu bản vẽ test.
- Bản sao đầy đủ dùng kiểm tra bảng tuyến/zoom: đọc TUYEN1, phát hiện tuyến mất hình học, hiển thị đường và lớp ẩn, toàn bộ extents nằm trong góc nhìn xoay, xóa bảng khi đóng tài liệu.
- Rà soát 51 lệnh Lisp công khai không trùng tên; bỏ RefreshAll thừa sau BindTo. Không xóa lệnh tương thích chỉ vì ít xuất hiện trên giao diện.
- Công cụ chụp cửa sổ CAD trực tiếp bị timeout; kết quả kiểm tra live lấy từ COM/Lisp và file báo cáo. Giao diện mới được kiểm tra trong tiến trình CAD kiểm thử riêng, DLL đang nạp trong phiên người dùng chưa được thay.
