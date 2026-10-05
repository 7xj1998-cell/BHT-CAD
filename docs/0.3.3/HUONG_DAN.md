# BHT 0.3.3 — Hướng dẫn sử dụng

BHT là bộ lệnh AutoLISP quản lý điểm khảo sát RTK, hồ sơ đối tượng (biển báo, cọc tiêu, cột Km…), ảnh TimeMark (KMZ), tuyến / lý trình và xuất thống kê.

- File chương trình: **`BHT-0.3.3.lsp`** (một file duy nhất; bảng điều khiển DCL được tạo tạm khi gõ `BHT`).
- Bản 0.3.3 tiếp nối trực tiếp `BHT-0.3.2.lsp` (bản 0.3.2 giữ nguyên, không sửa). Bản vẽ làm bằng 0.3.2 mở được bằng 0.3.3, không mất dữ liệu.
- Dùng được với AutoCAD 2021–2024 và Civil 3D 2023 trên Windows. Đã kiểm thử bằng AutoCAD 2024 Core Console. Các phần giao diện (bảng DCL, chọn đối tượng bằng chuột, trình xem ảnh) cần nghiệm thu tay theo `CHECKLIST_NGHIEM_THU.md`.

## 1. Nạp chương trình (APPLOAD)

1. Kiểm tra biến **LISPSYS = 1** (gõ `LISPSYS` ở dòng lệnh).
   - Nếu đang là 0: đặt `LISPSYS` = 1, **đóng hẳn AutoCAD rồi mở lại**.
   - Nếu LISPSYS = 0, chữ tiếng Việt có dấu sẽ hiển thị sai.
2. Gõ `APPLOAD`, chọn `BHT-0.3.3.lsp`, bấm **Load**. Muốn tự nạp mỗi lần mở AutoCAD thì thêm vào *Startup Suite*, và **gỡ bản cũ khỏi Startup Suite**.
3. Khi nạp đúng, dòng lệnh hiện: **`BHT 0.3.3 đã nạp thành công.`**
4. Gõ `BHT` để mở bảng điều khiển. Góc bảng ghi "Phiên bản 0.3.3".

Không nạp cùng lúc bản cũ và bản 0.3.3 trong một phiên AutoCAD, vì các bản dùng chung tên hàm.

## 2. Quy trình làm việc (theo bảng `BHT`)

| Bước | Việc | Lệnh chính |
|---|---|---|
| 1 | Nhập điểm RTK | **`BHTNHAP`** (CSV trực tiếp: tên, Bắc, Đông, Z, mô tả; không tiêu đề) = cách **mặc định**. `BHTNHAPTSV` chỉ dùng cho file TSV trao đổi / chuẩn hóa; **không cần** nhập lại cùng dữ liệu bằng cả hai |
| 2 | Nhãn điểm | `BHTNHANDIEM`, `BHTANNHAN`, **`BHTSAPNHAN`**, **`BHTNHANTUDONG`** |
| 3 | Nhập TimeMark | `BHTKMZ`, `BHTANHNAP`, `BHTHETOADO` |
| 4 | Kiểm tra và xem ảnh | `BHTDONGBOANH`, `BHTXEMANH`, `BHTANH`, `BHTTHUMUCANH`, `BHTCHENANH`, `BHTNHANANH` |
| 5 | Ghép ảnh (chỉ đề xuất, người dùng duyệt) | `BHTGHEPANH`, `BHTXACNHANANH`, `BHTGANANH`, `BHTBOANH` |
| 6 | Hồ sơ đối tượng | `BHTDOITUONG`, `BHTSUADT`, `BHTXOADT`, `BHTTHEMDIEM`, `BHTBOTDIEM`, `BHTINFO` |
| 7 | Ký hiệu và thứ tự hiển thị | `BHTKYHIEU`, **`BHTTHUTUVE`** |
| 8 | Tuyến, Km, gói thầu | `BHTTUYEN`, `BHTMOCKM`, `BHTDSMOC`, `BHTLYTRINH`, `BHTGOITHAU`, `BHTPHANDOAN`, `BHTGANDOAN` |
| 9 | Xuất thống kê | `BHTXUAT`, `BHTKT`, `BHTTRANGTHAI` |
| Khác | Chẩn đoán | `BHTDIAG`, `BHTTEST`, `BHTHELP` |
| Bảo trì dữ liệu cũ | Chỉ dùng cho bản vẽ cũ | `BHTNANGCAP` (dữ liệu BHT 0.1), **`BHTVEMODEL`** (thực thể BHT lỡ tạo trong Layout) |

