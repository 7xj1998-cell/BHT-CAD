# Kiểm tra BHT 0.6.36

- Build C# 5 / .NET Framework, tham chiếu AutoCAD 2024: thành công; Core: 233 PASS.
- Giao diện: 175 kiểm tra PASS. Native picker: PASS. CAP1: 60 kiểm tra CAD và bài Lisp PASS.
- Ba lần mở trong CoreConsole: 233 / 191 / 301 ms; 16 ảnh, 2.985.984 byte pixel mỗi lần. Trước tối ưu từng ghi nhận khoảng 1,2 GB pixel và 3,6–4,9 giây mở. Đây là bài đo cục bộ, không phải đo trên bản vẽ người dùng.
- Hồi quy lỗi cửa sổ: đổi trang, resize, lọc không có kết quả, lọc lại, Dispose khi còn hiển thị, Close và Dispose lặp; không phát sinh ThreadException trong cả ba lượt.
- Thư viện đèn: 31 kiểm tra CAD PASS; bốn kiểm tra Lisp PASS về chèn, giữ RTK và trục hướng. File nguồn không đổi, nạp lại không tạo block trùng, không có proxy.
- Ảnh kiểm tra bảy mẫu: DEN_0.6.36.png, kết xuất từ DXF của các DWG chuẩn hóa.
- Chưa kiểm tra thao tác trực tiếp trên bản vẽ người dùng. Xoay vuông góc theo đường tham chiếu chưa nằm trong bản này.
