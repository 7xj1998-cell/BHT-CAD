# BHT 0.4.6

Bản 0.4.6 làm gọn cách trình bày điểm RTK và đổi Palette theo phong cách tối phù hợp AutoCAD.

## Thay đổi chính

- Palette nền than–xanh, nút chữ vàng, thông tin cyan; năm thẻ chuyển thành thanh dọc sát mép phải.
- Bản vẽ mới dùng kiểu chữ `BHT_RTK` Arial Unicode rộng 0,85 để cụm tên–mô tả–cao độ gọn hơn.
- Bản vẽ cũ giữ kiểu chữ và vị trí nhãn; cập nhật phần mềm không tự dời nhãn legacy.
- Dấu X vẫn đúng tâm và có kích thước 1 unit; BHT không di chuyển hoặc làm tròn tọa độ RTK.
- Bổ sung tài liệu đối chiếu cách trình bày điểm của TDT 9.1 bản thường và DPSurvey 3.3.

## Kiểm thử

- Core: **62 PASS, 0 FAIL**.
- AutoCAD Core Console: **172 PASS, 0 FAIL, 1 BLOCKED**.
- BLOCKED duy nhất là mở DCL vì Core Console không có giao diện; Palette/DCL được đưa vào checklist nghiệm thu thủ công.

## Cài đặt

Đóng toàn bộ AutoCAD, giải nén ZIP và chạy `INSTALL_BHT.cmd`. Nếu dùng cách di động, đặt
`BHT-0.4.6.lsp` cùng ba DLL rồi APPLOAD duy nhất file Lisp.

TDT chỉ dùng bản thường tại `C:\Program Files (x86)\TDT Solution 2022\`. Release không chứa tài sản TDT.
