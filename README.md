# BHT v0.6.3 — Quản lý hiện trạng tuyến

BHT là ứng dụng AutoLISP + .NET cho AutoCAD trên Windows, quản lý điểm RTK, hồ sơ đối tượng, ảnh hiện trường, tuyến/lý trình và báo cáo.

## Cài đặt

Tải `BHT-0.6.3.zip` trong [Releases](https://github.com/7xj1998-cell/BHT-CAD/releases/tag/v0.6.3), giải nén đầy đủ, đóng AutoCAD và chạy `INSTALL_BHT.cmd`. Mở CAD, gõ `BTH` hoặc `BHT` để hiện Palette. Gói này dùng Lisp và 12 module; bộ cài MSI/VLX thuộc v0.6.4 và không nằm trong bản v0.6.3.

Phông mặc định là `VNRomancUpdate.shx`, dùng Unicode NFC và giữ phân biệt `Ê`/`ê`. Hồ sơ, CSV và báo cáo giữ Unicode. Phông cũ `vnromanc.shx` chỉ dùng TCVN3 tại lớp hiển thị khi chọn kiểu cũ.

## Các thay đổi chính của v0.6.3

- Palette chỉ hiện khi gọi lệnh; đóng bảng hoặc chuyển bản vẽ ngắt theo dõi dữ liệu/timer.
- Ô “Tô màu biển” nằm cùng hàng chèn tự do, áp dụng cho mọi biển BHT trong bản vẽ.
- Nhãn căn giữa bên dưới mặt biển, tự tính kích thước và quay cùng biển khi dùng điểm trung gian.
- Hướng dẫn hồ sơ mới chuyển vào tooltip; tùy chọn dùng chung điểm RTK được ghi rõ.
- Thư viện biển có thumbnail, tìm kiếm, biến thể tốc độ và nhiều mặt; hỗ trợ block riêng và biển nội bộ khi máy không có TDT.

Xem [hướng dẫn sử dụng](docs/HUONG_DAN.md), [cài đặt](packaging/README_INSTALL.md), [ghi chú v0.6.3](docs/RELEASE_NOTES_0.6.3.md) và [hợp đồng dữ liệu](docs/DATA_CONTRACT.md).

## Mã nguồn và build

- `src/lisp/BHT-0.6.3.lsp`: loader duy nhất, với 12 module trong `src/lisp/modules`.
- `src/dotnet`: BHT.Core, BHT.Bridge và BHT.Palette; phiên bản assembly `0.6.3.0`.
- `scripts`: build, kiểm phiên bản, đóng gói và kiểm thư viện TDT.
- `tests`: Core, tích hợp CAD và bộ cài; `.github/workflows` chạy Core trên Windows.
- `packaging`: Application Bundle và trình cài PowerShell.

Cần .NET Framework 4.8 và DLL tham chiếu từ thư mục AutoCAD của máy phát triển. Mục tiêu hỗ trợ AutoCAD 2021–2024 x64; kiểm thử hiện tại dùng AutoCAD 2024.

```powershell
./scripts/check-version.ps1
./scripts/build.ps1 -AcadDir 'D:\AutoCAD 2024' -UseCsc -Test
./scripts/package.ps1 -AcadDir 'D:\AutoCAD 2024'
```

Không đưa DLL Autodesk, kết quả build, bản vẽ, ảnh/dữ liệu khảo sát, phông sao chép cục bộ hoặc ZIP vào cây mã nguồn. Các gói tải xuống nằm ở Releases. Lịch sử Git và các bản phát hành trước được giữ để tra cứu; cây nguồn hiện tại chỉ có một loader BHT.

## Kiểm thử bản nhập lên GitHub

127 kiểm tra Core và bảy kiểm tra bộ cài đạt; REVIEW/S0/V5 đạt. Lisp và 12 module được đối chiếu SHA256 với gói v0.6.3 đã phát hành. Ba DLL biên dịch lại giữ nguyên định danh assembly, chữ ký và IL của 833 phương thức so với gói đó. TX chưa chạy vì thiếu fixture proxy; chưa nghiệm thu thao tác chuột trên Palette v0.6.3.

Đợt này đưa bản v0.6.3 đã có lên GitHub và dọn cây nguồn, không đưa thay đổi runtime v0.6.4 vào bản cũ. Đợt sửa chức năng tiếp theo phải tăng phiên bản theo `AGENTS.md`.