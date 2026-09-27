# BHT — Nhật ký thay đổi

## 0.4.0 (2026-09-27)

### Mới: plugin .NET (tùy chọn) — palette "BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN"
- `BHT.Palette.dll` (+ `BHT.Bridge.dll`, `BHT.Core.dll`), .NET Framework 4.8 x64, AssemblyVersion 0.4.0.0 / FileVersion 0.4.0.1.
- `NETLOAD BHT.Palette.dll` rồi `BHTPALETTE`: PaletteSet GUID cố định, lần đầu gắn trái, nhớ vị trí; 5 thẻ: Tổng quan,
  Điểm khảo sát, Ảnh TimeMark (xem JPG trong palette), Hồ sơ đối tượng (tạo cọc tiêu từ POINT, chèn/cập nhật ký hiệu),
  Tuyến & báo cáo.
- Dữ liệu vẫn nằm trong bản vẽ (dictionary BHT_V02 / XRecord / XData), C# đọc/ghi đúng định dạng Lisp
  (docs/DATA_CONTRACT.md). Thuật toán nhãn / ký hiệu / ký hiệu ảnh / kiểm tra / thứ tự hiển thị vẫn chỉ ở Lisp.
- Lệnh kiểm thử trong BHT.Bridge (dùng được trong Core Console): `BHTNETINFO`, `BHTNETDUMP`, `BHTNETTAO`, `BHTNETSUA`,
  `BHTNETTHEMDIEM`, `BHTNETGANANH`, `BHTNETBOANH`, `BHTNETLISP`, `BHTNETDIEUPHOI`, `BHTNETCACHE`, `BHTNETPING`.

### BHT-0.4.0.lsp (từ 0.3.3)
- Hàm API `bht:api-*` (12 hàm, đăng ký `vl-acad-defun`) cho plugin: phiên bản, thông tin (giống BHTINFO), đường dẫn JPG,
  ký hiệu theo object_id, nhãn theo phạm vi, ký hiệu ảnh, thống kê ảnh, kiểm tra, thứ tự hiển thị. Trả danh sách chuỗi
  `("OK" …)` / `("LOI" lý do)`; không hỏi người dùng.