## 3. Lệnh mới / thay đổi trong 0.3.3

### Nhãn điểm RTK: bố trí tự động, sắp xếp lại, dời tay

**`BHTNHANDIEM`** (bí danh `BHTLABEL`). Các lựa chọn:

- `1` Tên · `2` Tên + mô tả · `3` Tên + mô tả + cao độ (mặc định).
- `4` Bật / tắt **ưu tiên hồ sơ**: điểm đã thuộc hồ sơ đối tượng chỉ còn nhãn tên, bớt rối ở chỗ có ký hiệu. Nhãn phụ được gỡ; tắt chế độ thì tạo lại. Dữ liệu điểm không đổi.
- `I` Bật / tắt dòng ID nội bộ.
- `S` Sắp xếp lại (như `BHTSAPNHAN`).
- `R` Trả nhãn về tự động (như `BHTNHANTUDONG`).
- `A` Ẩn · `H` Hiện · `C` Cài đặt (cao chữ, khoảng lệch, kiểu chữ) · `X` Xóa mọi nhãn BHT.

Nhãn mới được **bố trí tự động** để tránh chồng lấn:

- BHT thử 8 hướng quanh điểm, mỗi hướng 4 khoảng cách.
- BHT chọn chỗ ít đè nhất lên nhãn khác, ký hiệu đối tượng, ký hiệu ảnh, nhãn mã ảnh và các điểm RTK.
- **Điểm RTK không bao giờ bị di chuyển.** Chỉ chữ nhãn được đặt chỗ.
- Chạy lại `BHTNHANDIEM` khi dữ liệu không đổi thì không dời nhãn nào. Chỉ điểm mới, hoặc nhãn thay đổi nội dung / cỡ chữ, mới được bố trí lại.

**`BHTSAPNHAN`**: sắp xếp lại nhãn trong phạm vi bạn chọn.

- `V` vùng chọn (mặc định) · `D` danh sách ID hoặc tên điểm · `T` tất cả.
- Lệnh báo số nhãn còn chồng lấn **trước và sau**.
- Ở khu điểm quá dày có thể vẫn còn chồng lấn. Khi đó kéo nhãn bằng tay, giảm cao chữ, hoặc dùng chế độ tên / ưu tiên hồ sơ.

**Kéo nhãn bằng tay:**

- Dùng grip / MOVE như bình thường.
- BHT nhận ra nhãn đã bị dời và **giữ nguyên vị trí đó** ở mọi lần cập nhật sau, kể cả `BHTSAPNHAN` > Tất cả. Nội dung và cỡ chữ vẫn được cập nhật.
- `BHTINFO` trên điểm ghi "(dời tay)" hoặc "(tự động)" cho từng nhãn.

**`BHTNHANTUDONG`**: chọn điểm hoặc nhãn → bỏ trạng thái dời tay → BHT bố trí lại các nhãn đó.

Bản vẽ làm bằng 0.3.2:

- Lần đầu cập nhật, nhãn còn ở vị trí mặc định cũ được coi là tự động, nhãn đã bị kéo được coi là dời tay. **Không nhãn nào bị dời.**
- Muốn sắp lại cho gọn thì chạy `BHTSAPNHAN` > `T`.

### Hồ sơ đối tượng: không tạo trùng ngoài ý muốn

**`BHTDOITUONG`**: nếu điểm vừa chọn **đã thuộc hồ sơ khác**, lệnh hiện hồ sơ đó (ID, nhóm, mã, số trụ, các điểm, số ảnh, điểm chung) và hỏi:

