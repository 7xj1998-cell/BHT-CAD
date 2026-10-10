# BHT 0.6.49

## Nhãn cọc tiêu
Nhãn H/Km nằm dưới ký hiệu và quay cùng góc block. Sau khi cài và khởi động lại CAD, chọn hồ sơ rồi **Chèn / cập nhật** để sửa nhãn cũ.

## Nhập cọc một lần
Nhập Số Km (và H đối với cọc tiêu có số), sau đó lưu hồ sơ. Lý trình của cọc được xác định ngay, kể cả khi chưa có tuyến. Ví dụ H5/49 là Km49+500.

Khi tính tuyến, BHT lấy các cọc có số làm mốc nếu điểm khảo sát nằm trong phạm vi lệch cho phép của duy nhất một tuyến. Hai mốc cho phép nội suy dọc Polyline; chỉ một mốc vẫn cần chiều tăng Km và giới hạn ngoại suy. Không có tuyến thì không suy đoán đường cong từ hai cọc.

**BHTMOCKM** dành cho mốc bổ sung ngoài hồ sơ hoặc điểm gãy lý trình. **BHTDSMOC** hiển thị cả mốc tự lấy từ hồ sơ; sửa/xóa mốc tự động tại hồ sơ cọc. Mốc trùng vị trí/giá trị được gộp; giá trị mâu thuẫn được báo, không cho kết quả giả.

Nếu nhiều tuyến cùng bao phủ cọc, kiểm tra phạm vi lệch của tuyến hoặc khai báo mốc riêng. Không tự chọn tuyến trong trường hợp này.

Sau khi sửa/xóa cọc, chạy **Tính tuyến / Cập nhật lý trình** để làm mới kết quả đã lưu của đối tượng khác. Tọa độ RTK, hình học tuyến và mốc thủ công không bị sửa.
