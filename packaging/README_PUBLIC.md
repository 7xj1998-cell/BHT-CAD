# BHT 0.6.55 — gói công khai kèm mã nguồn GPL-3.0-only

Đây là bản phát triển Mốc 1, chưa nghiệm thu máy sạch hoặc người dùng độc lập. Chỉ kiểm thử AutoCAD 2024.

Chạy INSTALL_BHT.cmd sau khi đóng toàn bộ AutoCAD. Gói có DLL BHT và loader/module AutoLISP đọc được; mã nguồn tương ứng nằm trong source/BHT-CAD. Xem LICENSE và COPYING_SCOPE.md.

## Các thành phần không kèm theo

Không có DWG/phông/ảnh thư viện ADSCivil/TDT; không có ảnh preview nhúng chưa xác minh nguồn. Không có DLL Autodesk. Vì vậy không cam kết đủ 467 mẫu biển hoặc đủ mẫu đèn chiếu sáng. Các chức năng cần tài nguyên đó phải dùng thư viện được cài hợp lệ trên máy hoặc nguồn DWG được người dùng cung cấp hợp lệ.

Phông mặc định VNRomancUpdate.shx không được kèm trong gói này. Máy thiếu phông có thể thay thế và hiển thị khác; cần kiểm tra chữ trước khi in. Gói không tự thay cấu hình chữ trong dữ liệu hiện trạng.

## Build lại

Trong source/BHT-CAD, đọc README.md và docs/AI_HANDOFF.md. Dùng scripts/build.ps1 -UseCsc -Test -PublicDistribution với -AcadDir trỏ đến AutoCAD 2024 hợp lệ; sau đó scripts/package.ps1 -PublicDistribution -IncludeSource -SkipBuild -BinDir trỏ đến kết quả build.

Không dùng -ProtectedRuntime cho gói công khai này. Bộ cài đầy đủ từng giao cục bộ có thư viện ngoài không phải là gói công khai này.