- `X` Xem hồ sơ · `S` Sửa hồ sơ · `T` Thêm điểm đã chọn vào hồ sơ đó.
- `M` Tạo hồ sơ **mới** dùng chung điểm. Lệnh hỏi xác nhận thêm một lần, mặc định là Không.
- `H` Hủy (**mặc định khi bấm Enter**). Không tạo gì.

Nếu bộ điểm đã chọn **trùng khớp** hoàn toàn với một hồ sơ có sẵn, lệnh cảnh báo riêng: có thể hồ sơ đã được tạo rồi.

Sau khi tạo hồ sơ, lệnh hỏi "Chèn ký hiệu … ngay? [C/K]". Sau khi sửa hồ sơ, thêm hoặc bớt điểm, ký hiệu đã có được cập nhật tại chỗ.

### `BHTKYHIEU`: cập nhật theo ID

- Enter: **cập nhật theo object_id**.
  - Tạo ký hiệu cho hồ sơ chưa có ký hiệu.
  - Sửa ký hiệu đã có ngay tại chỗ (đổi nhóm, đổi mã, thêm hoặc bớt điểm).
  - Chỉ xóa ký hiệu của hồ sơ đã bị xóa.
  - Không xóa rồi vẽ lại toàn bộ.
- Ký hiệu hoặc nhãn ký hiệu mà bạn đã dời, xoay hay đổi tỷ lệ được **giữ nguyên** khi cập nhật.
- `R`: chọn ký hiệu → trả về vị trí tự động (trung bình tọa độ các điểm RTK của hồ sơ, góc 0, tỷ lệ cài đặt).
- `C`: cài đặt tỷ lệ ký hiệu, cao chữ nhãn.
- Hồ sơ (XRecord trong bản vẽ) là nơi lưu dữ liệu. Ký hiệu chỉ là lớp thể hiện, xóa ký hiệu không mất hồ sơ.

### `BHTTHUTUVE`: thứ tự hiển thị

Sắp thứ tự hiển thị, từ trên xuống dưới:

1. nhãn (điểm RTK, ký hiệu, mã ảnh);
2. ký hiệu đối tượng, điểm RTK, ký hiệu ảnh, đường dẫn ảnh;
3. raster ảnh BHT;
4. các thực thể khác (giữ nguyên);
5. ảnh nền IRT (dưới cùng).

Cách nhận diện:

- BHT chỉ sắp thực thể mang XData BHT.
- **Ảnh nền IRT** được nhận diện theo mẫu tên layer, hoặc tên ảnh / tên file (không xét tên thư mục). Mẫu mặc định: `IRT*`, `*GOOGLE*`, `*SATELLITE*`, `*TILE*`, `*BING*`, `*ESRI*`… Có thể sửa bằng `BHTTHUTUVE` > `C`, mẫu được lưu trong bản vẽ.
- BHT chỉ đưa ảnh IRT xuống dưới, **không sửa, không xóa dữ liệu IRT**.
- Ảnh không nhận diện chắc chắn và ảnh trong Xref được **giữ nguyên**; lệnh báo số lượng.

Nếu không thấy thay đổi, kiểm tra biến `DRAWORDERCTL`, nên đặt bằng 3.

### Ảnh

- **`BHTCHENANH`**:
  - chỉ chèn các ảnh bạn chọn;
  - hỏi thêm "Vẽ đường dẫn từ ký hiệu ảnh tới ảnh raster?". Đường dẫn là LINE trên layer `BHT_ANH_DAN`, tự đi theo khi ký hiệu hoặc raster đổi chỗ (`BHTDONGBOANH`), tự xóa khi gỡ raster.
- Chèn raster xong, chạy `BHTTHUTUVE` để nhãn và ký hiệu nằm trên ảnh.
- **`BHTTHUMUCANH`**: thư mục bạn chỉ định được ưu tiên dùng, kể cả khi thư mục cũ vẫn còn. Đường dẫn raster đã chèn được cập nhật theo; AutoCAD có thể cần `-IMAGE` > Reload.

### Nhập CSV / TSV

