# QA BHT 0.6.54

- Tái hiện trước sửa: FAS bảo vệ 0.6.53, đưa thư mục runtime vào ACAD Support Path -> “bad argument type: stringp T”; API không nạp.
- Sau sửa: bootstrap qua .NET/hàng đợi LOAD, có và không có Support Path -> API 0.6.54 tương thích.
- FAS trong đường dẫn có dấu/khoảng trắng, chưa NETLOAD Bridge: đường dẫn kiểu STR, thư mục đúng, API nạp thành công.
- Cùng thư mục có FAS và LSP: giữ ưu tiên FAS.
- Loader LSP với thư mục mã nguồn trong Support Path, chưa NETLOAD Bridge: đường dẫn và API đúng.
- Build Core/Bridge/Palette thành công; 233 CoreTests đạt.
- FAS biên dịch thành công; Core/Bridge được bảo vệ theo pipeline hiện hành.

Script: run_bootstrap653.ps1 -WithSupportPath và run_loadpaths654.ps1 trong tests/IntegrationTests.
Kiểm thử bằng AutoCAD 2024 Core Console cô lập; không cài đè DLL vào CAD người dùng.
Bộ cài/roundtrip runtime được kiểm tra sau package; log tại build/v0.6.54.
