# Kiểm tra 0.6.42

- Core: 233 PASS.
- Street642: 19 PASS, gồm tên ngắn/dài, nội dung chính xác, WidthFactor = 1, chữ nằm trong khung, bộ nhớ đệm ổn định và chữ giữ nguyên khi bỏ nền; kiểm tra extents sau xoay.
- Marker642: 17 PASS, gồm H4/40, chiều cao 0,22 theo tỷ lệ, vị trí theo trục ký hiệu, góc dễ đọc tại bốn góc và RTK/XData không đổi.
- CAP1: 60 kiểm tra CAD và kiểm tra Lisp đạt.
- Các bài kiểm tra chạy trong AutoCAD CoreConsole riêng. Chưa kiểm tra hình ảnh trực tiếp trong phiên AutoCAD của người dùng.
- Tham khảo hình học và thuộc tính DWG gốc, không suy diễn thuật toán từ mã DLL đã biên dịch của phần mềm khác.
- Thư viện 467 mẫu: kiểm tra CAD, trụ, dấu gốc, hatch và tương tác chèn đạt (SIGN INTEGRATION PASSED).
