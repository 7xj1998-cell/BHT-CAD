# BHT 0.6.22 — 08/10/2026

Đã tạo bộ cài **BHT-Setup-0.6.22.exe**, chỉ một file để gửi sang máy khác. Người nhận đóng AutoCAD, mở EXE và bấm **Cài đặt BHT**. Bộ cài đã kèm DLL, Lisp, modules và phông chữ; tự giải nén và kiểm tra dữ liệu trước khi cài cho tài khoản Windows hiện tại. Không cần quyền quản trị.

File INSTALL_BHT.cmd vẫn dùng được trong gói ZIP đầy đủ. Nếu gửi riêng CMD, bộ cài sẽ thiếu dữ liệu. Gói ZIP có mã nguồn vẫn được giữ để lưu trữ và bàn giao.

Máy nhận cần Windows 64-bit, .NET Framework 4.8 và AutoCAD tương thích. Bundle khai báo AutoCAD 2021–2024; đã kiểm tra trên AutoCAD 2024. Các phiên bản AutoCAD khác cần bản build phù hợp. Bộ cài BHT không cài AutoCAD hoặc TDT. Xem [hướng dẫn cài đặt](../packaging/README_INSTALL.md).

Giữ các chức năng và dữ liệu của 0.6.21, gồm tỷ lệ hình/nhãn riêng, bố cục hồ sơ, nhãn nhiều mặt và sửa nét biển.


Đã đạt 171 kiểm thử Core, hồi quy ký hiệu/Unicode/G/T trên AutoCAD 2024, 7 kiểm tra bộ cài cũ và kiểm tra bộ cài EXE: đứng một mình trong đường dẫn có dấu/khoảng trắng, giải nén đúng, từ chối đường dẫn sai và dữ liệu hỏng, bố cục form, đóng không cài, xác minh không đổi BHT đang cài. Chưa kiểm tra trực tiếp trên một máy Windows khác.
