# CHANGELOG

## 0.4.2 (2026-09-27)

- Điểm RTK mặc định dùng `PDMODE=3` (dấu X) và `PDSIZE=1`; thêm `BHTKIEUDIEM` và nút Palette để đổi kích thước, áp dụng lại kiểu điểm và sắp nhãn.
- Mở rộng bố trí nhãn lên 64 vị trí ứng viên, tính cả vùng dấu X; bộ dữ liệu hồi quy 526 điểm còn 0/1574 nhãn chồng lấn sau khi sắp.
- Sửa bố cục thẻ **Ảnh** để danh sách, ảnh xem trước và nút thao tác không che nhau; thêm hướng dẫn và nút nhập KMZ/chỉ lại thư mục khi chưa có ảnh.
- Thẻ **Hồ sơ** cho nhập, xóa hoặc tính lý trình; chấp nhận `Km39+050.5`, `39+050,5` hoặc số mét và lưu trạng thái `NHAP_TAY`.
- Danh sách ảnh của hồ sơ có trạng thái rỗng rõ ràng và điều hướng sang thẻ Ảnh.
- Nhãn ký hiệu đặt phía trên block và luôn bắt đầu bằng `object_id`, sau đó là mã hiệu.
- Thêm `BHTBLOCK`: nạp một DWG làm block tùy chọn cho từng nhóm, lấy `INSBASE` làm tâm chèn, tự giữ hệ số đơn vị và có thể trở lại block mặc định.
- Giữ nguyên hợp đồng dữ liệu `BHT_V02` và khả năng đọc bản vẽ 0.3.2–0.4.1.

## 0.4.1 (2026-09-27)

- `BTH` và `BHT` cùng mở một .NET Palette duy nhất; giữ `BHTPALETTE` làm bí danh tương thích.
- Thêm Autodesk Application Bundle và bộ cài tự động. Cách APPLOAD tự nạp DLL cạnh file Lisp, không cần người dùng chạy `NETLOAD`.
- Chuyển DCL sang lệnh dự phòng `BHTDCL`; sửa lỗi font bằng tệp DCL UTF-8 BOM.
- Rút gọn tên thẻ để không bị cắt chữ; bổ sung nhập CSV, nhập KMZ và tiếp tục quy trình ở thẻ Tổng quan.
- Cho phép chọn điểm trực tiếp trên CAD để tạo hoặc bổ sung hồ sơ trong khi Palette vẫn mở.
- Đồng bộ chọn điểm hai chiều giữa danh sách và bản vẽ; tiếp tục tự làm mới khi đổi tài liệu hoặc dữ liệu DWG.
- Giữ nguyên hợp đồng dữ liệu `BHT_V02` và các lệnh Lisp hiện có.

## 0.4.0 (2026-09-27)
* Plugin .NET (net48, x64): BHT.Core, BHT.Bridge, BHT.Palette; lệnh `BHTPALETTE` mở palette
  "BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN" (5 thẻ: Tổng quan, Điểm khảo sát, Ảnh TimeMark, Hồ sơ đối tượng, Tuyến & báo cáo).
* BHT-0.4.0.lsp (từ 0.3.3): hàm API `bht:api-*` cho plugin (vl-acad-defun); `BHTPALETTE` trong Lisp chỉ hướng dẫn
  NETLOAD khi plugin chưa nạp; BHTTEST 46 mục.
* BHTTHUTUVE: nhận ảnh nền IRT dạng lưới nhiều tile (mỗi tile một IMAGE, kể cả trên layer 0) theo đường dẫn thư mục
  `IRT\` / `IRT.cache` (mẫu `irt_mau_thumuc`, cấu hình BHTTHUTUVE > C); đọc cấu hình một lần cho cả lưới; báo số tile
  trên layer khóa; không bao giờ coi ảnh BHT là IRT.
* Định dạng dữ liệu DWG không đổi so với 0.3.3 (docs/DATA_CONTRACT.md).

## 0.3.3 và cũ hơn
Xem CHANGELOG trong các gói phát hành `release/BHT-0.3.x`.
