# BHT 0.6.37

## 0.6.37 — 10/10/2026

- Ảnh của cả trang thư viện được nạp sẵn dưới dạng thu nhỏ: cuộn đến biển là thấy ảnh, không phải bấm vào. Giới hạn 60 mẫu/trang, giải phóng ảnh trang cũ.
- Gom tốc độ, tải trọng, kích thước, khoảng cách, giờ và thông tin cầu vào Nội dung biển. Bỏ các ô nhập bên ngoài; hỗ trợ thông số riêng cho từng mặt. Biển không có thông số có thông báo rõ.
- Thêm bảng Dữ liệu tuyến: danh sách tuyến đã nạp, nguồn, chiều dài, trạng thái hình học. Nhấp đúp hoặc Hiển thị / zoom tuyến để mở lớp và zoom trọn tuyến.
- BHTHUONGBIEN xoay đầu biển vuông góc về bên trái hướng A→B hoặc chiều tuyến. Đổi A/B để đảo phía. Giữ vị trí, tỷ lệ, RTK và khả năng Undo cả nhóm; giữ cách hiểu dữ liệu hướng cũ.
- Sửa BHTTRANGTHAI chỉ hiện tiêu đề trong báo cáo; đưa đủ các dòng thống kê vào cửa sổ kết quả.
- Bỏ lượt làm mới Palette bị gọi hai lần. Rà soát 51 lệnh Lisp công khai: không trùng tên; giữ lệnh tương thích và công cụ nâng cao.


## Cách dùng phần cập nhật 0.6.37

**Nội dung biển:** chọn mẫu → Nội dung biển… → sửa các dòng → Áp dụng → Chọn biển. Tốc độ, giờ, khoảng cách, tải trọng và thông tin cầu đều nhập tại đây. Với nhiều mặt, mỗi dòng ghi rõ số mặt và mã biển. Dữ liệu đã lưu ở các phiên bản trước vẫn đọc được.

**Dữ liệu tuyến:** mở Tuyến & báo cáo → Dữ liệu tuyến. Chọn tuyến rồi bấm Hiển thị / zoom tuyến hoặc nhấp đúp. BHT mở lớp của tuyến nếu đang tắt/đóng băng, chọn hình học và zoom vừa toàn tuyến. Bảng báo Thiếu hình học nếu đường tham chiếu đã bị xóa. Chiều dài theo đơn vị bản vẽ. Làm mới tuyến để đọc lại danh sách.

**Xoay vuông góc:** gọi BHTHUONGBIEN → H → chọn A rồi B theo hướng đường → C → chọn nhóm biển → Enter. Đầu biển xoay vuông góc về phía trái A→B. Đổi thứ tự A/B để quay sang phía đối diện. Không cần tạo tuyến cho cách H. Chọn T nếu đã có tuyến và muốn theo tiếp tuyến tại từng vị trí. Chọn A ở bước phạm vi để áp dụng mọi biển phù hợp; Undo một lần hoàn tác cả nhóm.

Đóng AutoCAD trước khi cài; mở lại để nạp DLL 0.6.37. Không NETLOAD chồng DLL mới lên phiên đang dùng 0.6.36.
