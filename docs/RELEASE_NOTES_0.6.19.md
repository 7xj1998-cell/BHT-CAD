# BHT 0.6.19 — 07/10/2026

Đã thêm **Trọng lượng (tấn)** cho biển phụ **S.505a — Loại xe**. Nhập `8` để CAD hiển thị **8T** dưới hình xe, theo ảnh khảo sát. Có thể nhập số thập phân như `8,5`; BHT lưu dạng `S.505a@8.5` và hiển thị **8.5T**. Để trống để giữ mẫu chỉ có xe.

Khi chọn nhiều mặt trên cùng trụ: thêm biển chính, chọn S.505a, nhập trọng lượng rồi bấm **Thêm mặt**. Nhấp đúp S.505a đưa con trỏ vào ô trọng lượng. Bấm **Chọn biển**, lưu hồ sơ và chèn/cập nhật ký hiệu. Mỗi mặt giữ giá trị riêng; khi sửa mặt đã thêm, bỏ mặt cũ rồi thêm lại với trọng lượng mới.

Mẫu dùng hình xe gốc từ thư viện TDT, đặt phía trên chữ đen trên nền trắng và viền đen. Mỗi trọng lượng có block riêng, dùng được khi ghép nhiều mặt và bật/tắt tô màu. Cần mẫu S.505a từ TDT khi tạo lần đầu; block đã lưu vẫn dùng được khi thiếu TDT. Không sửa tài nguyên TDT gốc.

Đã đạt 171 kiểm thử Core, 63 kiểm tra form/đồng bộ trạng thái, 7 kiểm tra bộ cài, kiểm tra hình học và PDF do AutoCAD xuất, bộ chọn biển, lưu/đồng bộ hồ sơ hai mặt, bật/tắt Hatch, cùng các bộ hồi quy ký hiệu, Unicode, G/T. Kiểm tra form chạy tự động; chưa thử toàn bộ thao tác chuột trong phiên AutoCAD đang mở của người dùng.

![Mẫu S.505a có trọng lượng, xuất trực tiếp từ AutoCAD](S505A_TRONG_LUONG_0.6.19.png)

Để cập nhật: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ BHT-0.6.19.zip và chạy INSTALL_BHT.cmd. Mở lại AutoCAD, kiểm tra tiêu đề BHT 0.6.19. Xem [hướng dẫn](HUONG_DAN.md).
