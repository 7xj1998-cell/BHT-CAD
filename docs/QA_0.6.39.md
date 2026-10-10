# Kiểm tra 0.6.39 — 10/10/2026

- Core 233 PASS; quản lý tuyến 19 PASS, gồm lệnh sửa/xóa và Undo.
- Lý trình 9 PASS: thiếu mốc/thiếu tuyến giữ nguyên hồ sơ, lỗi ID, chỉ cập nhật hồ sơ được chọn; nội suy XY và độ lệch, đảo thứ tự cọc, cọc trùng, cùng lý trình, điểm ngoài khoảng.
- Lệnh BHTKM2COC trong AutoCAD CoreConsole trả Km45+250.00 cho điểm cách 25% đoạn cọc Km45+000 đến Km46+000; không tạo tuyến hoặc ghi hồ sơ.
- Bộ thư viện biển/đèn, hướng biển và route-start đã chạy đạt trong 0.6.38; không sửa các thuật toán đó ở 0.6.39. Xem QA_0.6.38.md về phạm vi và giới hạn.
- Chưa thay DLL đang nạp trong AutoCAD người dùng. Không thay đổi đường PL thử nghiệm hay coi đó là tim tuyến thực. Cần đóng AutoCAD rồi cài bản mới.
- Giao diện/nội dung: 663 kiểm tra đạt. Loại lượt RefreshAll trùng trong callback tính lý trình; CallLisp tự làm mới sau khi trả kết quả.
