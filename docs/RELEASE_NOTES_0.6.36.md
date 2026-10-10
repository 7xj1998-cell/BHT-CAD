# BHT 0.6.36

## 0.6.36 — 2026-10-09

- Giảm thời gian mở/chọn biển: chia 60 biển mỗi trang, chỉ nạp ảnh thu nhỏ đang nhìn thấy, giải phóng ảnh ngoài vùng xem; gộp tìm kiếm khi gõ nhanh.
- Sửa lỗi Sequence contains no elements khi đóng hoặc đổi kích thước thư viện; ngừng nạp ảnh trong lúc hủy cửa sổ và đổi trang.
- Đổi phần CAP1 thành tùy chọn Bố trí khung/trụ nâng cao trong Nội dung biển. Mặc định ẩn, vẫn giữ bố trí đã lưu trong bản vẽ cũ.
- Thêm Nạp DWG… để chọn block riêng cho hồ sơ và thư viện 7 mẫu đèn: chiếu sáng đơn, đôi, trang trí, mặt đứng trái/phải, tín hiệu ba màu và cảnh báo vàng.
- Năm mẫu chiếu sáng được chuẩn hóa từ thư viện CAD có sẵn; hai mẫu tín hiệu do BHT tạo. Thư viện được đóng gói để dùng độc lập, không cần cài phần mềm nguồn.
- Chưa thay đổi cách xoay vuông góc theo đường tham chiếu; xử lý ở đợt tiếp theo.


## Thư viện đèn và chọn biển nhanh — 0.6.36

Thư viện biển hiển thị tối đa 60 mẫu mỗi trang. Dùng Trang trước / Trang sau hoặc gõ mã để tìm trên toàn bộ danh mục. Ảnh xem trước chỉ nạp khi cần; không phải chờ toàn bộ ảnh của thư viện.

Để dùng đèn: chọn hoặc tạo hồ sơ nhóm DEN, bấm **Nạp DWG…** tại phần block tùy chỉnh. Hộp chọn mở thư mục **LightLibrary**. Chọn mẫu, bấm **Lưu**, sau đó **Chèn / cập nhật ký hiệu**. Mẫu chỉ gán cho hồ sơ đang sửa. Có thể chọn DWG khác ngoài thư viện.

- DEN_CS_DON_MB: đèn đơn, mặt bằng.
- DEN_CS_DOI_MB: đèn đôi, mặt bằng.
- DEN_CS_TRANG_TRI_MB: đèn trang trí, mặt bằng.
- DEN_CS_TRAI_MD / DEN_CS_PHAI_MD: mặt đứng cột đèn, cần trái / phải.
- DEN_TIN_HIEU_3_MAU: ký hiệu đèn giao thông ba màu, BHT tạo.
- DEN_CANH_BAO_VANG: ký hiệu đèn cảnh báo vàng, BHT tạo.

Các mẫu là ký hiệu 2D, không thay thế chi tiết cấu tạo hay kích thước thiết kế thực tế. Chọn mẫu MB khi bố trí trên bình đồ, MD khi cần hình mặt đứng. Điểm gốc block đặt tại chân/tâm trụ; điều chỉnh tỷ lệ theo bản vẽ. Việc gán mẫu không thay đổi tọa độ RTK.

Trong **Nội dung biển**, phần **Bố trí khung/trụ nâng cao** mặc định tắt. Bật khi cần bố trí nhiều mặt hoặc khung/trụ CAP1. Hồ sơ cũ có CAP1 vẫn mở lại đúng chế độ; bỏ chọn sẽ chuyển sang bố trí thường khi lưu.

Sau khi cài bản mới cần khởi động lại AutoCAD để nạp DLL mới; DLL đã nạp trong phiên CAD hiện tại không tự thay thế.
