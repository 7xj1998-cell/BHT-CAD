# Kiểm tra 0.6.46

- Core: 233 PASS.
- Thư viện đèn: nhập các DWG, màu đèn tín hiệu, chèn và xoay; nhóm DEN cũ giữ nguyên, DEN_CS/DEN_TH lưu đúng và dùng đúng block, RTK không đổi.
- Trụ mất mặt biển: dùng block trụ riêng, nhãn đúng, không có nhãn mặt phụ cũ, giữ mã, đổi tình trạng khôi phục mặt biển và RTK không đổi.
- Kiểm tra chạy trong AutoCAD CoreConsole; chưa kiểm tra trực quan trên bản vẽ đang mở của người dùng.
- Giao diện và luồng hồ sơ: 683 PASS, gồm hai nhóm đèn, nút chọn mẫu chỉ hiện đúng nhóm và các mẫu trỏ tới DWG có thật.
