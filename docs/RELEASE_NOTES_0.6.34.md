# BHT 0.6.34 — Dấu gốc biển, biển phụ và chọn đầu tuyến

Đã thêm block tròn đặc tại tâm X của từng điểm RTK liên kết với biển báo. Dấu trên layer ký hiệu, vẫn hiện khi ẩn layer điểm và khi tắt tô nền biển. Biển có nhiều điểm chân có dấu tại từng điểm.

Di chuyển/xoay hình biển giữ dấu ở đúng vị trí RTK. Đổi tỷ lệ biển cũng đổi kích thước dấu. Đặt biển tại G vẫn có dấu khi không có đường dẫn. Chọn dấu để mở hồ sơ biển trong Palette; dấu được xóa cùng ký hiệu/hồ sơ.

Đóng AutoCAD rồi chạy `BHT-Setup-0.6.34.exe`. Mở lại, kiểm tra phiên bản 0.6.34. Bản vẽ cũ nhận dấu sau khi cập nhật ký hiệu; lưu DWG sau khi kiểm tra. Bật `FILLMODE = 1` và REGEN để hiển thị phần đặc.

Đã khôi phục bộ lọc **Biển phụ**, hiển thị đủ 47 mẫu mã S. Tạo tuyến mới từ PL thường hoặc TDT 9.1 sẽ mở ngay bước chọn đầu tuyến và xác nhận/đảo mũi tên chiều tăng. Có thể chọn lại bằng nút **Chọn điểm đầu và chiều tuyến** trong **Tuyến & báo cáo**. Km cần mốc từ hồ sơ hoặc cọc TDT đã kiểm tra.

Đã sửa lỗi chuyển đường dẫn biển nhiều chân từ thẳng sang gấp khúc.
