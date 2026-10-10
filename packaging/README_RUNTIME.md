# BHT — bản runtime
Cài bằng BHT-Setup hoặc INSTALL_BHT.cmd, sau khi đóng tất cả phiên AutoCAD.
Mở lại CAD rồi dùng lệnh BHT/BTH.

Gói này gồm Lisp biên dịch FAS và ba DLL. Core/Bridge được làm rối tên nội bộ; DLL giao diện giữ tên để tương thích. Gói không chứa mã nguồn nghiệp vụ, PDB hoặc bản đồ tên debug.
Các file PowerShell/CMD chỉ phục vụ cài đặt và kiểm tra thư viện.

Giữ nguyên cấu trúc BHT.bundle. Khi nạp thủ công, dùng BHT-<phiên bản>.fas trong Contents/Windows, không tìm file LSP.
Yêu cầu Windows, AutoCAD 2021–2024 theo manifest; đã kiểm tra runtime trên AutoCAD 2024. LISPSYS=1; đổi biến này cần khởi động lại CAD.
Việc biên dịch/làm rối tăng chi phí đọc ngược, không chống sao chép tuyệt đối và không bảo vệ riêng các block DWG.
