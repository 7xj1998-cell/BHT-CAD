# Cài BHT 0.4.1

## Cách khuyến nghị: Application Bundle

1. Đóng AutoCAD.
2. Chạy `INSTALL_BHT.cmd`.
3. Mở AutoCAD và gõ `BTH` hoặc `BHT`.

AutoCAD tự nhận `BHT.bundle`; không chạy `NETLOAD`. Palette mở bên trái và chỉ có một phiên bản.

## Cách APPLOAD

Nếu không muốn cài bundle, giữ `BHT-0.4.1.lsp` và ba DLL trong cùng một thư mục. Trong AutoCAD, `APPLOAD` duy nhất file Lisp. Lisp tự nạp DLL; sau đó gõ `BTH` hoặc `BHT`.

`BHTDCL` chỉ là giao diện dự phòng. Không dùng lệnh này trong quy trình thông thường.
