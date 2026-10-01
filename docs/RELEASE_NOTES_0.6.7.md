# BHT v0.6.7 — 2026-10-02

Khắc phục lỗi chèn nhiều mặt biển: BHTSIGNASSEMBLY có thuộc tính LispFunction nhưng lớp chứa hàm chưa nằm trong danh sách CommandClass của assembly. AutoCAD không đăng ký hàm nên Lisp dừng khi ghép cụm; hộp thông báo không có chi tiết. Đã bổ sung đăng ký lớp, dùng hàm static và thêm thông báo dự phòng khi Lisp trả lỗi rỗng.

Thanh thao tác hồ sơ dùng hai hàng cố định. Hàng đầu: Tạo hồ sơ, Lưu, Đặt tự do, Thư viện biển. Hàng dưới: Chèn/Cập nhật ký hiệu và Tô màu biển. Các nút không tự xuống hàng khi thay đổi bề rộng bảng.

Kiểm thử: 133 kiểm tra Core đạt; CAD Core Console xác nhận hàm đã đăng ký, chèn 1 trụ 2 mặt W.239 + S.509a@7, hai mặt được tạo và cập nhật lặp giữ nguyên; gọi qua Application.Invoke (đường API Palette) đạt. Kiểm tra không TDT đạt. WinForms có 376 ảnh thực và không ảnh thiếu, bộ chọn và tùy chọn đặt tự do đạt. Chưa kiểm chứng thao tác chuột trực tiếp trong AutoCAD ở đợt này.

Cài đặt: đóng toàn bộ AutoCAD, giải nén và chạy INSTALL_BHT.cmd, khởi động CAD và gọi BHT. Kiểm tra tiêu đề 0.6.7. Chọn hồ sơ rồi Chèn/Cập nhật ký hiệu để tạo lại cụm trước đó bị lỗi.