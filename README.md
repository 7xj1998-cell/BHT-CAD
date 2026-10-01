# BHT 0.5.5 — Quản lý hiện trạng tuyến

BHT là bộ AutoLISP + .NET Palette cho AutoCAD 2021–2024 trên Windows. Ứng dụng quản lý điểm RTK, hồ sơ đối tượng, ảnh TimeMark, tuyến/lý trình và báo cáo ngay trong bản vẽ.

## Phông chữ và phiên bản

Chữ CAD mặc định dùng `VNRomancUpdate.shx` với bảng mã **Unicode**. Phông được kiểm tra trên máy là SHX Unicode, có glyph riêng cho `Ê`, `ê`, `Ế`, `Ệ`; không chuyển TCVN3 cho phông này. Khi gõ trực tiếp vào TEXT có kiểu `BHT_TCVN`/`BHT_BIENBAO`, chọn Unicode trong bộ gõ. Tên kiểu `BHT_TCVN` được giữ để tương thích bản vẽ cũ. Kiểu tùy chỉnh dùng `vnromanc.shx` vẫn dùng TCVN3; Palette, CSV/Excel và hồ sơ luôn giữ Unicode.

Mỗi đợt sửa phải tăng số phiên bản. Dùng `scripts/set-version.ps1 -Version <phiên-bản-mới>` cho bản sửa kế tiếp; build và package đều kiểm tra metadata. Không phát hành lại mã đã đổi dưới số phiên bản cũ.

Thư viện biển báo: xem trước ảnh lớn, chọn tốc độ P.127, thêm/bỏ/sắp thứ tự nhiều mặt trên cùng trụ; mặt đầu là mã biển chính. Xem [thay đổi v0.5.5](docs/RELEASE_NOTES_0.5.5.md), [xử lý review](docs/REVIEW_RESOLUTION_0.5.5.md) và [hướng dẫn chèn tự do](docs/RELEASE_NOTES_0.5.3.md).

## Trải nghiệm chính

- Gõ `BTH` hoặc `BHT` để mở một bảng Palette tối duy nhất; thanh chọn thẻ nằm dọc ở mép phải.
- Chọn điểm trực tiếp trên bản vẽ trong khi Palette vẫn mở để tạo hoặc bổ sung hồ sơ.
- Chọn một dòng điểm trong Palette để đánh dấu điểm tương ứng trên CAD; nhấp đúp để phóng tới.
- Nhập CSV/KMZ và tiếp tục quy trình ngay từ thẻ **Tổng quan**.
- Điểm RTK mặc định hiển thị bằng dấu X kích thước 1 đơn vị; thuật toán nhãn tránh cả điểm và nhãn lân cận.
- Nhập lý trình trực tiếp trong thẻ **Hồ sơ**; biển báo tự chọn block theo mã QCVN, vẫn có thể nạp DWG riêng cho từng nhóm.
- Lấy tim TDTSolution 9.1 bản thường bằng `BHTTUYENTDT`; BHT tạo Polyline tham chiếu riêng và không sửa đối tượng TDT.
- Xuất báo cáo biển báo `.xlsx` Unicode với sheet tổng hợp và danh sách chi tiết ngay trên thẻ **Tuyến & báo cáo**.
- Giao diện chính dùng Palette .NET; khi chưa nạp được, dùng `BHTLOAD` để kiểm tra DLL và thử lại.

## Cài đặt

Cách khuyến nghị: giải nén bản phát hành, đóng AutoCAD, chạy `INSTALL_BHT.cmd`, sau đó mở AutoCAD và gõ `BTH` hoặc `BHT`. Application Bundle tự nạp Lisp và DLL; người dùng không cần `NETLOAD`.

Cách di động: đặt `BHT-0.5.5.lsp`, `BHT.Core.dll`, `BHT.Bridge.dll` và `BHT.Palette.dll` trong cùng thư mục, rồi `APPLOAD` duy nhất file Lisp. Lisp tự nạp Palette.

Xem [hướng dẫn cài đặt](packaging/README_INSTALL.md), [hướng dẫn sử dụng](docs/HUONG_DAN.md), [nghiên cứu TDT/DPSurvey](docs/NGHIEN_CUU_DIEM_VA_PALETTE_TDT_DPSURVEY.md), [rà soát block/TDT](docs/BLOCK_AUDIT_0.4.5.md), [giới hạn đã biết](docs/KNOWN_ISSUES_0.4.6.md), [báo cáo kiểm thử](docs/TEST_REPORT_0.4.6-fix3.md) và [checklist nghiệm thu](docs/CHECKLIST_NGHIEM_THU_0.4.6-fix3.md).

## Cấu trúc

- `src/lisp/BHT-0.5.5.lsp`: lõi dữ liệu, nhập/xuất, thuật toán CAD và toàn bộ thư viện block tích hợp.
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

`package.ps1` tạo thư mục và ZIP `build/release/BHT-0.5.5`. Các DLL Autodesk không được đưa vào mã nguồn hoặc gói phát hành.

## Nguyên tắc dữ liệu

X = Easting, Y = Northing, Z = cao độ. BHT không làm tròn, đổi chỗ hoặc di chuyển POINT RTK. Điểm RTK là dữ liệu gốc; hồ sơ là đơn vị quản lý; block, nhãn và raster là lớp trình bày. GPS ảnh chỉ là vị trí chụp và không thay tọa độ RTK. Định dạng DWG giữ tương thích với BHT 0.3.2–0.4.3.

Phiên bản nguồn và Lisp là `0.4.6-fix3`; assemblies mang số `0.4.6.3` (AssemblyInformationalVersion `0.4.6-fix3`).

Chèn biển tự do: lưu hồ sơ Biển báo có điểm RTK, bấm **Chèn biển tự do** (hoặc `BHTBIENTUDO`), chọn hướng → điểm trung gian (`Xoa` để bỏ điểm cuối; `Dat`/Enter để kết thúc) → vị trí đặt biển. BHT lưu đường dẫn gấp khúc và hướng; cập nhật ký hiệu vẫn giữ bố trí này. `BHTKYHIEU` > `R` trả về tự động theo tuyến. Xem `docs/RELEASE_NOTES_0.5.3.md`.
