# BHT 0.6.21 — 08/10/2026

Đã thêm nút **Tỷ lệ biển / nhãn…** trong thẻ Hồ sơ đối tượng. Chọn riêng hệ số kích thước hình biển và nhãn mã: có các mức gợi ý, nhập tùy chỉnh và nút **Về chuẩn 1:1**. Ví dụ hình biển `2`, nhãn `1` làm biển lớn gấp đôi, nhãn giữ cỡ chuẩn. Nhận dấu phẩy thập phân; giá trị từ `0,01` đến `100`, tối đa 3 chữ số thập phân.

Thiết lập lưu theo bản vẽ, áp dụng cho tất cả biển báo BHT đã chèn và biển chèn sau này. Vị trí, hướng, đường dẫn và dữ liệu RTK được giữ. Nhãn chính và các mặt phụ dùng cùng tỷ lệ nhãn. Bản vẽ cũ giữ cách tính cũ đến khi áp dụng thiết lập mới.

Các nút được sắp theo ba hàng: tạo/lưu hồ sơ, chọn biển/tỷ lệ, đặt/chèn ký hiệu. Thao tác thêm/gỡ điểm nằm cạnh danh sách RTK. Hộp tỷ lệ giữ nội dung đang sửa và vị trí cuộn của vùng nhập.

Đã đạt 171 kiểm thử Core, 111 kiểm tra form và hồi quy CAD/ký hiệu/Unicode/G/T; 7 kiểm tra bộ cài đạt. Kiểm tra CAD gồm vị trí tự động và vị trí tay, nhãn nhiều mặt, biển chèn sau, cập nhật lặp và giá trị sai không ghi dữ liệu. Các kiểm tra chạy trên AutoCAD Core Console và form tự động; chưa thử chuột trong Palette đang dock của phiên CAD người dùng.

![Nút thao tác trong Palette](UI_BHT_0.6.21.png)

![Chọn tỷ lệ hình biển và nhãn](TY_LE_BIEN_0.6.21.png)

Cập nhật: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ **BHT-0.6.21.zip** và chạy **INSTALL_BHT.cmd**. Mở lại CAD, kiểm tra tiêu đề **BHT 0.6.21**. Xem [hướng dẫn](HUONG_DAN.md).
