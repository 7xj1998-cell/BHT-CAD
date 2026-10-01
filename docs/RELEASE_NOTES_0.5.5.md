# BHT v0.5.5 — Gỡ giao diện DCL dự phòng

Ngày 01/10/2026. Lisp BHT-0.5.5.lsp; DLL 0.5.5.0.

Palette .NET là giao diện chính. Bản này bỏ BHTDCL/BHTUITEST và mã giao diện DCL; giảm 254 dòng. Các hàm tìm kiếm biển không dấu, nhập tình trạng, xem trạng thái và 67 lệnh Lisp còn lại được giữ.

Nếu Palette chưa mở, gõ BHTLOAD, kiểm tra BHT.Palette.dll/BHT.Bridge.dll/BHT.Core.dll cạnh file Lisp hoặc cài lại bundle, rồi mở lại AutoCAD. Không còn bảng DCL dự phòng. Sửa BHTTEST để không gọi helper DCL đã bỏ.

Build và 122 kiểm tra Core đạt; các phiên REVIEW/S0/V5, kiểm thử biển báo/phông/chèn tự do và WinForms picker đạt. TX chưa chạy vì thiếu bản vẽ proxy mẫu. Xem [kết quả phân tích review](REVIEW_RESOLUTION_0.5.5.md).

Cài đặt: giải nén BHT-0.5.5.zip, đóng AutoCAD, chạy INSTALL_BHT.cmd rồi mở AutoCAD và gõ BTH/BHT. Phông mặc định tiếp tục là VNRomancUpdate.shx Unicode; thao tác chọn hướng và điểm trung gian vẫn theo [v0.5.3](RELEASE_NOTES_0.5.3.md). Bản mới chưa tự cài vào phiên đang mở.
