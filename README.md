# BHT v0.6.13 — Quản lý hiện trạng tuyến

BHT là ứng dụng AutoLISP + .NET cho AutoCAD trên Windows, quản lý điểm RTK, hồ sơ đối tượng, ảnh hiện trường, tuyến/lý trình và báo cáo.

## Cài đặt

Giải nén đầy đủ `BHT-0.6.13.zip`, đóng toàn bộ AutoCAD và chạy `INSTALL_BHT.cmd`. Mở CAD, gõ `BHT` hoặc `BTH` để mở bảng. Kiểm tra tiêu đề hiển thị 0.6.11.

Phông mặc định là `VNRomancUpdate.shx`, dùng Unicode NFC. Hồ sơ, CSV và báo cáo giữ Unicode. Phông cũ `vnromanc.shx` chỉ dùng TCVN3 tại lớp hiển thị khi chọn kiểu cũ.

## Các thay đổi chính của v0.6.13

- Chọn hướng trên CAD đúng phía đầu cọc; hỗ trợ UCS xoay và giữ ý nghĩa góc WCS.
- Biển I.439 giữ khung đôi, phông Giaothong1 và nền xanh của mẫu cũ; tự ghép dòng lý trình–tên đường.

- Tách đúng R.415a/b và W.239a/b, sửa ảnh biển và hình CAD bị sai, giữ biểu tượng trên nền tô màu.
- Nhập tên cầu, lý trình và tên đường ngay trong bảng chọn I.439, xem trước nội dung và lưu cùng hồ sơ.
- Cọc tiêu có tùy chọn Km/H để hiện H9/39 và tự ghi lý trình; cọc Km hiển thị số trong block, bắt điểm giữa thanh đen. Cọc không cần nhãn đã được ẩn nhãn.
- Giữ các bản sửa đọc cọc TDT và mũi tên tuyến từ v0.6.9; giữ các lệnh tinh giản từ v0.6.8.

Xem [hướng dẫn sử dụng](docs/HUONG_DAN.md), [cài đặt](packaging/README_INSTALL.md), [ghi chú phát hành](docs/RELEASE_NOTES_0.6.11.md) và [hợp đồng dữ liệu](docs/DATA_CONTRACT.md).

## Mã nguồn và build

- `src/lisp/BHT-0.6.13.lsp`: loader duy nhất, với 12 module trong `src/lisp/modules`.
- `src/dotnet`: BHT.Core, BHT.Bridge và BHT.Palette; phiên bản assembly `0.6.13.0`.
- `scripts`: build, kiểm phiên bản, đóng gói và kiểm thư viện TDT.
- `tests`: Core, tích hợp CAD và bộ cài; `.github/workflows` chạy Core trên Windows.
- `packaging`: Application Bundle và trình cài PowerShell.

Cần .NET Framework 4.8 và DLL tham chiếu từ thư mục AutoCAD của máy phát triển. Mục tiêu hỗ trợ AutoCAD 2021–2024 x64; kiểm thử tích hợp dùng AutoCAD 2024.

```powershell
./scripts/check-version.ps1
./scripts/build.ps1 -AcadDir 'D:\AutoCAD 2024' -OutDir 'build\v0.6.11\bin' -UseCsc -Test
./tests/IntegrationTests/run_signs.ps1 -SkipBuild
./tests/IntegrationTests/run_offline.ps1
./tests/ReleaseTests/installer-security.ps1
./scripts/package.ps1 -AcadDir 'D:\AutoCAD 2024' -BinDir 'build\v0.6.11\bin' -SkipBuild -IncludeSource
```

Kết quả kiểm thử và giới hạn nghiệm thu được ghi trong ghi chú phát hành. CI chỉ kiểm tra Core vì runner không có DLL AutoCAD; plugin được build và kiểm tra trên máy có AutoCAD.

Không đưa DLL Autodesk, kết quả build, bản vẽ, ảnh/dữ liệu khảo sát, phông sao chép cục bộ hoặc ZIP vào cây mã nguồn. Các gói tải xuống nằm ở Releases.
