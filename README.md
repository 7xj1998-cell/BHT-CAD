# BHT v0.6.8 — Quản lý hiện trạng tuyến

BHT là ứng dụng AutoLISP + .NET cho AutoCAD trên Windows, quản lý điểm RTK, hồ sơ đối tượng, ảnh hiện trường, tuyến/lý trình và báo cáo.

## Cài đặt

Giải nén đầy đủ `BHT-0.6.8.zip`, đóng toàn bộ AutoCAD và chạy `INSTALL_BHT.cmd`. Mở CAD, gõ `BHT` hoặc `BTH` để mở bảng. Kiểm tra tiêu đề hiển thị 0.6.8.

Phông mặc định là `VNRomancUpdate.shx`, dùng Unicode NFC. Hồ sơ, CSV và báo cáo giữ Unicode. Phông cũ `vnromanc.shx` chỉ dùng TCVN3 tại lớp hiển thị khi chọn kiểu cũ.

## Các thay đổi chính của v0.6.8

- Đã bỏ 14 bí danh Lisp và hai bí danh mở bảng. Xem [lệnh thay thế](docs/COMMANDS_0.6.8.md) để cập nhật script CAD.
- Đã chặn mã tốc độ và giá trị mét sai trước khi chèn biển, tránh dùng số mặc định thay cho giá trị nhập sai.
- Đã giới hạn bộ chọn ở 20 mặt/trụ và kiểm tra từng mã trước khi xác nhận cụm biển.
- Đã kiểm tra danh mục theo mã, tránh khớp tiền tố sang một biển khác; mã gốc không có chữ biến thể vẫn chọn được biến thể đầu tiên.
- Đã kiểm tra tên block của cụm biển, bỏ một control không sử dụng và loại tệp biên dịch khỏi mã nguồn đóng gói.
- Đã đồng bộ phiên bản trong hướng dẫn cài đặt và bổ sung kiểm tra để phát hiện README ghi sai phiên bản.

Xem [hướng dẫn sử dụng](docs/HUONG_DAN.md), [cài đặt](packaging/README_INSTALL.md), [ghi chú phát hành](docs/RELEASE_NOTES_0.6.8.md) và [hợp đồng dữ liệu](docs/DATA_CONTRACT.md).

## Mã nguồn và build

- `src/lisp/BHT-0.6.8.lsp`: loader duy nhất, với 12 module trong `src/lisp/modules`.
- `src/dotnet`: BHT.Core, BHT.Bridge và BHT.Palette; phiên bản assembly `0.6.8.0`.
- `scripts`: build, kiểm phiên bản, đóng gói và kiểm thư viện TDT.
- `tests`: Core, tích hợp CAD và bộ cài; `.github/workflows` chạy Core trên Windows.
- `packaging`: Application Bundle và trình cài PowerShell.

Cần .NET Framework 4.8 và DLL tham chiếu từ thư mục AutoCAD của máy phát triển. Mục tiêu hỗ trợ AutoCAD 2021–2024 x64; kiểm thử tích hợp dùng AutoCAD 2024.

```powershell
./scripts/check-version.ps1
./scripts/build.ps1 -AcadDir 'D:\AutoCAD 2024' -OutDir 'build\v0.6.8\bin' -UseCsc -Test
./tests/IntegrationTests/run_signs.ps1 -SkipBuild
./tests/IntegrationTests/run_offline.ps1
./tests/ReleaseTests/installer-security.ps1
./scripts/package.ps1 -AcadDir 'D:\AutoCAD 2024' -BinDir 'build\v0.6.8\bin' -SkipBuild -IncludeSource
```

Kết quả kiểm thử và giới hạn nghiệm thu được ghi trong ghi chú phát hành. CI chỉ kiểm tra Core vì runner không có DLL AutoCAD; plugin được build và kiểm tra trên máy có AutoCAD.

Không đưa DLL Autodesk, kết quả build, bản vẽ, ảnh/dữ liệu khảo sát, phông sao chép cục bộ hoặc ZIP vào cây mã nguồn. Các gói tải xuống nằm ở Releases.
