# BHT 0.6.18 — 07/10/2026

Đã sửa **Tô màu tất cả biển** tự bật lại khi làm mới trong lúc thao tác còn chờ AutoCAD xử lý. Trước đây, làm mới đọc giá trị cũ từ bản vẽ và ghi đè checkbox. Bản mới giữ lựa chọn đang chờ và đọc lại trạng thái đã lưu sau khi có kết quả.

Đã khóa checkbox khi đang áp dụng tô màu hoặc xử lý thao tác Lisp khác, tránh gửi nhiều yêu cầu chồng nhau. Nếu AutoCAD đang bận hoặc thao tác bị từ chối, checkbox trở về trạng thái thực của bản vẽ và vùng trạng thái báo rõ. Kết quả cũ sau khi đổi/gắn lại bản vẽ được bỏ qua.

Phạm vi tô màu vẫn là toàn bộ nhóm Biển báo BHT trong bản vẽ. Các bảng tên của Bảng quảng cáo, Khác và Chưa xác định giữ nền xanh. Nội dung hồ sơ chưa lưu vẫn được giữ khi làm mới.

Đã đạt build đầy đủ và 166 kiểm thử Core, 63 kiểm tra form/đồng bộ trạng thái, hồi quy hình học biển, bật/tắt màu, đặt ký hiệu G/T, Unicode và bộ chọn biển, cùng 7 kiểm tra bộ cài. Các tình huống mới mô phỏng kết quả chậm, làm mới nhiều lần, thao tác liên tiếp, kết quả cũ, lỗi và AutoCAD bận; API bật/tắt được gọi thực trong AutoCAD Core Console. Chưa kiểm tra toàn bộ thao tác chuột trong Palette đang dock của phiên AutoCAD đầy đủ.

Để cập nhật: lưu bản vẽ, đóng toàn bộ AutoCAD, giải nén đầy đủ BHT-0.6.18.zip và chạy INSTALL_BHT.cmd. Mở lại AutoCAD, kiểm tra tiêu đề BHT 0.6.18. Nếu tiêu đề còn 0.6.15 thì phiên AutoCAD vẫn đang dùng DLL cũ; cần nạp lại bộ mới sau khi đóng CAD. Xem [hướng dẫn](HUONG_DAN.md).
