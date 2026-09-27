# BHT — Quản lý hiện trạng tuyến (AutoCAD 2024)

Công cụ AutoLISP + plugin .NET cho AutoCAD để quản lý dữ liệu hiện trạng tuyến đường: điểm đo RTK, hồ sơ đối tượng
(cọc tiêu, biển báo, …), ảnh TimeMark liên kết, ký hiệu / nhãn trình bày.

* `src/lisp/BHT-0.4.0.lsp` — lõi Lisp (APPLOAD). Gõ `BHT` mở bảng điều khiển DCL; `BHTHELP` xem danh sách lệnh.
* `src/dotnet/BHT.Core` — thư viện thuần .NET (net48): định dạng dữ liệu, logic kiểm thử được (CI).
* `src/dotnet/BHT.Bridge` — truy cập dữ liệu DWG (acdbmgd + accoremgd).
* `src/dotnet/BHT.Palette` — palette `BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN`, lệnh `BHTPALETTE` (NETLOAD).
* `tests/CoreTests` — kiểm thử đơn vị BHT.Core (chương trình console, mã thoát = số FAIL).
* `tests/IntegrationTests` — kịch bản AutoCAD Core Console (accoreconsole) cho Lisp + BHT.Bridge.
* `docs/` — hợp đồng dữ liệu, kiến trúc, hướng dẫn.

## Quy tắc dữ liệu
X = Easting, Y = Northing, Z = cao độ. Không làm tròn / sửa dữ liệu khảo sát; không bao giờ dời POINT RTK.
Điểm RTK = dữ liệu gốc; hồ sơ đối tượng = đơn vị quản lý; ảnh = media liên kết; block / nhãn = trình bày.
GPS ảnh không thay tọa độ RTK; ghép ảnh chỉ là gợi ý, người dùng xác nhận.

## Build
Yêu cầu: Windows, .NET Framework 4.8. Tham chiếu AutoCAD (acdbmgd.dll, accoremgd.dll, acmgd.dll) lấy từ thư mục cài
AutoCAD — **không** đưa vào repo.

```powershell
# Tự tìm: -AcadDir > biến môi trường ACAD_INSTALL_DIR > D:\AutoCAD 2024
powershell -ExecutionPolicy Bypass -File scripts\build.ps1 -Test
```
Có .NET SDK → `dotnet build`; không có → csc.exe của .NET Framework (C# 5). Không tìm thấy tham chiếu AutoCAD → chỉ
build BHT.Core + CoreTests và báo rõ đã bỏ qua plugin. CI (`.github/workflows/build-core.yml`) chỉ build/kiểm thử BHT.Core.

## Phiên bản
`VERSION` = 0.4.0; AssemblyVersion 0.4.0.0, FileVersion 0.4.0.1. Xem `CHANGELOG.md`.