- `BHTPALETTE` (Lisp) khi chưa nạp plugin: in hướng dẫn NETLOAD. Lệnh `BHT` vẫn mở bảng DCL; Lisp không phụ thuộc palette.
- `BHTTHUTUVE`: ảnh nền IRT dạng **lưới nhiều tile** (mỗi tile 1 IMAGE, kể cả trên layer 0) được nhận theo **đường dẫn thư
  mục** `IRT\` / `IRT.cache` (mẫu mới `irt_mau_thumuc`), ngoài mẫu layer / tên file; cấu hình đọc một lần cho cả lưới;
  báo số tile trên layer khóa; không bao giờ coi raster / thư mục ảnh BHT là IRT. BHTTHUTUVE > C hỏi thêm mẫu thư mục.
- BHTTEST: 46 mục (thêm API và mẫu thư mục IRT).
- Định dạng dữ liệu bản vẽ không đổi; bản vẽ 0.3.2 / 0.3.3 mở bình thường.

## 0.3.3 (2026-09-27)

Tiếp nối trực tiếp `BHT-0.3.2.lsp`. Bản 0.3.2 và các bản trước giữ nguyên, không sửa. Bản vẽ làm bằng 0.3.2 mở được bằng 0.3.3 và không mất dữ liệu (đã kiểm, xem TEST_REPORT.md, phiên L và L2).

### Nhãn điểm RTK
- **Bố trí nhãn tránh chồng lấn.**
  - Hộp bao chữ được đo bằng `textbox`.
  - Mỗi khối nhãn thử 8 hướng quanh điểm × 4 bán kính, tổng 32 vị trí.
  - Vị trí được chọn sao cho ít đè nhất lên nhãn khác, ký hiệu đối tượng, ký hiệu ảnh, nhãn mã ảnh và các điểm RTK.
  - Chạy 2 lượt.
  - POINT RTK **không bao giờ bị di chuyển**.
- **`BHTSAPNHAN`** (mới): sắp xếp lại nhãn trong một phạm vi do người dùng chọn: vùng chọn, danh sách ID/tên điểm, hoặc tất cả. Lệnh báo số nhãn còn chồng lấn trước và sau khi sắp. Ở khu dày điểm vẫn có thể còn chồng lấn, lệnh không khẳng định là hết.
- **Nhãn dời tay được giữ.**
  - XData `BHT_NHAN` lưu vị trí BHT đã đặt và trạng thái `TU_DONG` / `TAY`.
  - Nếu người dùng kéo nhãn đi, BHT nhận ra (vị trí thực khác vị trí đã lưu) và từ đó giữ nguyên vị trí đó. Nội dung và cỡ chữ vẫn được cập nhật.
- **`BHTNHANTUDONG`** (mới): trả nhãn của các điểm đã chọn về vị trí tự động.
- **`BHTNHANDIEM`**: thêm các lựa chọn `4` (chế độ ưu tiên hồ sơ), `S` (sắp xếp lại), `R` (trả về tự động).
- **Chế độ ưu tiên hồ sơ:** điểm đã thuộc hồ sơ đối tượng chỉ giữ nhãn TÊN. Nhãn phụ (mô tả, cao độ, ID) bị gỡ, không mất dữ liệu; tắt chế độ thì nhãn phụ tạo lại.
- **Nhãn 0.3.2 được nâng cấp XData tự động.** Nhãn còn ở vị trí mặc định của 0.3.2 thành `TU_DONG`; nhãn đã bị dời thành `TAY`. Lần cập nhật đầu tiên **không dời nhãn nào**.

### Hồ sơ đối tượng
- **`BHTDOITUONG` khi chọn điểm đã thuộc hồ sơ khác:**
  - Hiện tóm tắt hồ sơ đó (ID, nhóm, mã, số trụ, các điểm, số ảnh, điểm chung).
  - Cho chọn: `X` xem · `S` sửa · `T` thêm điểm đã chọn vào hồ sơ có sẵn · `M` tạo hồ sơ MỚI dùng chung điểm (phải xác nhận thêm lần nữa, mặc định K) · `H` hủy.
  - **Mặc định (Enter) là HỦY**: không tạo hồ sơ mới.
  - Bộ điểm trùng khớp hoàn toàn với một hồ sơ có sẵn thì có cảnh báo riêng.
- Sau khi tạo hồ sơ, lệnh hỏi có chèn ký hiệu ngay không. Sửa hồ sơ, thêm hoặc bớt điểm thì ký hiệu đã có được cập nhật.
- `BHTTHEMDIEM` cảnh báo khi điểm cần thêm đã thuộc hồ sơ khác (mặc định không thêm).

### Ký hiệu đối tượng (`BHTKYHIEU`)
- **Cập nhật theo object_id**, không còn xóa hết rồi vẽ lại:
  - tạo ký hiệu còn thiếu;
  - sửa ký hiệu thay đổi ngay trên thực thể đang có;
  - chỉ xóa ký hiệu của hồ sơ đã bị xóa;
  - xóa bản trùng.
- Vị trí, góc xoay, tỷ lệ mà người dùng đặt cho ký hiệu và nhãn ký hiệu được giữ (trạng thái `TAY` trong XData `BHT_KH`).
- `BHTKYHIEU` > `R`: trả ký hiệu đã chọn về vị trí tự động.
- Ký hiệu 0.3.2 được nhận ra theo object_id, không vẽ trùng và không bị dời.
- Không đụng thực thể không mang XData `BHT_KH`, kể cả INSERT cùng tên block.

### Thứ tự hiển thị (`BHTTHUTUVE`, mới)
- Thứ tự từ trên xuống dưới: nhãn (RTK, ký hiệu, mã ảnh) > ký hiệu / POINT / ký hiệu ảnh / đường dẫn > raster ảnh BHT > (thực thể khác) > ảnh nền IRT.
- BHT dùng lệnh DRAWORDER, chỉ trên thực thể nhận diện chính xác bằng XData BHT.
- **Ảnh nền IRT** được nhận diện theo mẫu tên layer / tên ảnh / tên file, cài được bằng `BHTTHUTUVE` > `C`. BHT chỉ đưa các ảnh này xuống dưới, không sửa và không xóa.
- Ảnh không nhận diện chắc chắn, và ảnh nằm trong Xref, được giữ nguyên thứ tự; lệnh báo số lượng các ảnh này.

### Ảnh
- `BHTCHENANH` có thêm tùy chọn **đường dẫn** (LINE, layer `BHT_ANH_DAN`) từ ký hiệu ảnh tới raster. Đường dẫn tự cập nhật khi đồng bộ ảnh, và tự xóa khi gỡ raster.
- `BHTTHUMUCANH`: thư mục người dùng chỉ định được **ưu tiên** hơn thư mục gốc lúc nhập, kể cả khi thư mục cũ vẫn còn.
- Đã kiểm lại: nhập lại ảnh không tạo trùng ký hiệu; đổi hệ tọa độ rồi đổi lại thì ký hiệu về đúng chỗ; nhập / đồng bộ ảnh không bao giờ tự chèn raster hàng loạt.

### Sửa lỗi quan trọng: thực thể BHT bị tạo trong Layout
- Lỗi có từ các bản trước. Khi chạy BHT lúc đang ở tab **Layout** (paper space), điểm, nhãn, ký hiệu và ký hiệu ảnh được tạo trong paper space, tại tọa độ khảo sát nên nằm ngoài khổ giấy.
- Từ 0.3.3, mọi thực thể BHT luôn được tạo trong **Model**. Lệnh `-IMAGE` và `DRAWORDER` tạm chuyển sang Model rồi trả lại tab cũ.
- **`BHTVEMODEL`** (mới, nhóm "Bảo trì dữ liệu cũ"):
  - chuyển các thực thể BHT lỡ nằm trong Layout về Model;
  - giữ nguyên tọa độ, layer, XData; handle thực thể sẽ đổi;
  - phải xác nhận trước khi chạy;
  - raster không chuyển được: lệnh báo để chèn lại.
- `BHTKT` cảnh báo khi có thực thể BHT nằm trong Layout.

### Nhập dữ liệu và bảng điều khiển
- CSV nhập trực tiếp là cách **mặc định**. TSV (`BHTNHAPTSV`) được ghi rõ là định dạng trao đổi / chuẩn hóa.
- Dataset ghi thêm định dạng đã nhập (`CSV`, `TSV`, `CSV+TSV`). Nhập lại cùng dữ liệu bằng định dạng kia sẽ có cảnh báo: không thêm điểm, không tạo trùng, không cần nhập cả hai.
- Bảng `BHT`:
  - có 42 nút;
  - thêm nút Sắp xếp nhãn, Trả nhãn về tự động, Sắp thứ tự hiển thị;
  - "Nâng cấp dữ liệu V0.1" và "Chuyển BHT từ Layout về Model" được chuyển vào nhóm **Bảo trì dữ liệu cũ**.
- `BHTINFO` trên điểm RTK ghi rõ từng nhãn đang ở trạng thái tự động hay dời tay.
- `BHTTEST` có 42 kiểm tra hàm (0.3.2 có 35). `BHTKT` kiểm thêm: số ký hiệu / nhãn đặt tay, hồ sơ chưa có ký hiệu, thực thể ngoài Model.

### Lệnh mới
`BHTSAPNHAN`, `BHTNHANTUDONG`, `BHTTHUTUVE`, `BHTVEMODEL`.

---
Các phiên bản trước: xem CHANGELOG trong `release\BHT-0.3.2\`.
