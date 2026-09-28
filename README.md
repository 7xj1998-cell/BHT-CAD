# BHT 0.4.5 — Quản lý hiện trạng tuyến

BHT là bộ AutoLISP + .NET Palette cho AutoCAD 2021–2024 trên Windows. Ứng dụng quản lý điểm RTK, hồ sơ đối tượng, ảnh TimeMark, tuyến/lý trình và báo cáo ngay trong bản vẽ.

## Trải nghiệm chính

- Gõ `BTH` hoặc `BHT` để mở một bảng Palette duy nhất, gắn bên trái AutoCAD.
- Chọn điểm trực tiếp trên bản vẽ trong khi Palette vẫn mở để tạo hoặc bổ sung hồ sơ.
- Chọn một dòng điểm trong Palette để đánh dấu điểm tương ứng trên CAD; nhấp đúp để phóng tới.
- Nhập CSV/KMZ và tiếp tục quy trình ngay từ thẻ **Tổng quan**.
- Điểm RTK mặc định hiển thị bằng dấu X kích thước 1 đơn vị; thuật toán nhãn tránh cả điểm và nhãn lân cận.
- Nhập lý trình trực tiếp trong thẻ **Hồ sơ**; biển báo tự chọn block theo mã QCVN, vẫn có thể nạp DWG riêng cho từng nhóm.
- Lấy tim TDTSolution 9.1 bản thường bằng `BHTTUYENTDT`; BHT tạo Polyline tham chiếu riêng và không sửa đối tượng TDT.
- Xuất báo cáo biển báo `.xlsx` Unicode với sheet tổng hợp và danh sách chi tiết ngay trên thẻ **Tuyến & báo cáo**.
- `BHTDCL` chỉ là giao diện dự phòng. Tệp DCL tạm được ghi UTF-8 BOM để tiếng Việt hiển thị đúng.

## Cài đặt

Cách khuyến nghị: giải nén bản phát hành, đóng AutoCAD, chạy `INSTALL_BHT.cmd`, sau đó mở AutoCAD và gõ `BTH` hoặc `BHT`. Application Bundle tự nạp Lisp và DLL; người dùng không cần `NETLOAD`.

Cách di động: đặt `BHT-0.4.5.lsp`, `BHT.Core.dll`, `BHT.Bridge.dll` và `BHT.Palette.dll` trong cùng thư mục, rồi `APPLOAD` duy nhất file Lisp. Lisp tự nạp Palette.

Xem [hướng dẫn cài đặt](packaging/README_INSTALL.md), [hướng dẫn sử dụng](docs/HUONG_DAN.md), [rà soát block/TDT](docs/BLOCK_AUDIT_0.4.5.md), [giới hạn đã biết](docs/KNOWN_ISSUES_0.4.5.md), [báo cáo kiểm thử](docs/TEST_REPORT_0.4.5.md) và [checklist nghiệm thu](docs/CHECKLIST_NGHIEM_THU_0.4.5.md).

## Cấu trúc

- `src/lisp/BHT-0.4.5.lsp`: lõi dữ liệu, nhập/xuất, thuật toán CAD và toàn bộ thư viện block tích hợp.
- `src/dotnet/BHT.Core`: hợp đồng dữ liệu và logic thuần .NET.
- `src/dotnet/BHT.Bridge`: truy cập DWG và cầu nối Lisp/.NET.
- `src/dotnet/BHT.Palette`: giao diện PaletteSet WinForms và các lệnh `BTH`/`BHT`.
- `packaging/BHT.bundle`: khai báo Autodesk Application Bundle.
- `tests/CoreTests`: kiểm thử logic thuần .NET.
- `tests/IntegrationTests`: hồi quy Lisp và cầu nối bằng AutoCAD Core Console.
- `scripts/audit_tdt_library.ps1`: kiểm tra và lập chỉ mục thư viện biển báo từ bản TDT đã cài, không đưa tài sản TDT vào BHT.

## Build và đóng gói

Yêu cầu Windows, .NET Framework 4.8 và thư mục cài AutoCAD có `acdbmgd.dll`, `accoremgd.dll`, `acmgd.dll`.

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -AcadDir 'D:\AutoCAD 2024' -UseCsc -Test
powershell -ExecutionPolicy Bypass -File scripts\package.ps1 -AcadDir 'D:\AutoCAD 2024'
```

`package.ps1` tạo thư mục và ZIP `build/release/BHT-0.4.5`. Các DLL Autodesk không được đưa vào mã nguồn hoặc gói phát hành.

## Nguyên tắc dữ liệu

X = Easting, Y = Northing, Z = cao độ. BHT không làm tròn, đổi chỗ hoặc di chuyển POINT RTK. Điểm RTK là dữ liệu gốc; hồ sơ là đơn vị quản lý; block, nhãn và raster là lớp trình bày. GPS ảnh chỉ là vị trí chụp và không thay tọa độ RTK. Định dạng DWG giữ tương thích với BHT 0.3.2–0.4.3.

Phiên bản nguồn, Lisp và assemblies cùng là `0.4.5`.
