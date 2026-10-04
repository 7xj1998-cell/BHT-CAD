# Cài BHT 0.6.11

## Cách khuyến nghị: Application Bundle

1. Đóng AutoCAD.
2. Chạy `INSTALL_BHT.cmd`.
3. Mở AutoCAD và gõ `BTH` hoặc `BHT`.

AutoCAD tự nhận `BHT.bundle`; không chạy `NETLOAD`. Palette mở bên trái và chỉ có một phiên bản.

## Cách APPLOAD

Trước khi cài, đóng tất cả cửa sổ AutoCAD. DLL .NET đang dùng không thể được thay thế trong phiên AutoCAD hiện tại.

Nếu không muốn cài bundle, giữ `BHT-0.6.11.lsp` và ba DLL cùng thư mục `modules` trong một thư mục trên Support Path. Trong AutoCAD, `APPLOAD` duy nhất file Lisp. Lisp tự nạp DLL; sau đó gõ `BTH` hoặc `BHT`.

Từ v0.5.5 đã bỏ DCL dự phòng. Nếu Palette không mở, gõ `BHTLOAD`, kiểm tra DLL hoặc cài lại bundle và mở lại AutoCAD.

## Phông chữ CAD

Chữ CAD mặc định dùng `VNRomancUpdate.shx` với bảng mã **Unicode**. Phông được kiểm tra trên máy là SHX Unicode, có glyph riêng cho `Ê`, `ê`, `Ế`, `Ệ`; không chuyển TCVN3 cho phông này. Khi gõ trực tiếp vào TEXT có kiểu `BHT_TCVN`/`BHT_BIENBAO`, chọn Unicode trong bộ gõ. Tên kiểu `BHT_TCVN` được giữ để tương thích bản vẽ cũ. Kiểu tùy chỉnh dùng `vnromanc.shx` vẫn dùng TCVN3; Palette, CSV/Excel và hồ sơ luôn giữ Unicode.

Từ v0.6.0 cần giữ đủ thư mục modules và SHA256SUMS.txt khi giải nén. Bộ cài từ chối bundle thiếu file, file đổi hash hoặc thêm file lạ. Bản cũ được giữ trong BHT-backup-<id> để khôi phục; thư mục backup không có đuôi .bundle nên không tự nạp. Đóng AutoCAD trước khi cài. `powershell -File INSTALL_BHT.ps1 -ValidateOnly` chỉ xác minh gói.

Gói mặc định không chứa source C#. Mã Lisp vẫn đọc được; DLL vẫn có thể bị dịch ngược. SHA256 phát hiện file lệch khỏi manifest, không thay chữ ký nhà phát hành. Bản này chưa có chữ ký Authenticode.
