# CHANGELOG

## 0.4.5 (2026-09-29)

- Đã tích hợp TDTSolution 9.1 bản thường tại `C:\Program Files (x86)\TDT Solution 2022\`; không dò hoặc dùng TDT 9.1 Pro.
- Đã thêm `BHTTUYENTDT`: khi module TDT đã nạp và đối tượng tim không còn là proxy, `Tdt91Interop` mở tim `ForRead`, gọi `Entity.Explode` rồi tạo hoặc cập nhật một Polyline riêng trên layer `BHT_TUYEN_TDT`. BHT tính lý trình trên bản sao này và không gọi `vlax-curve-*` trực tiếp trên `TDTDBALIGNMENT`.
- Đã thêm `TdtSignLibrary`: đọc danh mục 412 mã từ bản TDT đang cài, hiện gợi ý `Mã — Tên biển` trong Palette và clone block vector được chọn vào DWG. Tài sản TDT không được sửa và không nằm trong gói BHT.
- Đã chuẩn hóa tỷ lệ hiển thị biển TDT: mặt biển scale `0.2`, cột cao `0.6` đơn vị; biển tự đặt ra ngoài tim theo phía đường, có leader về đúng điểm RTK và nhãn chỉ hiện mã biển cùng lý trình.
- Đã bổ sung báo cáo Excel `.xlsx` Unicode gồm sheet tổng hợp và danh sách biển: STT, công trình, đoạn/gói, loại biển, mã/tên biển, phía, lý trình, tình trạng, số trụ/mặt, trạng thái kiểm tra, ghi chú và ID hồ sơ.
- Đã rút gọn thẻ Tuyến & báo cáo còn sáu thao tác chính; các lệnh ít dùng nằm trong **Công cụ nâng cao**. Báo cáo dài mở trong hộp thoại có thể thay đổi kích thước và sao chép; vùng trạng thái dưới Palette không còn nhận con trỏ nhập.
- Đã cập nhật bố trí nhãn, kích thước chữ mặc định và thứ tự hiển thị; POINT RTK vẫn là dấu X kích thước 1 đơn vị, không di chuyển và không làm tròn tọa độ.
- Đã đồng bộ `BHT-0.4.5.lsp`, `BHT.Core`, `BHT.Bridge`, `BHT.Palette`, Application Bundle và bộ cài về phiên bản 0.4.5.
- Kiểm thử phát hành: 62 PASS Core; 172 PASS, 0 FAIL, 1 BLOCKED trên AutoCAD Core Console. Mục BLOCKED là mở giao diện DCL do Core Console không có UI và được chuyển sang checklist nghiệm thu thủ công.

## 0.4.4 (2026-09-28)

- Hợp nhất thư viện biển báo vào `BHT-0.4.4.lsp`; người dùng chỉ APPLOAD một file Lisp.
- Rà soát 205 ảnh trong KMZ tuyến DT830, ưu tiên các nhóm xuất hiện thực tế: W.207, R.412, W.239a + S.509a, W.245a, W.209, I.414, I.423a, I.428a, I.434a và các biển hạn chế P.
- Sửa các mã sai trong bản nháp: tốc độ tối đa là P.127, P.102 là cấm đi ngược chiều; giao nhau với đường ưu tiên là W.208, W.201 là chỗ ngoặt; W.245 là đi chậm; I.401/I.407 không phải cột Km/chỉ hướng đường.
- Block biển báo có điểm chèn tại chân cột `(0,0)`, tên định nghĩa mang hậu tố `V044`, màu và hình học độc lập với layer; hồ sơ `BIEN_BAO` tự chọn block theo trường `ma_hieu`.
- Thêm `BHTBBDANHMUC`; `BHTBLOCK` có lựa chọn `D` để xem danh mục chuẩn trước khi nạp DWG tùy chọn.
- Kiểm tra thư viện cục bộ của TDT Solution 2022: tách được 5 DWG chứa 329 block vector và xuất danh mục 412 biển ra CSV UTF-8 BOM; bổ sung script kiểm tra chỉ đọc, không đóng gói tài sản TDT.
- Thêm DWG/PNG gallery của 19 block và hồi quy hình học, mã hiệu, tải Lisp, dữ liệu/ảnh/tuyến/plugin: 228 PASS, 0 FAIL.

## 0.4.3 (2026-09-28)

- Đồng bộ chặt phiên bản Lisp/.NET; tiêu đề Palette lấy trực tiếp từ assembly và bộ cài chặn khi AutoCAD còn chạy để tránh DLL cũ bị giữ trong bộ nhớ.
- Palette mở mặc định bên trái rộng 430 px, dùng bảng màu xanh mới, bỏ hàng gợi ý rời bị cắt chữ và có vùng thông báo nhiều dòng.
- Thêm bộ đệm `bht:api-messages`: kết quả lệnh tương tác được hiện trong Palette sau khi lệnh kết thúc.
- CSV dùng UTF-8 BOM với tiêu đề tiếng Việt có dấu.
- Nhãn ký hiệu hiển thị tên nghiệp vụ và mã/lý trình, ví dụ `Cọc tiêu Km 48+500`, không hiện ID hồ sơ nội bộ.
- Vẽ lại block mặc định Cọc tiêu và Cột Km theo mẫu; dùng tên định nghĩa phiên bản mới để cập nhật được cả bản vẽ đã chứa block cũ.

## 0.4.2 (2026-09-27)

- Điểm RTK mặc định dùng `PDMODE=3` (dấu X) và `PDSIZE=1`; thêm `BHTKIEUDIEM` và nút Palette để đổi kích thước, áp dụng lại kiểu điểm và sắp nhãn.
- Mở rộng bố trí nhãn lên 64 vị trí ứng viên, tính cả vùng dấu X; bộ dữ liệu hồi quy 526 điểm còn 0/1574 nhãn chồng lấn sau khi sắp.
- Sửa bố cục thẻ **Ảnh** để danh sách, ảnh xem trước và nút thao tác không che nhau; thêm hướng dẫn và nút nhập KMZ/chỉ lại thư mục khi chưa có ảnh.
- Thẻ **Hồ sơ** cho nhập, xóa hoặc tính lý trình; chấp nhận `Km39+050.5`, `39+050,5` hoặc số mét và lưu trạng thái `NHAP_TAY`.
- Danh sách ảnh của hồ sơ hiện rõ `Chưa có ảnh` và điều hướng sang thẻ Ảnh.
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
