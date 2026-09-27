# BHT 0.4.0 — Báo cáo kiểm thử

Ngày chạy: 2026-09-27 (giờ Việt Nam). Máy: Windows của người dùng, AutoCAD 2024 (ACADVER 24.3) — **AutoCAD Core Console**
(`D:\AutoCAD 2024\accoreconsole.exe`, LISPSYS = 1). Không có kết quả nào được chạy trong AutoCAD đầy đủ (có giao diện).

## 1. Sản phẩm và SHA-256

| File | Kích thước (byte) | SHA-256 |
|---|---|---|
| BHT-0.4.0.lsp | 267 148 | `402CE32A72C1E375B0CB7F0B478A79139C4F0EA2F12BBB5D95BE314985FE7A0F` |
| bin/BHT.Palette.dll (FileVersion 0.4.0.1) | 57 856 | `A4B172E3859E0EDD9CF12B40334C72AC0D5DC77B3E8BF00BB3580BC6F4A4868D` |
| bin/BHT.Bridge.dll (FileVersion 0.4.0.1) | 44 544 | `A14E7B59FF1F630C7F2B249F5D75368E7D3978FCBD26CAD9DBDDBAABB66664E6` |
| bin/BHT.Core.dll (FileVersion 0.4.0.1) | 26 112 | `58EB467954C48639B70BEB48C26DF6A2EE68E7B9EBA365461325F3114D06366E` |

Đây đúng là các file đã dùng trong kiểm thử bên dưới (bản Lisp được kiểm dưới tên `BHT-0.4.0-rc.lsp` trong thư mục có dấu,
cùng SHA-256). Không có DLL nào của Autodesk trong gói.
csc.exe của .NET Framework không có chế độ build tất định: build lại từ mã nguồn cho DLL chạy giống hệt nhưng SHA-256 khác.

## 2. Build (.NET)

