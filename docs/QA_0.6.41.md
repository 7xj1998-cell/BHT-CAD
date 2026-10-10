# Kiểm tra 0.6.41

- Core: 233 PASS; xoay hướng: 25 PASS, gồm nối lại đúng hai chân CAP1 sau xoay.
- Nối nhiều trụ: 7 PASS mới, gồm hai đường độc lập, nét mảnh liên tục, vuông góc sau xoay, dấu gốc cho nhóm Khác, hai chân đặc trong block, cập nhật không tạo trùng và giữ nguyên RTK/XData.
- run_signs với BHT_TEST_ADS=1 kiểm tra thư viện 467 mẫu, trụ, gốc, hatch và tương tác chèn đạt. Các bài kiểm tra đường dẫn được cập nhật để nhận cả LINE lẫn LWPOLYLINE; giữ kiểm tra điểm đầu RTK/điểm cuối chân trụ.
- Kiểm thử trong AutoCAD CoreConsole riêng; chưa sửa bản vẽ đang mở của người dùng. Các đường đi qua điểm trung gian do người dùng chỉ định được giữ nguyên; không cam kết tự tránh mọi đối tượng khác trên bình đồ.