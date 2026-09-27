# BHT 0.4.0 — Vấn đề còn tồn tại

1. **Palette .NET chưa được chạy trong AutoCAD đầy đủ.** Mọi phần giao diện palette (gắn trái, kéo rộng, đồng bộ lựa chọn,
   xem JPG, chuyển / đóng bản vẽ, từ chối khi đang có lệnh, lỗi khóa tài liệu, tiêu điểm / vòng lặp sự kiện,
   ExecuteInCommandContextAsync) = **BLOCKED** — AutoCAD Core Console không có giao diện. Cần làm theo
   `CHECKLIST_NGHIEM_THU.md` mục P.
   - Đã kiểm trong Core Console: NETLOAD `BHT.Palette.dll` thành công (lệnh `BHTPALETTE` đã đăng ký); phần dữ liệu
     (BHT.Bridge) đọc/ghi giống hệt Lisp; gọi hàm Lisp qua `Application.Invoke`.
   - Bản rc đầu: gõ `BHTPALETTE` trong Core Console làm tiến trình dừng đột ngột (tạo PaletteSet khi không có giao diện).
     Bản 0.4.0 phát hiện Core Console và chỉ báo "cần AutoCAD đầy đủ".
2. **Hộp thoại DCL, chọn đối tượng bằng chuột, trình xem ảnh của Lisp** vẫn chỉ kiểm tĩnh / kiểm phần dữ liệu (như 0.3.3).
3. **Thứ tự hiển thị qua API:** AutoCAD từ chối lệnh DRAWORDER khi hàm Lisp được gọi qua `Application.Invoke`
   (acedInvoke). `bht:api-draworder` trả LỖI rõ ràng; palette dùng đường lệnh `BHTTHUTUVE` (SendStringToExecute; bạn nhấn
   Enter ở câu hỏi của lệnh). Đường lệnh này đã kiểm bằng dòng script trong Core Console, chưa kiểm từ palette thật.
4. **`Application.Invoke` chỉ trả kết quả khi Lisp đang rảnh.** Khi lệnh .NET bị gọi từ bên trong `(command …)` của Lisp,
   Invoke không trả gì → C# báo LỖI (không coi là thành công). Palette gọi từ ngữ cảnh ứng dụng qua
   ExecuteInCommandContextAsync — đường này chưa chạy được trong Core Console (BLOCKED, CHECKLIST P13/P15).
5. **Nhận diện ảnh nền IRT (tile).** Quy ước tên được suy ra từ các hằng trong file IRTv6 fix-5 (đó là bản dump bytecode
   đã dịch ngược, đọc được, chỉ đọc — không phải file mã hóa như ghi chú 0.3.3): tile lưu trong bộ nhớ đệm thư mục `IRT\`
   / `IRT.cache`; layer tùy tùy chọn CreateLayer + tiền tố/hậu tố của IRT, tắt thì tile nằm trên **layer hiện hành
   (có thể là layer 0)**. BHT 0.4.0 nhận theo đường dẫn thư mục + layer + tên file (cấu hình BHTTHUTUVE > C).
   - **Chưa thấy đường dẫn tile thật trên máy người dùng** (cần `LIST` một tile). Nếu IRT lưu tile ngoài thư mục tên `IRT`
     và layer / tên file không khớp, tile được giữ nguyên thứ tự và được báo "không nhận diện chắc chắn".
   - Ảnh trong Xref không được sắp. BHT không mở khóa layer; tile trên layer khóa vẫn được sắp (đã kiểm Core Console).
   - Đã kiểm hiệu năng: 156 tile phân loại ~15 ms, sắp thứ tự ~0,1 s (Core Console).
6. **Không dùng .NET SDK / Visual Studio:** máy build không có dotnet SDK, MSBuild, Visual Studio, .NET Framework 4.8
   Developer Pack. DLL được build bằng `csc.exe` của .NET Framework 4.x (C# 5), tham chiếu `C:\Windows\Microsoft.NET\
   Framework64\v4.0.30319` (4.8 runtime). Các file `.csproj` (SDK-style) và workflow GitHub Actions **chưa được chạy thử**
   (không có SDK trên máy này); workflow chỉ build BHT.Core + CoreTests và báo SKIP plugin.
7. **Bố trí nhãn không bảo đảm hết chồng lấn** (như 0.3.3: 526 điểm thật còn 26 / 1574 nhãn chồng lấn).
8. **Chế độ ưu tiên hồ sơ gỡ (không chỉ ẩn) nhãn phụ**; đường dẫn ảnh nối góc dưới-trái raster; hệ tọa độ ảnh
   (VN-2000, KTT 105°45', k = 0,9999) chưa được xác nhận — như 0.3.3.
9. **Bản vẽ 0.3.3 dùng kiểm thử N có 586 điểm** = 526 điểm thật + 60 điểm khu dày giả lập (phiên A của bộ kiểm 0.3.3).
10. **Kiểm thử KMZ 349 MB** không chạy lại (mã nhập KMZ không đổi từ 0.3.2).
