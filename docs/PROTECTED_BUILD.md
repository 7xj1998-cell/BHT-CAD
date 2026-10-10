# Quy trình build runtime bảo vệ
1. Tăng VERSION bằng scripts/set-version.ps1.
2. scripts/build.ps1 -UseCsc -Test -OutDir build\v<VERSION>\bin-private (dùng đường dẫn tuyệt đối khi chạy).
3. scripts/compile-lisp.ps1 -OutDir build\v<VERSION>\compiled.
4. scripts/protect-dotnet.ps1 -BinDir <bin-private> -OutDir <bin-protected>.
5. Chạy CoreTests với DLL protected; run_signs, run_lights, run_palette_layout với BinDir protected và RuntimePath trỏ FAS.
6. scripts/package.ps1 -SkipBuild -ProtectedRuntime -BinDir <bin-protected> -CompiledLisp <FAS> -OutRoot <build/release-vVERSION>. Không dùng IncludeSource.
7. Kiểm tra bundle độc lập không có LSP/source, mở bản vẽ, xuất API Lisp/.NET, nạp lại phiên khác và kiểm thử bộ cài.

## Công cụ
Obfuscar 2.2.50 (MIT), tải từ https://api.nuget.org/v3-flatcontainer/obfuscar/2.2.50/obfuscar.2.2.50.nupkg .
SHA256 nupkg: 8790E1E36D613613311EC512129A6701C63576428692F20A95988A351FDC3187.
SHA256 tools/Obfuscar.Console.exe: 859C554A0AE0C6F6E45DAEC6A6190EE8772855C6D242717FBA0898B4118DE881.
Bản công cụ nằm ngoài repo, truyền Obfuscar khi dùng máy khác. Không đóng gói công cụ hoặc Mapping.xml cho khách.
Giữ bin-private, compiled/runtime-private.lsp, protection-private/Mapping.xml và source trong kho nội bộ.

## Phạm vi
FAS chạy trong document namespace, giữ vl-acad-defun cho .NET. Foundation tìm runtime FAS hoặc lấy thư mục từ Bridge.
Obfuscar giữ public API, không mã hóa chuỗi, không đổi tên property/event; đổi tên nội bộ Core/Bridge. Palette giữ nguyên vì UI/reflection có ràng buộc tên. Đây là mức bảo vệ có giới hạn, chưa triển khai VLX, ARX native, ký số hay giấy phép.
Gói protected và gói source không phát hành chung. Các bản cũ chứa nguồn đã bàn giao không được bảo vệ hồi tố.
