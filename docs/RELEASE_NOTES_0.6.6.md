# BHT v0.6.6 — 2026-10-02

Sửa thư viện ảnh biển báo: nhúng toàn bộ bộ ảnh đã kiểm chứng vào BHT.Palette.dll. Ảnh R.122 (Dừng lại), P.131c và S.508a/b vẫn hiện khi thiếu thư mục Images. Ảnh nhúng được ưu tiên; ảnh TDT hoặc Images vẫn hỗ trợ mã ngoài bộ ảnh đi kèm.

Máy kiểm tra vẫn cài BHT.Palette 0.6.3.0. Phiên bản này có 412 mục và các mục chưa có ảnh; v0.6.6 lọc các tiêu đề XML cũ còn 376 mã lựa chọn. Đóng toàn bộ AutoCAD, giải nén gói mới và chạy INSTALL_BHT.cmd. Khởi động lại CAD, gọi BHT và kiểm tra tiêu đề 0.6.6.

Kiểm thử: 132 kiểm tra Core; CAD Core Console chèn biển, tham số mét, nhiều mặt và đặt tự do; WinForms 376 ảnh thực, không thiếu ảnh; chạy WinForms trong thư mục tạm chỉ có DLL và exe, không có Images hay assets, vẫn 376 ảnh thực; 7 kiểm tra bảo mật bộ cài. Không xác nhận thao tác chuột trực tiếp trong AutoCAD ở đợt này.