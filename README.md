# BHT v0.6.9 — Quản lý hiện trạng tuyến

BHT là ứng dụng AutoLISP + .NET cho AutoCAD trên Windows, quản lý điểm RTK, hồ sơ đối tượng, ảnh hiện trường, tuyến/lý trình và báo cáo.

## Cài đặt

Giải nén đầy đủ `BHT-0.6.9.zip`, đóng toàn bộ AutoCAD và chạy `INSTALL_BHT.cmd`. Mở CAD, gõ `BHT` hoặc `BTH` để mở bảng. Kiểm tra tiêu đề hiển thị 0.6.9.

Phông mặc định là `VNRomancUpdate.shx`, dùng Unicode NFC. Hồ sơ, CSV và báo cáo giữ Unicode. Phông cũ `vnromanc.shx` chỉ dùng TCVN3 tại lớp hiển thị khi chọn kiểu cũ.

## Các thay đổi chính của v0.6.9

- Đã sửa mũi tên chọn/đảo chiều tuyến để giữ hình trong lúc xác nhận và REGEN.
- Đã đọc nhãn Km nằm trong tuyến TDT và block lồng nhau, lấy đúng vị trí vạch cọc trên tim.
- Đã sửa lỗi cập nhật lại tim có cung, giữ nguyên handle Polyline tham chiếu.
- Đã kiểm tra bản sao tuyến TDT thực tế: đọc đủ 371 cọc; giữ hai cảnh báo để người dùng xét duyệt.
- Các lệnh tinh giản từ v0.6.8 được giữ; xem [lệnh thay thế](docs/COMMANDS_0.6.8.md) để cập nhật script CAD.

Xem [hướng dẫn sử dụng](docs/HUONG_DAN.md), [cài đặt](packaging/README_INSTALL.md), [ghi chú phát hành](docs/RELEASE_NOTES_0.6.9.md) và [hợp đồng dữ liệu](docs/DATA_CONTRACT.md).

## Mã nguồn và build

- `src/lisp/BHT-0.6.9.lsp`: loader duy nhất, với 12 module trong `src/lisp/modules`.
- `src/dotnet`: BHT.Core, BHT.Bridge và BHT.Palette; phiên bản assembly `0.6.9.0`.
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