- `BHTNHAP` (CSV trực tiếp) là cách nhập mặc định.
- `BHTNHAPTSV` dành cho `BHT_RTK.tsv`, là định dạng trao đổi / chuẩn hóa.
- Nếu nhập lại cùng dữ liệu bằng định dạng kia, BHT báo "ĐÃ CÓ trong bản vẽ … KHÔNG cần nhập cùng một bộ dữ liệu bằng cả CSV và TSV" và không tạo điểm trùng.

### `BHTVEMODEL` (bảo trì dữ liệu cũ)

Các bản trước 0.3.3 có lỗi: nếu chạy BHT khi đang ở tab **Layout**, điểm, nhãn và ký hiệu bị tạo trong paper space. Từ 0.3.3, BHT luôn tạo trong **Model**.

Nếu `BHTKT` báo "… thực thể BHT nằm trong Layout":

1. Gõ `BHTVEMODEL`.
2. Trả lời `C` để chuyển các thực thể đó về Model. Tọa độ, layer, XData giữ nguyên; hồ sơ, ảnh và nhãn không mất.
3. Raster ảnh không chuyển được. Gỡ và chèn lại bằng `BHTCHENANH`.

## 4. Các lệnh từ 0.3.2 (vẫn dùng như cũ)

### Nhãn điểm: layer, kiểu chữ, nội dung (như 0.3.2)

- Layer: `BHT_RTK_TEN`, `BHT_RTK_MOTA`, `BHT_RTK_CAO_DO`, `BHT_RTK_ID`. Kiểu chữ: `BHT_ARIAL` (arial.ttf).
- Nội dung lấy **nguyên văn** từ CSV gốc; cao độ ghi `H = <Z gốc>`, không làm tròn; mô tả rỗng thì không có dòng mô tả.
- Mỗi nhãn gắn với ID điểm qua XData `BHT_NHAN`; chạy lại không nhân đôi; chỉ sửa / xóa TEXT có XData `BHT_NHAN`.
- Sau khi nhập CSV, chương trình hỏi có tạo / cập nhật nhãn ngay không.

### `BHTANNHAN`

Ẩn hoặc hiện toàn bộ nhãn điểm RTK. Lệnh chỉ bật / tắt layer, không xóa gì.

### `BHTDONGBOANH` (bí danh `BHTSYNCANH`) — đồng bộ ký hiệu ảnh

Dựng lại ký hiệu vị trí chụp (block `BHT_ANH_GPS`) và nhãn mã ảnh (layer `BHT_ANH_TEN`) từ bản ghi ảnh đã lưu trong bản vẽ:

- tạo ký hiệu còn thiếu, kể cả ký hiệu bị người dùng xóa;
- xóa ký hiệu trùng;
- dời ký hiệu bị kéo lệch về đúng vị trí;
- tính lại vị trí khi đổi hệ tọa độ;
- xóa ký hiệu không còn bản ghi (chỉ xóa thực thể có XData ảnh của BHT).

Ảnh GPS 0,0 vẫn **giữ bản ghi** nhưng **không có ký hiệu** (không bao giờ đặt ở gốc 0,0). Những ảnh này ghép thủ công.

`BHTANHNAP` và `BHTHETOADO` tự gọi đồng bộ.

### `BHTNHANANH`

Ẩn hoặc hiện nhãn mã ảnh (layer `BHT_ANH_TEN`).

### `BHTXEMANH` — xem ảnh

1. Chọn ký hiệu ảnh, nhãn mã ảnh, raster, điểm RTK / nhãn điểm, hoặc gõ `M` để nhập mã ảnh.
2. Chương trình hiện thông tin ảnh (thời gian, GPS, vị trí chụp, trạng thái ghép, đối tượng, đường dẫn JPG) và **mở JPG bằng trình xem ảnh mặc định của Windows**.
   - Chọn điểm RTK: chương trình liệt kê ảnh đã xác nhận, ảnh được đề xuất và ảnh chụp gần. Ảnh chụp gần chỉ là gợi ý.
