# BHT v0.6.5 — Quản lý hiện trạng tuyến

BHT là ứng dụng AutoLISP + .NET cho AutoCAD trên Windows, quản lý điểm RTK, hồ sơ đối tượng, ảnh hiện trường, tuyến/lý trình và báo cáo.

## Cài đặt

Giải nén đầy đủ `BHT-0.6.5.zip`, đóng AutoCAD và chạy `INSTALL_BHT.cmd`. Mở CAD, gõ `BTH` hoặc `BHT` để hiện Palette. Đây là đợt chỉnh sửa tiếp từ v0.6.3, dùng Lisp chia module và .NET; không dùng mã v0.6.4 làm nền.

Phông mặc định là `VNRomancUpdate.shx`, dùng Unicode NFC và giữ phân biệt `Ê`/`ê`. Hồ sơ, CSV và báo cáo giữ Unicode. Phông cũ `vnromanc.shx` chỉ dùng TCVN3 tại lớp hiển thị khi chọn kiểu cũ.

## Các thay đổi chính của v0.6.5

- Cọc tiêu đặt gốc tại chân đuôi, nhãn trên đầu và quay cùng ký hiệu.
- “Đặt tự do” mở hộp tùy chọn riêng; đường dẫn thẳng, gấp khúc, chọn điểm trung gian; hướng theo tuyến, chọn CAD hoặc nhập góc. Áp dụng mọi nhóm đối tượng.
- Hồ sơ chia ba phần: thông tin, ký hiệu, vị trí/ảnh. Bỏ các lệnh nâng cấp dữ liệu đời cũ.
- Một trụ nhiều mặt vẽ đủ các tấm, biển chính trên và biển phụ dưới. Chèn/cập nhật lưu thông số vừa sửa trước khi vẽ.
- S.501, S.502, S.509a, P.117–P.120 nhận giá trị mét; ví dụ `S.509a@4.5`, `S.502@150`. Sửa tại thư viện biển.
- Thư viện có ảnh cho 376 mã hợp lệ trong danh mục TDT đã kiểm tra; ảnh bổ sung đóng gói kèm ứng dụng. Không tính khung chữ mã là ảnh.

Xem [hướng dẫn sử dụng](docs/HUONG_DAN.md), [cài đặt](packaging/README_INSTALL.md), [ghi chú v0.6.5](docs/RELEASE_NOTES_0.6.5.md) và [hợp đồng dữ liệu](docs/DATA_CONTRACT.md).

## Mã nguồn và build

- `src/lisp/BHT-0.6.6.lsp`: loader duy nhất, với 12 module trong `src/lisp/modules`.
- `src/dotnet`: BHT.Core, BHT.Bridge và BHT.Palette; phiên bản assembly `0.6.6.0`.
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