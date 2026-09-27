# BHT 0.4.1 — Hướng dẫn sử dụng

BHT là bộ lệnh AutoLISP quản lý điểm khảo sát RTK, hồ sơ đối tượng (biển báo, cọc tiêu, cột Km…), ảnh TimeMark (KMZ), tuyến / lý trình và xuất thống kê.

- Lệnh chính: **`BTH`** hoặc **`BHT`** mở một Palette gắn bên trái AutoCAD.
- Bản 0.4.1 gồm `BHT-0.4.1.lsp`, `BHT.Palette.dll`, `BHT.Bridge.dll` và `BHT.Core.dll`.
- `BHTDCL` mở bảng DCL dự phòng khi Palette không nạp được. DCL dùng UTF-8 BOM để hiển thị đúng tiếng Việt.
- Định dạng dữ liệu trong bản vẽ không đổi: bản vẽ từ 0.3.2 đến 0.4.0 mở bằng 0.4.1 mà không cần chuyển đổi.
- Mục tiêu hỗ trợ AutoCAD 2021–2024 và Civil 3D 2023 trên Windows.

## 1. Cài đặt khuyến nghị

1. Đóng AutoCAD.
2. Giải nén gói `BHT-0.4.1.zip` và chạy `INSTALL_BHT.cmd`.
3. Mở AutoCAD, gõ `BTH` hoặc `BHT`.

AutoCAD tự nhận `BHT.bundle`; không cần `APPLOAD` hoặc `NETLOAD`. Nếu từng cài bản cũ bằng Startup Suite, hãy gỡ file Lisp cũ để tránh hai phiên bản cùng nạp.

## 1b. Cách di động bằng APPLOAD

1. Đặt `BHT-0.4.1.lsp` và ba DLL trong cùng một thư mục tin cậy.
2. Kiểm tra **LISPSYS = 1**. Nếu phải đổi từ 0 sang 1, khởi động lại AutoCAD.
3. Gõ `APPLOAD`, chọn duy nhất `BHT-0.4.1.lsp`. Lisp tự nạp DLL cạnh nó.
4. Khi dòng lệnh báo `BHT 0.4.1 đã nạp thành công`, gõ `BTH` hoặc `BHT`.

Nếu Palette không nạp được, gõ `BHTLOAD` để thử lại và đọc lỗi tại dòng lệnh. Bạn vẫn có thể dùng `BHTDCL` trong lúc xử lý DLL.

**SECURELOAD / TRUSTEDPATHS:** nếu AutoCAD hỏi có nạp mã từ thư mục này hay không, chọn nạp hoặc thêm thư mục BHT vào Options → Files → Trusted Locations. Không cần đặt `SECURELOAD = 0`.

### Các thẻ của palette
* **A Tổng quan** — số điểm RTK (dữ liệu đo) và số hồ sơ đối tượng (đơn vị quản lý) tách riêng; ảnh (đã ghép / chưa ghép,
  có / không GPS), tuyến, đoạn, cảnh báo kiểm tra.
* **B Điểm khảo sát** — danh sách tìm theo tên / ID / mô tả / loại (gõ không dấu cũng được). Chọn dòng → phóng tới điểm
  trong bản vẽ. Chọn POINT trong bản vẽ → thẻ hiện tên, mô tả gốc, X/Y/Z, ID, nhóm gợi ý, hồ sơ liên kết, ảnh liên quan.
  Nút: phóng tới, xem ảnh, tạo hồ sơ, cập nhật nhãn.
* **C Ảnh TimeMark** — xem JPG ngay trong palette, trước/sau, trạng thái GPS, trạng thái ghép. Chọn ký hiệu ảnh trong bản
  vẽ → nhảy tới ảnh đó. Danh sách điểm RTK gần vị trí chụp kèm khoảng cách (chỉ để tham khảo). **Ghép ảnh vào hồ sơ chỉ
  khi bạn bấm xác nhận**; BHT không tự ghép theo khoảng cách, GPS ảnh không thay tọa độ RTK.
* **D Hồ sơ đối tượng** — xem / tạo / sửa hồ sơ (nhóm, mã hiệu, mô tả, số trụ, số mặt, tình trạng, phía đường, điểm, ảnh,
  lý trình nếu có). Tạo cọc tiêu từ POINT đang chọn: nhóm gợi ý dựa trên mô tả (có ghi căn cứ), bạn xác nhận, nhập số trụ
  / tình trạng / ghi chú → **Lưu**; **Chèn/Cập nhật ký hiệu** gọi BHTKYHIEU theo object_id. Điểm đã thuộc hồ sơ khác:
  mặc định **không** tạo mới; dùng chung điểm phải tích ô và xác nhận lần hai.
* **E Tuyến & báo cáo** — nút gọi các lệnh Lisp sẵn có. Kết quả được đọc lại từ bản vẽ sau khi lệnh chạy xong.

Palette **từ chối thao tác ghi khi đang có lệnh chạy** (báo "đang có lệnh …, hãy kết thúc lệnh"). Dữ liệu luôn nằm trong bản
vẽ (dictionary BHT_V02 / XData) — palette chỉ là giao diện; đóng palette không mất gì.

## 2. Quy trình làm việc (theo Palette `BTH` / `BHT`)

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
- **Ảnh nền IRT** (0.4.0): IRT chèn ảnh vệ tinh thành **lưới nhiều tile**, mỗi tile là một IMAGE riêng, thường nằm trên layer hiện hành (có thể là layer 0). BHT nhận một IMAGE là IRT khi:
  - đường dẫn file ảnh nằm trong thư mục bộ nhớ đệm của IRT: mẫu mặc định `*\IRT\*`, `IRT\*`, `*\IRT.CACHE\*`, `*\IRT_CACHE\*`; hoặc
  - tên layer khớp mẫu (mặc định `IRT*`, `*VE_TINH*`, `*SATELLITE*`, `*GOOGLE*`, `*TILE*`…); hoặc
  - tên file / tên ảnh khớp mẫu (mặc định `IRT*`, `*TILE*`, `*GOOGLE*`, `*BING*`…).
  - **Không bao giờ** coi là IRT: raster ảnh BHT (XData BHT, layer `BHT*`, file trong thư mục ảnh BHT).
  - Ba mẫu sửa được bằng `BHTTHUTUVE` > `C`, lưu trong bản vẽ. Ảnh không khớp được giữ nguyên thứ tự và được báo số lượng.
  - Tile trên layer đang khóa vẫn được sắp (chỉ đổi bảng thứ tự hiển thị); BHT không mở khóa layer.
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
- Kết quả kiểm thử của bản này nằm ở `TEST_REPORT_0.4.1.md`.
