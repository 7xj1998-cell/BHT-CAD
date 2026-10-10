# Cài BHT 0.6.53

## Bộ cài một file để gửi

Gửi duy nhất **BHT-Setup-0.6.53.exe**. Người nhận đóng AutoCAD, mở file và bấm **Cài đặt BHT**. File tự giải nén vào thư mục tạm, kiểm tra dữ liệu, cài bundle và phông chữ cho tài khoản Windows hiện tại. Không cần quyền quản trị, không cần giữ file phụ cạnh EXE. Có thể giữ EXE để cài lại.

Máy nhận cần Windows 64-bit, .NET Framework 4.8 và AutoCAD tương thích. Bundle khai báo AutoCAD 2021–2024; đã kiểm tra trên AutoCAD 2024. AutoCAD dùng nền tảng .NET khác cần bản build phù hợp. Bộ cài BHT không cài AutoCAD hoặc TDT; mẫu CAD đầy đủ từ thư viện TDT cần TDT 9.1 trên máy khi tạo lần đầu, các mẫu đã lưu trong DWG vẫn được dùng lại.

Khi cài thành công, cửa sổ báo **Đã cài đặt BHT** và chỉ còn nút **Hoàn tất** để đóng. Nút cài đặt được ẩn và khóa để tránh cài lặp trong cùng cửa sổ. Nếu cài lỗi, nút cài đặt vẫn còn để thử lại.

Mở lại AutoCAD và gõ **BHT** hoặc **BTH**. Bộ cài giữ bản BHT cũ trong thư mục backup và từ chối cập nhật khi AutoCAD đang chạy. File EXE chưa có chữ ký Authenticode; không thay đổi thiết lập bảo vệ của Windows.

`BHT-Setup-0.6.53.exe --validate-only --report <đường-dẫn-tệp>` chỉ kiểm tra bộ cài, không cài vào máy. Nhật ký xác minh ghi vào tệp được chỉ định.

## Cách dùng gói ZIP: Application Bundle

1. Giải nén đầy đủ `BHT-0.6.53.zip` và đóng AutoCAD.
2. Chạy `INSTALL_BHT.cmd` trong thư mục đã giải nén. File CMD cần bundle, PowerShell và manifest đi kèm; không gửi riêng CMD.
3. Mở AutoCAD và gõ `BTH` hoặc `BHT`.

AutoCAD tự nhận `BHT.bundle`; không chạy `NETLOAD`. Palette mở bên trái và chỉ có một phiên bản.

## Cách APPLOAD

Trước khi cài, đóng tất cả cửa sổ AutoCAD. DLL .NET đang dùng không thể được thay thế trong phiên AutoCAD hiện tại.

Nếu không muốn cài bundle, giữ `BHT-0.6.53.lsp` và ba DLL cùng thư mục `modules` trong một thư mục trên Support Path. Trong AutoCAD, `APPLOAD` duy nhất file Lisp. Lisp tự nạp DLL; sau đó gõ `BTH` hoặc `BHT`.

Từ v0.5.5 đã bỏ DCL dự phòng. Nếu Palette không mở, gõ `BHTLOAD`, kiểm tra DLL hoặc cài lại bundle và mở lại AutoCAD.

## Phông chữ CAD

Chữ CAD mặc định dùng `VNRomancUpdate.shx` với bảng mã **Unicode**. Phông được kiểm tra trên máy là SHX Unicode, có glyph riêng cho `Ê`, `ê`, `Ế`, `Ệ`; không chuyển TCVN3 cho phông này. Khi gõ trực tiếp vào TEXT có kiểu `BHT_TCVN`/`BHT_BIENBAO`, chọn Unicode trong bộ gõ. Tên kiểu `BHT_TCVN` được giữ để tương thích bản vẽ cũ. Kiểu tùy chỉnh dùng `vnromanc.shx` vẫn dùng TCVN3; Palette, CSV/Excel và hồ sơ luôn giữ Unicode.

Từ v0.6.0 cần giữ đủ thư mục modules và SHA256SUMS.txt khi giải nén. Bộ cài từ chối bundle thiếu file, file đổi hash hoặc thêm file lạ. Bản cũ được giữ trong BHT-backup-<id> để khôi phục; thư mục backup không có đuôi .bundle nên không tự nạp. Đóng AutoCAD trước khi cài. `powershell -File INSTALL_BHT.ps1 -ValidateOnly` chỉ xác minh gói.

Gói mặc định không chứa source C#. Mã Lisp vẫn đọc được; DLL vẫn có thể bị dịch ngược. SHA256 phát hiện file lệch khỏi manifest, không thay chữ ký nhà phát hành. Bản này chưa có chữ ký Authenticode.
