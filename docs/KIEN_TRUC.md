# BHT 0.4.1 — KIẾN TRÚC

```
BHT-0.4.1.lsp  (lõi Lisp: nhập dữ liệu, thuật toán nhãn / ký hiệu / ký hiệu ảnh / kiểm tra / thứ tự hiển thị)
      ▲  bht:api-*  (vl-acad-defun, Application.Invoke)            ▲ lệnh Lisp (SendStringToExecute, fire-and-forget)
      │                                                              │
BHT.Palette.dll  (một PaletteSet WinForms; lệnh chính BTH / BHT; tham chiếu acmgd)
      │
BHT.Bridge.dll   (truy cập DWG: dictionary BHT_V02 / XRecord / XData; AcadDispatcher; lệnh kiểm thử BHTNET*;
      │           chỉ tham chiếu acdbmgd + accoremgd → NETLOAD được trong Core Console)
BHT.Core.dll     (thuần .NET: mô hình dữ liệu, mã hóa bản ghi giống Lisp, logic hồ sơ / ảnh / tìm kiếm; kiểm thử CI)
```

* **DWG là nguồn dữ liệu duy nhất.** C# đọc/ghi đúng định dạng Lisp (docs/DATA_CONTRACT.md). Lisp không phụ thuộc Palette;
  `BHTDCL` vẫn cung cấp giao diện dự phòng khi DLL không nạp được.
* **Một điểm vào giao diện.** `BTH` và `BHT` là lệnh .NET cùng gọi một `PaletteHost`. Lisp không định nghĩa hai lệnh này,
  tránh xung đột và tránh mở song song DCL/Palette. `BHTPALETTE` và `BHTSHOW` chỉ là bí danh tương thích.
* **Tự nạp.** Autodesk Application Bundle nạp Lisp theo từng tài liệu và nạp DLL khi gọi lệnh. Khi dùng APPLOAD,
  Lisp tự `NETLOAD` `BHT.Palette.dll` đặt cạnh nó. Người dùng không cần thao tác NETLOAD thủ công.
* **Không viết lại thuật toán của Lisp trong C#**: nhãn, ký hiệu, ký hiệu ảnh, kiểm tra, thứ tự hiển thị → gọi `bht:api-*`.
  Phần viết lại trong C# (và lý do): mã hóa/giải mã bản ghi, tạo/sửa hồ sơ, gắn/bỏ ảnh (thao tác dữ liệu đơn giản cần chạy
  từ palette không chế độ mà không chiếm dòng lệnh), tìm đường dẫn JPG, tìm điểm/ảnh gần (hiển thị). Mỗi phần được
  **kiểm thử chéo với Lisp** trong Core Console (dump C# = dump Lisp; hồ sơ C# tạo được Lisp đọc giống bản Lisp tạo;
  đường dẫn JPG C# = `bht:api-photo-path`).
* **WinForms** (không WPF): giống quy ước repo GKIN-NET của người dùng (PaletteSet + UserControl WinForms), không cần XAML,
  build được bằng csc.exe của .NET Framework khi máy không có SDK/Visual Studio.

## AcadDispatcher (một lớp dùng chung)
* `ActiveDocument` — tài liệu hiện hành (có thể null).
* `IsBusy` — `Document.CommandInProgress` khác rỗng → palette **từ chối** thao tác ghi, báo người dùng.
* `RunWrite` — `Document.LockDocument()` + Transaction cho sửa DB trực tiếp từ UI không chế độ; bắt lỗi, Dispose đầy đủ.
* `RunInCommandContext` — `DocumentCollection.ExecuteInCommandContextAsync` (có trong API 2024; kiểu trả về
  `ExecutionResult`, không phải Task); ngoại lệ bắt **bên trong** callback; nếu đang ở ngữ cảnh lệnh thì chạy trực tiếp.
* `RunLisp` — `Application.Invoke` gọi `bht:api-*`; không có kết quả = LỖI.
* `SendCommand` — `SendStringToExecute` chỉ là gửi (fire-and-forget); `CommandWatcher` xác nhận qua
  CommandEnded / CommandCancelled / CommandFailed / LispEnded / LispCancelled rồi **đọc lại dữ liệu**; gửi ≠ thành công.
* Palette: `ImpliedSelectionChanged` có cờ chống đệ quy + hẹn giờ 300 ms (debounce); `DocumentActivated` /
  `DocumentToBeDestroyed` để gắn lại / gỡ sự kiện; bộ nhớ đệm dữ liệu bị hủy khi ObjectAppended / Modified / Erased.
