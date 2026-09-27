# BHT 0.3.3 — Vấn đề còn tồn tại

1. **Chưa chạy thật các phần giao diện:** hộp thoại DCL, hộp chọn file, chọn đối tượng bằng chuột, trình xem ảnh.
   - AutoCAD Core Console không có các phần này.
   - Đã kiểm tĩnh file DCL: 42 nút, khóa duy nhất, mọi nút gọi lệnh có thật.
   - Các hàm dữ liệu phía sau đã được kiểm, kể cả `BHTDOITUONG` với câu trả lời giả lập (thay hàm hỏi đáp, không thay logic).
   - Cần làm theo `CHECKLIST_NGHIEM_THU.md` trong AutoCAD đầy đủ.
2. **Bố trí nhãn không bảo đảm hết chồng lấn.** Số liệu đo trong Core Console:
   - 526 điểm thật: còn 26 / 1574 nhãn chồng lấn. Ở vị trí mặc định của 0.3.2 là 941.
   - Khu dày giả lập (60 điểm, lưới 1,2 m): còn 141 / 160. Ở vị trí 0.3.2 là 160 / 160; số cặp nhãn đè nhau giảm từ 1351 xuống 143.
   - Khu quá dày cần kéo tay (BHT giữ vị trí tay), giảm cao chữ, hoặc dùng chế độ tên / ưu tiên hồ sơ.
   - Thuật toán là tham lam 2 lượt, không phải tối ưu toàn cục.
3. **Nhận diện ảnh nền IRT dựa trên mẫu tên.** IRTv6 là file mã hóa, BHT không đọc được quy ước đặt tên layer / ảnh của IRT.
   - Mẫu mặc định: `IRT*`, `*GOOGLE*`, `*SATELLITE*`, `*TILE*`, `*BING*`, `*ESRI*`, `*ARCGIS*`, `*VETINH*`… Mẫu được so với tên layer, tên ảnh và tên file, không xét tên thư mục.
   - Ảnh không khớp mẫu được giữ nguyên thứ tự. Ảnh nằm trong Xref không được sắp.
   - Cần người dùng cho biết tên layer / tên file IRT thật (CHECKLIST D2).
4. **Thứ tự hiển thị được kiểm bằng bảng SORTENTS** trong Core Console, chưa nhìn trên màn hình.
   - Phải để `DRAWORDERCTL` = 3 thì AutoCAD mới hiển thị theo bảng này.
   - Thực thể tạo sau khi chạy `BHTTHUTUVE` (nhãn mới, raster mới) nằm trên cùng cho tới khi chạy lại lệnh.
5. **Thực thể BHT tạo trong Layout bởi bản cũ.** Nếu trước đây từng chạy BHT khi đang ở tab Layout, dữ liệu nằm trong paper space. Dữ liệu không mất; `BHTKT` sẽ cảnh báo.
   - `BHTVEMODEL` chuyển các thực thể đó về Model; handle thực thể đổi.
   - Raster ảnh không chuyển được, cần gỡ và chèn lại.
   - Bản vẽ test của 0.3.2 bị trường hợp này vì bản vẽ mẫu được lưu khi đang ở Layout1.
6. **Hệ tọa độ ảnh chưa được xác nhận chính thức.** Mặc định: VN-2000, KTT 105°45', k = 0.9999.
7. **Raster sau khi chỉ lại thư mục** có thể cần `-IMAGE` > Reload trong AutoCAD đầy đủ.
8. **Chế độ ưu tiên hồ sơ gỡ nhãn phụ** (mô tả, cao độ, ID) của điểm thuộc hồ sơ, không chỉ ẩn. Tắt chế độ thì nhãn được tạo lại từ dữ liệu điểm, nhưng vị trí dời tay (nếu có) của các nhãn phụ đó không còn.
9. **Đường dẫn ảnh** nối tới góc dưới-trái của raster (điểm chèn IMAGE), chưa nối tới cạnh gần nhất.
10. **Kiểm thử KMZ (giải nén 349 MB)** không chạy lại ở 0.3.3, vì phần mã này không đổi so với 0.3.2 (đã kiểm ở 0.3.2, phiên C). Dữ liệu ảnh đã giải nén của 0.3.2 được dùng lại.
