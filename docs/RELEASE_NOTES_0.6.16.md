# BHT 0.6.16 — 07/10/2026

Đã sửa form tự cuộn xuống khi tạo hồ sơ từ RTK. Hồ sơ mới mở ở đầu form, ô Nhóm nhận con trỏ; sửa/làm mới giữ vị trí cuộn. Cập nhật dữ liệu và ẩn/hiện các dòng được gom trong một lần bố trí, dòng trạng thái có chiều cao ổn định để giảm giật.

Đã bỏ `(meta trung_kc_m)` khỏi cảnh báo trùng Cọc tiêu/Cột Km. Đây là tên cấu hình ngưỡng khoảng cách, không phải lỗi thực thi; kiểm tra trùng và ngưỡng mặc định 0,50 m vẫn hoạt động.

Đã thêm **Tên trên bảng** cho nhóm **Bảng quảng cáo** và **Khác**. Tên được lưu trong trường mô tả hiện có; hồ sơ cũ tiếp tục dùng mô tả đã lưu. Ký hiệu mặc định là bảng chữ nhật có Hatch xanh, viền trắng và tên màu trắng ở giữa, cùng màu nền với biển S.509a. Tên dài tự xuống dòng hoặc thu chiều ngang chữ để nằm trong khung. Nếu tên còn trống, bảng dùng tên nhóm.

Đã đổi ký hiệu mặc định của nhóm **Chưa xác định** sang cùng mẫu với chữ **Chưa xác định** ở chính giữa, kể cả khi hồ sơ có mô tả khác. Tên nằm trong bảng, không tạo thêm nhãn vàng ở ngoài. Block tuỳ chỉnh đã gán riêng hoặc cho cả nhóm vẫn được ưu tiên. Tô màu tất cả biển tiếp tục áp dụng cho nhóm Biển báo; các bảng tên mới giữ nền xanh.

![Mẫu bảng xuất từ AutoCAD](BANG_TEN_0.6.16.png)

Đã đạt 166 kiểm thử Core, 44 kiểm tra form tại các kích thước 340 × 600, 340 × 850 và 480 × 850, 21 kiểm tra hình học/chữ/Hatch của bảng, hồi quy AutoCAD và chế độ không có TDT, cùng 7 kiểm tra bộ cài. Đã kiểm tra hình mẫu xuất trực tiếp từ AutoCAD. Chưa kiểm tra thao tác trong Palette đang dock ở mọi mức DPI của phiên AutoCAD đầy đủ.

Để cập nhật: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ BHT-0.6.16.zip và chạy INSTALL_BHT.cmd. Mở lại AutoCAD, kiểm tra tiêu đề BHT 0.6.16. Chọn hồ sơ cũ và bấm **Chèn / cập nhật ký hiệu** để đổi sang bảng mới; vị trí/góc đã đặt được giữ. **Lưu hồ sơ** chỉ ghi dữ liệu. Xem [hướng dẫn](HUONG_DAN.md).