3. Các lựa chọn tiếp theo: `S` ảnh sau · `T` ảnh trước · `G` gắn ảnh vào đối tượng (xác nhận thủ công, liên kết hai chiều) · `M` mở lại.

Hộp thoại DCL của AutoCAD **không hiển thị được JPG**, nên BHT mở ảnh bằng trình xem của Windows. Muốn xem ảnh ngay trên bản vẽ thì dùng `BHTCHENANH`.

### `BHTANH`

Giữ cách dùng của 0.3.1: nhập mã ảnh để mở. Thêm hai cách mới: Enter để chọn trên bản vẽ; `T` để đặt thư mục ảnh.

### `BHTTHUMUCANH` — chỉ lại thư mục ảnh

Dùng khi chuyển thư mục dự án làm mất đường dẫn ảnh. Chọn thư mục chứa `BHT_PHOTO.tsv` hoặc thư mục `photos`. BHT tìm lại JPG cho mọi ảnh, báo số tìm thấy / thiếu, và cập nhật luôn đường dẫn các raster đã chèn.

Khi thiếu JPG, thông báo ghi rõ tên file và các nơi đã tìm.

### `BHTCHENANH` — chèn JPG làm raster

**Chỉ chèn các ảnh bạn chọn** (nhập mã hoặc chọn ký hiệu), không bao giờ chèn cả 205 ảnh.

- Ảnh được chèn trên layer `BHT_ANH_RASTER`, chiều rộng do bạn nhập (đơn vị bản vẽ).
- Không chèn trùng một ảnh.
- Ảnh không có GPS thì phải chọn điểm chèn.
- Tùy chọn `X` để gỡ raster theo mã; ảnh gốc và bản ghi vẫn giữ.

### `BHTTRANGTHAI`

In trạng thái chi tiết của bản vẽ kèm các ghi chú hướng dẫn.

### `BHTINFO`

Chọn điểm RTK, nhãn điểm, ký hiệu ảnh, raster ảnh hoặc ký hiệu đối tượng để xem dữ liệu BHT. Nếu là ảnh, lệnh hỏi có mở JPG không.

### `BHTKT`

Kiểm tra thêm:
- nhãn điểm: trùng, mồ côi, lệch nội dung;
- ký hiệu ảnh: trùng, ở gốc 0,0, ảnh GPS 0,0 có ký hiệu, mồ côi, lệch vị trí, thiếu ký hiệu;
- thiếu JPG;
- liên kết ảnh ↔ hồ sơ một chiều.

Các lệnh và bí danh cũ vẫn dùng được.

## 5. Nguyên tắc dữ liệu (không đổi)

- CAD X = Easting (Đông), Y = Northing (Bắc), Z = cao độ. Không làm tròn và không sửa dữ liệu khảo sát. BHT không bao giờ thay đổi tọa độ POINT.
- Một điểm RTK không phải một biển. Một đối tượng có thể gồm nhiều điểm và nhiều ảnh; một trụ có thể có nhiều mặt biển.
- GPS ảnh là vị trí **chụp**, không ghi đè RTK. Ghép ảnh tự động chỉ là đề xuất.
- Không đọc hình học của proxy TDT (TDTDBALIGNMENT). Lý trình chỉ tính trên Polyline tham chiếu và mốc Km đã xác nhận.
- Hệ tọa độ ảnh mặc định là VN-2000 múi 3°, KTT 105°45', k = 0.9999. **Hệ này chưa được xác nhận chính thức**; kiểm tra bằng `BHTHETOADO`.

## 6. Lưu ý

- Luôn làm việc trên **bản sao** bản vẽ.
- Ảnh GPS 0,0 (`BOT19-P-000204`, `-000205` trong KMZ mẫu) được giữ nhưng không có ký hiệu. Ghép thủ công bằng `BHTGANANH` hoặc `BHTXEMANH` > `G`.
- Danh sách những điểm cần kiểm tra tay trong AutoCAD đầy đủ nằm ở `CHECKLIST_NGHIEM_THU.md`. Các vấn đề còn tồn tại nằm ở `KNOWN_ISSUES.md`.
