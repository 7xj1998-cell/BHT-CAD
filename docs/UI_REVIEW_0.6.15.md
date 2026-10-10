# Rà giao diện và thao tác BHT 0.6.15

Phạm vi ưu tiên: tạo/sửa hồ sơ và đặt ký hiệu, theo lựa chọn của người dùng. Đã đọc mã WinForms, luồng đọc/ghi DWG, sự kiện chọn điểm/chuyển bản vẽ và các kiểm thử hiện có; tạo ảnh giao diện từ control thực trong AutoCAD Core Console bằng dữ liệu giả lập.

| Vấn đề trước khi sửa | Hành vi sau khi sửa |
|---|---|
| Làm mới nạp lại hồ sơ, có thể ghi đè nội dung đang sửa | Giữ vùng nhập khi có thay đổi chưa lưu |
| Chọn hồ sơ khác có thể bỏ thay đổi mà không hỏi | Hỏi trước khi bỏ thay đổi; mặc định quay lại vùng nhập |
| Đổi bản vẽ làm Palette tự ẩn | Palette gắn lại bản vẽ; bản nháp được lưu riêng theo bản vẽ trong cùng phiên |
| Lưu có thể chèn/cập nhật ký hiệu | Lưu hồ sơ chỉ ghi dữ liệu; thao tác chèn và đặt có nút riêng |
| Huỷ hộp tuỳ chọn đặt ký hiệu vẫn có thể đã lưu hồ sơ | Chỉ lưu sau khi xác nhận hộp tuỳ chọn |
| Ô lý trình tay không được ghi khi bấm Lưu hồ sơ | Kiểm tra lý trình rồi ghi cùng hồ sơ; vẫn có thao tác ghi/xóa riêng |
| Danh sách hồ sơ không có tìm kiếm, chiều cao cố định | Tìm không dấu theo ID/nhóm/mã/mô tả/tình trạng và kéo thanh phân cách |
| Mã nhóm/phía đường dài, nhãn nút dễ bị cắt | Hiển thị tên tiếng Việt, giữ mã dữ liệu; nhóm nút hai cột và dòng tô màu riêng |
| README có thể giữ số phiên bản/đường dẫn build cũ | Sửa nội dung hiện tại và bổ sung cập nhật tự động trong script tăng phiên bản |

Luồng đề xuất và đã triển khai: Điểm RTK → Hồ sơ đối tượng → Ảnh hiện trường → Tuyến/báo cáo. Trong hồ sơ: chọn/tạo → kiểm tra thông tin → chọn biển → lưu → chèn/cập nhật hoặc đặt ký hiệu.

Vùng danh sách và vùng nhập được tách bằng SplitContainer; các nút chính nằm trong bảng hai cột. Cách bố trí dùng Dock cho các vùng lớn và chỉ dùng TableLayoutPanel ở nhóm cần chia tỷ lệ, phù hợp hướng dẫn [Microsoft về bố trí WinForms](https://learn.microsoft.com/en-us/dotnet/desktop/winforms/controls/best-practices-for-the-tablelayoutpanel-control).

![Giao diện hồ sơ ở chiều rộng 480 px](UI_BHT_0.6.15.png)

Đã đạt 166 kiểm thử Core, 26 kiểm tra giao diện/luồng hồ sơ và 7 kiểm tra bộ cài. Kiểm thử giao diện gồm tìm không dấu, giữ nội dung khi làm mới/lọc, giữ mã nhóm sau khi đổi nhãn hiển thị, phát hiện sửa ID/lý trình, khôi phục bản nháp và kiểm tra nút ở 340×600, 340×850, 480×850 px.

Ảnh là giao diện thực của control được dựng bằng dữ liệu kiểm thử, không phải ảnh phiên AutoCAD đang mở của người dùng. Chưa xác nhận toàn bộ thao tác trong phiên AutoCAD giao diện đầy đủ hoặc mọi mức DPI. Chiều cao Palette tối thiểu tăng lên 600 px để giữ vùng nhập còn sử dụng được.