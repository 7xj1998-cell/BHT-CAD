# BHT 0.6.17 — 07/10/2026

Đã thêm nhấp đúp trên dòng trong danh sách Hồ sơ đối tượng để thu phóng tới vị trí RTK của đúng hồ sơ đó. Đã bỏ nút Thu phóng dư ở dưới form. Nhấp một lần tiếp tục mở/sửa hồ sơ; nhấp đúp không tự lưu nội dung đang sửa. Nhấp vào vùng trống hoặc nhấp đúp bằng chuột phải không thu phóng.

Đã thêm phím **G** (Gốc) và **T** (Tuỳ chọn) khi đặt ký hiệu trên CAD:

- **G** đặt tại tâm X gốc của hồ sơ, bỏ các điểm trung gian và đường dẫn cũ. Với hồ sơ nhiều điểm, tâm gốc là vị trí trung bình của các điểm RTK hợp lệ.
- **T** chuyển sang chọn vị trí tuỳ ý bằng chuột. Vẫn có thể bấm vị trí trực tiếp, không cần gõ T trước.
- Phím G/T có ở bước điểm trung gian và vị trí cuối, dùng được từ Palette hoặc BHTDATTUDO. Hướng ký hiệu đã chọn vẫn được áp dụng; chế độ Chọn hướng trên CAD vẫn cần bấm hướng sau vị trí.
- Enter ở vị trí cuối hoặc Esc huỷ thao tác; bản ghi và ký hiệu chưa bị thay đổi. Điểm RTK giữ nguyên.

Đã đạt build đầy đủ, 166 kiểm thử Core, 49 kiểm tra form, 9 tình huống G/T tương tác thực trong AutoCAD Core Console, hồi quy ký hiệu/Unicode và bộ chọn biển, cùng 7 kiểm tra bộ cài. Các tình huống G/T gồm vị trí gốc, vị trí tuỳ ý, huỷ, điểm trung gian, lệnh BHTDATTUDO và UCS xoay. Chưa kiểm tra toàn bộ thao tác chuột trong Palette đang dock ở mọi mức DPI của phiên AutoCAD đầy đủ.

Để cập nhật: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ BHT-0.6.17.zip và chạy INSTALL_BHT.cmd. Mở lại AutoCAD, kiểm tra tiêu đề BHT 0.6.17. Xem [hướng dẫn](HUONG_DAN.md).
