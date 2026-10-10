# BHT 0.6.39

## 0.6.39 — 10/10/2026

- Sửa nút Tính tuyến cạnh ô lý trình: chỉ tính hồ sơ đang chọn; luôn hiện kết quả hoặc thông báo nguyên nhân thiếu dữ liệu. Không ghi đè lý trình cũ khi thiếu tuyến, thiếu mốc Km hoặc không chiếu được vị trí.
- Thêm Kiểm tra 2 cọc Km (`BHTKM2COC`) trong Tuyến & báo cáo. Chọn hai cọc, nhập lý trình, chọn điểm cần tính: nội suy theo hình chiếu lên đoạn thẳng nối cọc trong mặt phẳng XY. Kết quả ghi rõ ƯỚC TÍNH, kèm độ lệch và khoảng cách; không tự ghi hồ sơ và không ngoại suy ngoài hai cọc.
- Các lệnh lý trình/nhập mốc mở bảng kết quả kể cả khi thông báo ngắn. Chức năng Cập nhật lý trình ở tab Tuyến vẫn áp dụng toàn bộ hồ sơ theo tuyến tham chiếu.
- Bao gồm quản lý tuyến, chọn/làm sáng và sửa/xóa/chọn lại tuyến của 0.6.38.

Không có tim tuyến thực thì hai cọc không xác định được chiều dài đường cong. PL vẽ thử không được xem là cơ sở lý trình thiết kế. Chỉ dùng kết quả hai cọc cho đoạn đủ thẳng sau khi kiểm tra; muốn ghi vào hồ sơ dùng Ghi tay và chịu trách nhiệm xác nhận giá trị.