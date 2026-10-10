# BHT 0.6.20 — 07/10/2026

Đã sửa bốn vấn đề trong ảnh phản hồi:

- **Nét biển:** R.415a/b có hình xe, bánh xe, đèn và vạch phân làn vẽ lại bằng nét CAD sạch. W.239a có ký hiệu điện với cạnh thẳng. Chế độ bỏ Hatch giữ đường bao đã có, bỏ nét trùng và nối các cạnh cong thành đường liên tục.
- **Màu số:** khi tắt tô màu, số và thuộc tính trong block lồng nhau kế thừa màu của ký hiệu, mặc định trắng trên nền CAD tối. Khi bật tô màu, số trên biển tốc độ vẫn đen trên nền trắng.
- **Nhãn từng mặt:** cụm hai mặt có hai dòng nhãn riêng phía dưới ký hiệu, theo thứ tự biển chính rồi biển phụ. Giá trị như `S.509a (4.75 m)` hoặc `S.505a (8T)` được giữ. Bỏ mặt sẽ dọn nhãn tương ứng; cập nhật lặp lại giữ cùng thực thể.
- **Vị trí cuộn:** danh sách giữ dòng đầu đang xem khi làm mới sau chỉnh sửa. Vùng nhập giữ vị trí khi đóng thư viện biển và áp dụng lựa chọn mới.

Đã đạt 171 kiểm thử Core, 75 kiểm tra giao diện với danh sách 72 hồ sơ và nhiều kích thước Palette, kiểm tra số/thuộc tính kế thừa màu, đường bao không trùng, nhãn nhiều mặt/tháo mặt/cập nhật lặp lại, các hồi quy ký hiệu, Unicode, G/T và 7 kiểm tra bộ cài. Hình học được kiểm tra thêm qua PDF AutoCAD xuất. Các kiểm tra chạy bằng AutoCAD Core Console và form tự động; chưa thử toàn bộ thao tác chuột trong Palette đang dock của phiên AutoCAD người dùng.

![Nét biển và nhãn từng mặt, xuất từ AutoCAD](SUA_NET_BIEN_0.6.20.png)

Cập nhật: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ **BHT-0.6.20.zip** và chạy **INSTALL_BHT.cmd**. Mở lại AutoCAD, kiểm tra tiêu đề **BHT 0.6.20**. Mở các hồ sơ có ký hiệu cũ và bấm **Chèn / cập nhật ký hiệu** để nhận nét và nhãn mới. Xem [hướng dẫn](HUONG_DAN.md).
