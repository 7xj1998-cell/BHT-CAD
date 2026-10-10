# Kiểm tra BHT 0.6.34

Đã build trên Windows x64 với .NET Framework và AutoCAD 2024 Core Console. Phiên bản Lisp/DLL/bundle đồng bộ 0.6.34 / 0.6.34.0.

- Core: 233 PASS, 0 FAIL.
- Dấu gốc biển: 16 kiểm tra Lisp đạt, gồm tọa độ XYZ RTK, đổi vị trí/góc biển, đặt tại G, đường dẫn gấp khúc, ẩn layer điểm, tỷ lệ, bỏ nền, chống trùng, gỡ điểm và xóa hồ sơ. Thêm 8 kiểm tra CAD cho block tròn đặc, layer riêng và chọn dấu để nhận hồ sơ qua CadView.
- Giao diện: 168 kiểm tra đạt. Bộ lọc Biển phụ hiển thị đủ 47 mã S., trở về dòng đầu danh sách khi đổi bộ lọc; nhóm cao tốc không lẫn mã S.
- Đầu tuyến: 10 kiểm tra thao tác chọn/xác nhận/đảo/hủy đạt; PL thường, UCS xoay, giữ mốc và đánh dấu kiểm tra lại. Luồng tạo/cập nhật TDT dùng adapter mô phỏng trong kiểm tra này, chưa chạy chọn tim TdtDbAlignment thật trong AutoCAD có ARX TDT 9.1.
- Route Model V5: 12 PASS, 0 FAIL; tuyến mở/kín, đảo chiều, lý trình/offset/phía, mốc, đọc TEXT Km bằng Bridge và chẩn đoán thay đổi hình học.
- Đợt hồi quy trước khi chỉnh bộ lọc: 2.832 kiểm tra thư viện trên 467 mẫu đạt; Lisp biển báo, TCVN3, UCS, G/T, nâng cấp/xóa và CAP1 đạt. CAP1 có 60 kiểm tra CAD và 6 kiểm tra RTK/Lisp. Các chỉnh sửa bộ lọc sau đó đã được kiểm tra riêng trên giao diện.

Xem [dấu tròn khi ẩn layer điểm](DAU_GOC_BIEN_0.6.34.png) và [nhóm Biển phụ](BIEN_PHU_0.6.34.png). Ảnh dấu tròn dựng từ DXF do AutoCAD xuất, với layer điểm RTK đã tắt và nền biển đã bỏ. Dấu của biển đặt lệch ở đầu đường dẫn; dấu của biển đặt tại G ở ngay chân hình biển.

Bật `FILLMODE = 1` rồi REGEN để thấy phần đặc. Hình xem trước không thay thế Plot Preview theo CTB/STB của hồ sơ. Đầu tuyến và chiều tăng cần người dùng chọn; lý trình Km cần mốc đã xác nhận, không suy ra từ hình dạng PL.
