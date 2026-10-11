# BHT v0.6.55 — mã nguồn cho AutoCAD

BHT quản lý hiện trạng tuyến, điểm khảo sát, biển báo, cọc và đèn trong AutoCAD. Kho này chứa mã nguồn C# và AutoLISP để đọc, kiểm tra và tiếp tục phát triển.

**AI/người phát triển mới: bắt đầu tại [docs/AI_HANDOFF.md](docs/AI_HANDOFF.md), sau đó đọc [AGENTS.md](AGENTS.md).**

## Bản hiện tại

- Phiên bản mã nguồn: **0.6.53**, assembly **0.6.55.0**.
- Sửa lỗi nạp Lisp “bad argument type: stringp T” khi FAS/LSP nằm trong Support Path; giữ cơ chế tự thử nạp và kiểm tra API của 0.6.53.
- Các cập nhật gần đây: đồng bộ tỷ lệ biển, biểu diễn trụ mất mặt biển, nhãn cọc xoay theo ký hiệu, mốc lý trình lấy từ hồ sơ cọc, đèn tín hiệu và đèn chiếu sáng riêng.
- Không tự cập nhật hình học ký hiệu khi khởi động CAD.

Xem [CHANGELOG](CHANGELOG.md), [ghi chú 0.6.53](docs/RELEASE_NOTES_0.6.55.md) và [QA 0.6.53](docs/QA_0.6.53.md). Tài liệu phiên bản cũ là lịch sử; khi có khác biệt, ưu tiên mã nguồn hiện tại và ghi chú mới nhất.

## Cấu trúc

| Thư mục | Vai trò |
|---|---|
| src/lisp/modules | 12 module AutoLISP: điểm, hồ sơ, tuyến, ký hiệu, API |
| src/lisp/BHT-0.6.55.lsp | Loader mã nguồn |
| src/dotnet/BHT.Core | Mô hình, quy tắc nghiệp vụ; không phụ thuộc AutoCAD |
| src/dotnet/BHT.Bridge | Đọc/ghi DWG, thư viện block, điều phối lệnh và gọi Lisp |
| src/dotnet/BHT.Palette | Giao diện WinForms/Palette của AutoCAD |
| tests | Kiểm tra Core, tích hợp AutoCAD, bộ cài |
| scripts, packaging | Build, phiên bản, FAS, bảo vệ DLL, đóng gói/cài đặt |
| docs | Hướng dẫn, hợp đồng dữ liệu, lịch sử phát hành và QA |

## Build

Windows, .NET Framework 4.8; plugin cần các DLL tham chiếu từ AutoCAD cài hợp lệ. Tích hợp hiện được kiểm tra với AutoCAD 2024 x64.

Chỉ build/kiểm tra Core, không cần AutoCAD:

    ./scripts/check-version.ps1
    ./scripts/build.ps1 -CoreOnly -UseCsc -Test -OutDir 'build/core'

Build plugin trên máy có AutoCAD:

    ./scripts/build.ps1 -AcadDir 'D:\AutoCAD 2024' -UseCsc -Test -OutDir 'build/v0.6.53/bin'

Không có DLL AutoCAD thì script có thể bỏ qua plugin; đọc log để phân biệt build Core và build đầy đủ. Không NETLOAD DLL mới đè lên phiên CAD đã nạp DLL cũ; đóng CAD và cài lại hoặc dùng Core Console cô lập để thử.

## Tài nguyên và bộ cài

Kho mã nguồn không chứa DLL Autodesk, thư viện DWG/phông sao chép từ phần mềm bên ngoài, dữ liệu khảo sát, ảnh thực tế, file build hoặc bộ cài. Vì vậy clone repo đủ để đọc mã và chạy CoreTests, nhưng cần bổ sung tài nguyên cục bộ để tái tạo toàn bộ thư viện biển/đèn và bộ cài.

Xem [thư viện cục bộ](docs/ADSCIVIL_LIBRARY.md), [đóng gói bảo vệ](docs/PROTECTED_BUILD.md), [cài đặt](packaging/README_INSTALL.md), [hợp đồng dữ liệu](docs/DATA_CONTRACT.md) và [hướng dẫn sử dụng](docs/HUONG_DAN.md).

Bộ phát hành 0.6.53 đã giao trên máy phát triển gồm FAS/DLL; BHT-0.6.55.zip runtime bảo vệ không phải ZIP mã nguồn. Mã nguồn mới nhất nằm trong kho Git này. Tài nguyên bên thứ ba tiếp tục tuân theo giấy phép của chủ sở hữu.

## Trạng thái 0.6.55

Bản thử nghiệm Mốc 1: GPL-3.0-only (LICENSE, COPYING_SCOPE.md), gói công khai kèm mã nguồn nhưng không kèm tài nguyên vendor chưa rõ quyền. Đọc ROADMAP.md, docs/ACCEPTANCE_0.6.md và docs/KNOWN_ISSUES.md. Chỉ kiểm thử AutoCAD 2024 trong đợt này; chưa nghiệm thu máy sạch/người dùng độc lập.

Build công khai: thêm -PublicDistribution vào scripts/build.ps1. Package: -PublicDistribution -IncludeSource, không dùng -ProtectedRuntime. Các mục thư viện phụ thuộc nguồn ngoài có thể thiếu; xem packaging/README_PUBLIC.md.