* Môi trường: **không có** .NET SDK (chỉ có dotnet host 10.0.7), MSBuild, Visual Studio, .NET Framework 4.8 Developer Pack.
* Trình biên dịch: `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe` (C# 5, `/platform:x64`), tham chiếu
  .NET Framework 4.x trong thư mục đó; AutoCAD: `D:\AutoCAD 2024\acdbmgd.dll`, `accoremgd.dll`, `acmgd.dll` (không chép).
* `scripts\build.ps1 -Test` (log `tests/evidence/build_log_V040.txt`): csc BHT.Core → exit 0; BHT.CoreTests → exit 0;
  BHT.Bridge (acdbmgd + accoremgd) → exit 0; BHT.Palette (+ acmgd, WinForms) → exit 0; không có cảnh báo / lỗi.
* Build lại trong thư mục dự án có dấu (`…\Lisp đang build\BHT\BHT-CAD`, 15:19): cả 4 bước csc exit 0, CoreTests 56 PASS /
  0 FAIL (`tests/evidence/build_log_BHT-CAD.txt`). SHA-256 khác bản đã kiểm (csc không tất định) — gói giao **các DLL đã kiểm**
  ở mục 1.
* Các file `.csproj` (SDK-style) và workflow GitHub Actions: **chưa chạy** (không có SDK trên máy) — không khẳng định chạy được.

## 3. Kiểm thử đơn vị BHT.Core (BHT.CoreTests.exe)

**56 PASS, 0 FAIL.** Mã hóa / giải mã bản ghi giống `bht:rec-encode/decode` (chia 200 ký tự, `k+=` ghép vào cặp cuối),
get/set/set-all, `bht:fnum`, ID hồ sơ (không dùng lại số đã xóa), tạo hồ sơ đúng thứ tự trường của `bht:obj-create`, từ chối
điểm đã thuộc hồ sơ khác (mặc định), dùng chung khi xác nhận, sửa / thêm / gỡ điểm, gắn / bỏ ảnh hai chiều, ứng viên đường
dẫn JPG giống Lisp, GPS 0,0, tìm không dấu, điểm / ảnh gần theo khoảng cách, phiên bản, XData BHT_PT, đọc trả lời Lisp
(không trả lời = lỗi), gợi ý nhóm có căn cứ.

## 4. Kiểm thử tích hợp Core Console (lần chạy cuối, tất cả trên cùng bản Lisp + DLL ở mục 1)

| Phiên | Nội dung | PASS | FAIL | BLOCKED |
|---|---|---|---|---|
| S0 | nạp từ đường dẫn có dấu, thông báo APPLOAD, BHTTEST (46/46), DCL tĩnh, 12 API, BHTPALETTE chưa có plugin | 13 | 0 | 1 (mở DCL) |
| A | hồi quy 0.3.3: 526 điểm, nhãn (chồng lấn 941 → 26 / 1574), nhãn dời tay, phạm vi, khu dày, hồ sơ không trùng, ký hiệu theo ID, 205 ảnh, raster + đường dẫn, Layout → Model, thứ tự (IRT + ảnh khác), thực thể ngoài BHT | 39 | 0 | 0 |
| B | mở lại A (SAVEAS 2018) | 8 | 0 | 0 |
| L | bản vẽ 0.3.2 mở bằng 0.4.0 | 11 | 0 | 0 |
| R | hồi quy 0.3.2 (nhập, ảnh, ghép đề xuất, tuyến, lý trình, gói thầu, xuất) | 29 | 0 | 0 |
| L2 | mở lại bản vẽ 0.3.2 đã nâng cấp | 2 | 0 | 0 |
| N | bản vẽ 0.3.3 + NETLOAD BHT.Bridge: C# đọc = Lisp (4 361 dòng), C# tạo / sửa / thêm điểm / gắn / bỏ ảnh → Lisp đọc giống hệt, thứ tự trường = Lisp, không tạo trùng, ghi an toàn, bộ điều phối từ chối khi có lệnh, Invoke khi Lisp bận = LỖI, cache vô hiệu khi DB đổi, 9 API qua Application.Invoke, DRAWORDER qua API = LỖI rõ ràng + đường lệnh BHTTHUTUVE, thực thể ngoài BHT không đổi (49 636), POINT không dời | 32 | 0 | 0 |
| N2 | mở lại N_out (SAVEAS 2018): dump C# = Lisp = cuối phiên N, hồ sơ C# tạo còn nguyên | 5 | 0 | 0 |
| NL | bản vẽ 0.3.2 + BHT.Bridge: C# đọc = Lisp (4 713 dòng), 205 ảnh, tạo hồ sơ nối tiếp ID, không trùng | 6 | 0 | 0 |
| P | NETLOAD BHT.Palette.dll trong Core Console; lệnh BHTPALETTE | 2 (+1 INFO) | 0 | 0 |
| T | ảnh nền IRT lưới 156 tile (144 + 12 trên layer khóa), mẫu cấu hình, tile layer 0 trong thư mục `…\IRT\…`, ảnh khác không bị đụng | 12 (+1 INFO) | 0 | 0 |
| **Tổng** | | **159** | **0** | **1** |

INFO P01: console ghi `BHT.Palette 0.4.0.1 đã nạp` — NETLOAD BHT.Palette.dll (tham chiếu acmgd) **nạp được** trong Core Console;
lệnh `BHTPALETTE` báo "cần AutoCAD đầy đủ" và tiến trình chạy tiếp (P02).
INFO T07: 12 tile trên layer khóa cũng được DRAWORDER đưa xuống dưới (BHT không mở khóa layer).
Hiệu năng T: phân loại 156 tile 16 ms; BHTTHUTUVE 78 ms.

### Lỗi ở các lần chạy trước (đã sửa, ghi lại trung thực) — `tests/evidence/lan_truoc/`
* T lần 1: T13 FAIL — kỳ vọng của bài kiểm sai (so "hạng" SORTENTS tuyệt đối của ảnh khác; AutoCAD đánh số lại khi
  DRAWORDER). Sửa bài kiểm: ảnh khác phải nằm trên mọi tile IRT và dữ liệu không đổi.
* N lần 1: 4 FAIL.
  - N04: kỳ vọng sai (bản vẽ 0.3.3 có 586 điểm = 526 thật + 60 giả lập khu dày) → so với số điểm của Lisp.
  - N22: API trả khóa chữ HOA (`CREATED=1`) → sửa `bht:api-alist` trả chữ thường như `loi=`/`canh_bao=`.
  - N26: **phát hiện thật**: AutoCAD từ chối lệnh DRAWORDER khi Lisp được gọi qua `Application.Invoke`
    ("AutoCAD command rejected"). Sửa: API trả LỖI rõ ràng chỉ dẫn `BHTTHUTUVE`, khôi phục biến hệ thống; palette dùng
    đường lệnh `BHTTHUTUVE`; thêm N26b kiểm đường lệnh.
  - N31: 1 thực thể không phải BHT bị đổi ở lần 1 (chưa có ghi chi tiết); **không tái hiện** ở 2 lần chạy sau (đã thêm
    ghi chi tiết thực thể đổi) — nguyên nhân chưa xác định; nghi liên quan lệnh DRAWORDER bị từ chối giữa chừng.
* P lần 1: gõ `BHTPALETTE` trong Core Console làm tiến trình **dừng đột ngột** (console dừng sau dòng lệnh, không QUIT).
  Sửa: phát hiện Core Console, chỉ báo, không tạo PaletteSet.
* Một lần chạy N/N2/NL không hợp lệ (lỗi ngoặc trong `t_common.lsp` của bộ kiểm) — không tính.

## 5. SKIP / BLOCKED (không chạy được trong Core Console)

* **BLOCKED** — mở bảng DCL `BHT` (S0 T05), chọn đối tượng bằng chuột, trình xem ảnh Lisp.
* **BLOCKED** — toàn bộ giao diện palette: gắn trái / kéo rộng / nhớ vị trí, đồng bộ lựa chọn CAD ↔ palette, xem JPG trong
  palette, chuyển / đóng bản vẽ, từ chối khi có lệnh (đã kiểm ở mức BHT.Bridge: N15), lỗi khóa tài liệu, tiêu điểm / vòng lặp
  sự kiện, ExecuteInCommandContextAsync từ ngữ cảnh ứng dụng, SendStringToExecute + CommandWatcher từ palette.
  → `CHECKLIST_NGHIEM_THU.md` mục P1–P21. Không khởi chạy acad.exe đầy đủ (không chạy được không giám sát một cách an toàn).
* **SKIP** — giải nén KMZ 349 MB (mã không đổi từ 0.3.2).

## 6. Kiểm tĩnh Lisp
Ngoặc cân bằng; 378 defun, không trùng, không lồng; không gọi hàm chưa định nghĩa (trừ `eval`/`set` dựng sẵn)
(`tests/evidence/static_check_040.txt`). Bản 0.3.2 / 0.3.3 không bị sửa: BHT-0.3.2.lsp SHA-256 `8EA8C246EFF7200D6E49B1CD285DC365A3AD30332DDC331ADD4460EB6DE23728`, BHT-0.3.3.lsp `0F9D41A99E6B36005D6BFD3998AC5D95FA91B180F587C6A862E9F2EC7D8CEA2F` (kiểm lại khi đóng gói).
