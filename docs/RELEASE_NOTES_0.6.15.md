# BHT 0.6.15 — 07/10/2026

Đã sắp xếp lại thao tác tạo/sửa hồ sơ và đặt ký hiệu: chọn điểm RTK → nhập/kiểm tra thông tin → chọn biển → Lưu hồ sơ → Chèn / cập nhật ký hiệu hoặc Đặt ký hiệu. Lưu hồ sơ không tự đổi hình CAD; lý trình tay được kiểm tra và ghi cùng hồ sơ.

Đã thêm tìm hồ sơ không dấu, danh sách có thể kéo đổi chiều cao và trạng thái Chưa lưu thay đổi. Làm mới/lọc không ghi đè vùng nhập; chuyển hồ sơ khác sẽ hỏi trước khi bỏ thay đổi. Đổi bản vẽ không tự ẩn Palette; bản nháp được khôi phục khi quay lại trong cùng phiên. Bản nháp nằm trong bộ nhớ, cần lưu trước khi đóng bản vẽ hoặc AutoCAD.

Đã sửa việc lưu trước khi xác nhận hộp tuỳ chọn đặt ký hiệu. Các nhóm, phía đường và loại mã hiển thị tên tiếng Việt, giữ nguyên mã dữ liệu. Nút chính và dòng Tô màu tất cả biển được bố trí để dùng ở bảng hẹp; Palette có chiều cao tối thiểu 600 px.

Đã đạt build đầy đủ và 166 kiểm thử Core, 26 kiểm tra giao diện/luồng hồ sơ trong AutoCAD Core Console, bộ hồi quy biển/đặt ký hiệu/Unicode và 7 kiểm tra bộ cài. Chưa kiểm thử toàn bộ phiên AutoCAD giao diện đầy đủ và mọi mức DPI.

Xem [báo cáo rà giao diện](UI_REVIEW_0.6.15.md) và [hướng dẫn](HUONG_DAN.md).

Cài đặt: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ BHT-0.6.15.zip và chạy INSTALL_BHT.cmd. Mở lại AutoCAD, gõ BHT hoặc BTH; tiêu đề Palette hiển thị 0.6.15.