# Kiểm tra BHT 0.6.35

Đã build trên Windows x64 bằng .NET Framework và AutoCAD 2024 Core Console. Lisp/DLL/bundle đồng bộ 0.6.35 / 0.6.35.0.

- Core: 233 PASS, 0 FAIL.
- Xoay đầu biển: 23 kiểm tra đạt, gồm đoạn thẳng, PL có cung cong, đảo chiều tuyến, hướng chung, UCS xoay, giữ điểm chèn/tỷ lệ XYZ/RTK/điểm gấp khúc, chống đếm trùng, bỏ qua ngoài phạm vi/chưa đặt, nối lại hai chân CAP1, block tùy chỉnh, hủy nhập/chọn rỗng, lưu hướng khi cập nhật và một Undo khôi phục cả hồ sơ/ký hiệu.
- Thư viện: 2.832 kiểm tra trên 467 mẫu đạt. Hồi quy Lisp biển báo, chữ TCVN3, đặt tự do, UCS, G/T, nhãn, nâng cấp/xóa và thao tác chọn biển đạt.
- Dấu gốc: 16 kiểm tra Lisp đạt; thêm 8 kiểm tra CAD cho block tròn đặc, layer riêng và chọn dấu qua CadView khi layer khảo sát tắt.
- Giao diện: 169 kiểm tra đạt, gồm nút xoay hàng loạt, 47 mẫu Biển phụ và bộ lọc cao tốc riêng.
- CAP1: 60 kiểm tra CAD và 6 kiểm tra lưu dữ liệu/bố trí/chân qua Lisp đạt.
- Đầu tuyến: 10 kiểm tra thao tác chọn/xác nhận/đảo/hủy đạt. Luồng TDT dùng adapter mô phỏng; chưa kiểm tra chọn đối tượng tim TdtDbAlignment thật trong AutoCAD nạp ARX TDT 9.1.

Ảnh [trước và sau xoay](HUONG_BIEN_0.6.35.png) dựng từ DXF do AutoCAD xuất. Tuyến, ký hiệu và dấu gốc dùng cùng phạm vi hiển thị ở hai ảnh; mũi tên xanh biểu diễn chiều tuyến. Kiểm tra tọa độ bằng dữ liệu CAD đã xác nhận vị trí không đổi. Ảnh minh họa không dùng dữ liệu khảo sát của dự án thực tế.

Chế độ theo tuyến cần đầu tuyến/chiều và phạm vi tham chiếu hợp lệ; `max_offset` quyết định biển đủ gần tuyến. Chế độ hướng chung nhận hai điểm trong UCS và lưu góc WCS. Hướng của block tùy chỉnh dùng quy ước +X. Cần kiểm tra kết quả trên DWG thực tế trước khi lưu và in; kiểm tra Core Console không thay cho Plot Preview theo CTB/STB.
