# BHT 0.6.8 — Hướng dẫn sử dụng

BHT là bộ lệnh AutoLISP quản lý điểm khảo sát RTK, hồ sơ đối tượng (biển báo, cọc tiêu, cột Km…), ảnh TimeMark (KMZ), tuyến / lý trình và xuất thống kê.

- Lệnh chính: **`BTH`** hoặc **`BHT`** mở một Palette gắn bên trái AutoCAD.
- Bản 0.6.8 gồm `BHT-0.6.8.lsp`, `BHT.Palette.dll`, `BHT.Bridge.dll` và `BHT.Core.dll`, cùng thư mục `modules` chứa 12 module.
- Palette .NET là giao diện chính. Từ v0.5.5 đã bỏ bảng DCL dự phòng.
- Định dạng dữ liệu trong bản vẽ không đổi: bản vẽ từ 0.3.2 đến 0.5.5 mở bằng 0.6.0 mà không cần chuyển đổi.
- Mục tiêu hỗ trợ AutoCAD 2021–2024 và Civil 3D 2023 trên Windows.

## Phông chữ mặc định

Chữ CAD mặc định dùng `VNRomancUpdate.shx` với bảng mã **Unicode**. Phông được kiểm tra trên máy là SHX Unicode, có glyph riêng cho `Ê`, `ê`, `Ế`, `Ệ`; không chuyển TCVN3 cho phông này. Khi gõ trực tiếp vào TEXT có kiểu `BHT_TCVN`/`BHT_BIENBAO`, chọn Unicode trong bộ gõ. Tên kiểu `BHT_TCVN` được giữ để tương thích bản vẽ cũ. Kiểu tùy chỉnh dùng `vnromanc.shx` vẫn dùng TCVN3; Palette, CSV/Excel và hồ sơ luôn giữ Unicode. Xem `RELEASE_NOTES_0.5.2.md` để cập nhật nhãn cũ.

## 1. Cài đặt khuyến nghị

1. Đóng AutoCAD.
2. Giải nén gói `BHT-0.6.8.zip` và chạy `INSTALL_BHT.cmd`.
3. Mở AutoCAD, gõ `BTH` hoặc `BHT`.

AutoCAD tự nhận `BHT.bundle`; không cần `APPLOAD` hoặc `NETLOAD`. Nếu từng cài bản cũ bằng Startup Suite, hãy gỡ file Lisp cũ để tránh hai phiên bản cùng nạp.

## 1b. Cách di động bằng APPLOAD

1. Đặt `BHT-0.6.8.lsp` và ba DLL cùng thư mục `modules` trong một thư mục tin cậy đã có trên Support Path.
2. Kiểm tra **LISPSYS = 1**. Nếu phải đổi từ 0 sang 1, khởi động lại AutoCAD.
3. Gõ `APPLOAD`, chọn duy nhất `BHT-0.6.8.lsp`. Sau APPLOAD, gõ BHTLOAD để nạp giao diện khi cần.
4. Khi dòng lệnh báo `BHT 0.6.8 đã nạp thành công`, gõ `BTH` hoặc `BHT`.

Nếu Palette không nạp được, gõ `BHTLOAD` để thử lại và đọc lỗi tại dòng lệnh. Kiểm tra ba DLL nằm cạnh file Lisp hoặc cài lại bundle rồi mở lại AutoCAD. Các lệnh nghiệp vụ trực tiếp vẫn dùng được khi Lisp đã nạp.

**SECURELOAD / TRUSTEDPATHS:** nếu AutoCAD hỏi có nạp mã từ thư mục này hay không, chọn nạp hoặc thêm thư mục BHT vào Options → Files → Trusted Locations. Không cần đặt `SECURELOAD = 0`.

### Các thẻ của palette
Năm thẻ nằm dọc ở cạnh phải Palette, mỗi thẻ ghi tên ngang (từ 0.4.6-fix3), rê chuột lên thẻ để xem mô tả ngắn.

* **A Tổng quan** — số điểm RTK (dữ liệu đo) và số hồ sơ đối tượng (đơn vị quản lý) tách riêng; ảnh (đã ghép / chưa ghép,
  có / không GPS), tuyến, đoạn, cảnh báo kiểm tra.
* **B Điểm RTK** — danh sách tìm theo tên / ID / mô tả / loại (gõ không dấu cũng được). Chọn dòng → phóng tới điểm
  trong bản vẽ. Chọn POINT trong bản vẽ → thẻ hiện tên, mô tả gốc, X/Y/Z, ID, nhóm gợi ý, hồ sơ liên kết, ảnh liên quan.
  Nút: phóng tới, xem ảnh, tạo hồ sơ, cập nhật nhãn.
* **C Ảnh hiện trường** (ảnh TimeMark / KMZ) — xem JPG ngay trong palette, trước/sau, trạng thái GPS, trạng thái ghép. Bố cục luôn dành chỗ riêng
  cho danh sách, ảnh xem trước và thông tin; khi chưa có dữ liệu, dùng **Nhập KMZ** hoặc **Chỉ thư mục ảnh** ngay trên thẻ.
  Chọn ký hiệu ảnh trong bản vẽ → nhảy tới ảnh đó. Danh sách điểm RTK gần vị trí chụp kèm khoảng cách (chỉ để tham khảo). **Ghép ảnh vào hồ sơ chỉ
  khi bạn bấm xác nhận**; BHT không tự ghép theo khoảng cách, GPS ảnh không thay tọa độ RTK.
* **D Hồ sơ đối tượng** — xem / tạo / sửa hồ sơ (nhóm, mã hiệu, mô tả, số trụ, số mặt, tình trạng, phía đường, điểm, ảnh,
  lý trình). Có thể ghi lý trình tay, xóa hoặc tính lại theo tuyến; danh sách ảnh dẫn thẳng sang thẻ Ảnh. Tạo cọc tiêu từ POINT đang chọn: nhóm gợi ý dựa trên mô tả (có ghi căn cứ), bạn xác nhận, nhập số trụ
  / tình trạng / ghi chú → **Lưu**; **Chèn/Cập nhật ký hiệu** gọi BHTKYHIEU theo object_id. Điểm đã thuộc hồ sơ khác:
  mặc định **không** tạo mới; dùng chung điểm phải tích ô và xác nhận lần hai.
* **E Tuyến & báo cáo** — sáu thao tác chính: lấy/cập nhật tim TDT 9.1, thêm mốc Km, tính lý trình/phía, sắp nhãn,
  xuất báo cáo biển báo Excel và kiểm tra dữ liệu. Các lệnh ít dùng nằm trong **Công cụ nâng cao**. Báo cáo dài mở trong
  hộp thoại riêng để đọc và sao chép.

Palette **từ chối thao tác ghi khi đang có lệnh chạy** (báo "đang có lệnh …, hãy kết thúc lệnh"). Dữ liệu luôn nằm trong bản
vẽ (dictionary BHT_V02 / XData) — palette chỉ là giao diện; đóng palette không mất gì.

## 2. Quy trình làm việc (theo Palette `BTH` / `BHT`)

| Bước | Việc | Lệnh chính |
|---|---|---|
| 1 | Nhập điểm RTK | **`BHTNHAP`** (CSV trực tiếp: tên, Bắc, Đông, Z, mô tả; không tiêu đề) = cách **mặc định**. `BHTNHAPTSV` chỉ dùng cho file TSV trao đổi / chuẩn hóa; **không cần** nhập lại cùng dữ liệu bằng cả hai |
| 2 | Kiểu điểm và nhãn | **`BHTKIEUDIEM`**, `BHTNHANDIEM`, `BHTANNHAN`, **`BHTSAPNHAN`**, **`BHTNHANTUDONG`** |
| 3 | Nhập TimeMark | `BHTKMZ`, `BHTANHNAP`, `BHTHETOADO` |
| 4 | Kiểm tra và xem ảnh | `BHTDONGBOANH`, `BHTXEMANH`, `BHTANH`, `BHTTHUMUCANH`, `BHTCHENANH`, `BHTNHANANH` |
| 5 | Ghép ảnh (chỉ đề xuất, người dùng duyệt) | `BHTGHEPANH`, `BHTXACNHANANH`, `BHTGANANH`, `BHTBOANH` |
| 6 | Hồ sơ đối tượng | `BHTDOITUONG`, `BHTSUADT`, `BHTXOADT`, `BHTTHEMDIEM`, `BHTBOTDIEM`, `BHTINFO` |
| 7 | Ký hiệu, block và thứ tự hiển thị | `BHTKYHIEU`, **`BHTBLOCK`**, **`BHTBBDANHMUC`**, **`BHTTHUTUVE`** |
| 8 | Tuyến, Km, gói thầu | `BHTTUYENTDT` (tim TDT 9.1), `BHTTUYEN` (Polyline thường), `BHTMOCKM`, `BHTDSMOC`, `BHTLYTRINH`, `BHTGOITHAU`, `BHTPHANDOAN`, `BHTGANDOAN` |
| 9 | Xuất thống kê | **Xuất báo cáo biển báo Excel** trên Palette, `BHTXUAT` (CSV), `BHTKT`, `BHTTRANGTHAI` |
| Khác | Chẩn đoán | `BHTDIAG`, `BHTTEST`, `BHTHELP` |

## Thông báo lỗi và cảnh báo (từ 0.4.6-fix3)

- Lỗi / cảnh báo cần bạn xử lý hiện cửa sổ **BHT** (biểu tượng lỗi hoặc cảnh báo) và vẫn in ở dòng lệnh, ví dụ `BHT lỗi: …`,
  “chưa có tuyến. Dùng BHTTUYEN trước.”, tim TDT dạng proxy, không mở/không ghi được file.
- Nhấn Esc (hủy lệnh) chỉ in “lệnh bị hủy” ở dòng lệnh, không hiện cửa sổ. Thông tin thường cũng chỉ in dòng lệnh.
- Muốn tắt cửa sổ trong phiên làm việc: gõ `(setq *bht-popup* nil)`; bật lại: `(setq *bht-popup* T)`.
- Khi chạy script `.scr` hoặc AutoCAD Core Console, BHT không hiện cửa sổ để công việc tự động không bị dừng.
- Lệnh gửi từ Palette mà báo lỗi: vùng trạng thái hiện “Lệnh … THẤT BẠI.” trên nền đỏ nhạt.

## 3. Thay đổi trong 0.4.6

- Palette dùng nền tối, chữ thao tác vàng và thanh chọn năm thẻ dọc ở cạnh phải.
- Bản vẽ mới dùng kiểu `BHT_RTK` gọn; bản vẽ cũ giữ nguyên kiểu chữ và vị trí nhãn.
- Cơ chế điểm được đối chiếu với TDT 9.1 và DPSurvey; dấu X vẫn 1 unit và dữ liệu RTK không đổi.

- BHT nhận đúng TDTSolution 9.1 bản thường tại `C:\Program Files (x86)\TDT Solution 2022\`. Bản TDT 9.1 Pro không được dùng.
- Trường **Mã hiệu** của hồ sơ biển báo là ô gợi ý có thể nhập. Danh mục hiện `Mã — Tên biển` từ 412 mã của TDT; chọn mã có vector để BHT clone block nguồn TDT vào DWG.
- Block nguồn TDT được bọc trong định nghĩa `BHT_TDT_<MA>` với scale mặt biển `0.2` và cột cao `0.6` đơn vị. BHT chỉ đọc thư viện cài đặt và tạo cache trong LocalAppData; không sửa thư mục TDT và không đóng gói tài sản TDT vào release.
- Biển báo tự đặt ra ngoài tim theo phía tuyến, xoay theo hướng tuyến, có leader nối về điểm RTK. Nhãn hiện mã biển và lý trình; ID hồ sơ chỉ nằm trong XData.
- Nút **Xuất báo cáo biển báo Excel** tạo `.xlsx` Unicode gồm sheet tổng hợp và danh sách chi tiết. Báo cáo có STT, công trình, đoạn/gói, loại và tên biển, phía, lý trình, tình trạng, số trụ/mặt, trạng thái kiểm tra, ghi chú và ID hồ sơ.
- Báo cáo kiểm tra/trạng thái mở trong hộp thoại lớn; vùng thông báo dưới Palette chỉ hiển thị trạng thái ngắn và không nhận con trỏ nhập.
- Toàn bộ block dự phòng vẫn nằm trong `BHT-0.6.8.lsp`; không nạp thêm `BHT-BIENBAO.lsp`. `BHTBLOCK` tiếp tục nhận DWG tùy chọn khi cần mẫu riêng.

### Lấy tim từ TDTSolution 9.1 bằng `BHTTUYENTDT`

1. Mở AutoCAD bằng profile TDTSolution 9.1 bản thường và chờ TDT nạp xong.
2. Mở bản vẽ có tim TDT, gõ `BHTTUYENTDT`, rồi chọn đúng đối tượng tim.
3. `Tdt91Interop` mở đối tượng nguồn ở chế độ `ForRead`, gọi `Entity.Explode` và tạo một Polyline riêng trên layer `BHT_TUYEN_TDT`.
4. BHT lưu handle/class nguồn để lần chạy sau cập nhật đúng Polyline tham chiếu. Tính lý trình và phía đường diễn ra trên Polyline BHT này.

`BHTTUYENTDT` từ chối tim đang là proxy (từ 0.4.6-fix3 thông báo nêu rõ: phiên AutoCAD chưa nạp TDTSolution 9.1 — lưu, đóng AutoCAD, mở lại bằng biểu tượng/profile TDTSolution 9.1, cắm khóa USB TDT nếu cần, rồi chạy lại). Không dùng `BHTTUYENTDT` trong AutoCAD chưa nạp TDT, và không dùng `vlax-curve-*` trực tiếp trên `TDTDBALIGNMENT`. Nếu TDT chưa sẵn sàng, dùng `BHTTUYEN` với một Polyline tham chiếu đã được kiểm tra.

### Các chức năng kế thừa từ 0.4.3

- Palette dùng bảng màu xanh dễ đọc, mở mặc định bên trái rộng 430 px và không còn hàng gợi ý rời bị cắt chữ.
- Kết quả của các lệnh Lisp được đưa vào vùng **Thông báo** nhiều dòng ở cuối Palette.
- CSV xuất ra dùng UTF-8 BOM và tiêu đề tiếng Việt có dấu.
- Nhãn ký hiệu dùng tên nghiệp vụ, ví dụ `Cọc tiêu Km 48+500`; ID nội bộ chỉ còn trong dữ liệu XData.
- Block mặc định của **Cọc tiêu** và **Cột Km** được vẽ lại theo mẫu hiện trường. Biển báo giữ nguyên để chờ mẫu.
- Bộ cài từ chối chạy khi còn AutoCAD đang mở, tránh DLL cũ và Lisp mới chạy lẫn phiên bản.

### Các chức năng kế thừa từ 0.4.2

### Điểm RTK và bố trí nhãn

- Bản vẽ mới dùng kiểu `BHT_RTK` (Arial Unicode, hệ số rộng 0,85) từ lần nhập RTK đầu tiên để cụm chữ gọn hơn. Bản vẽ cũ tiếp tục dùng kiểu đã lưu; phần mềm không tự đổi font hoặc dời nhãn legacy.
- Tên, mô tả và cao độ được xem là một cụm: BHT chọn vị trí cho cả cụm và giữ các dòng thẳng hàng. Khoảng dòng mặc định 1,5 lần chiều cao chữ.

- Khi nạp BHT, POINT hiển thị mặc định bằng dấu X (`PDMODE=3`) kích thước tuyệt đối 1 đơn vị bản vẽ (`PDSIZE=1`). Tâm dấu X chính là tọa độ POINT; BHT không dời điểm.
- `BHTKIEUDIEM` cho nhập kích thước dấu X và chọn sắp lại toàn bộ nhãn. Nút **Đặt dấu X (cỡ 1) + sắp lại nhãn** trong thẻ Điểm RTK áp dụng nhanh kích thước 1 đơn vị bản vẽ và sắp lại toàn bộ nhãn (tên cũ: “Dấu X 1u + sắp nhãn”).
- BHT thử 64 vị trí quanh mỗi điểm (8 hướng × 8 khoảng cách), tránh dấu X, nhãn điểm, ký hiệu đối tượng, ký hiệu ảnh và chữ khác của BHT.

### Ảnh và lý trình trong Palette

- Thẻ **Ảnh** không còn dùng các vùng Dock chồng nhau. Khi danh sách rỗng, thẻ nêu rõ cần nhập KMZ hoặc chỉ lại thư mục ảnh.
- Trong thẻ **Hồ sơ**, ô **Lý trình tay** chấp nhận `Km39+050.50`, `39+050,50` hoặc tổng số mét `39050.5`. Nút **Ghi tay** lưu `ly_trinh_m`, `ly_trinh_km` và trạng thái `NHAP_TAY`; **Xóa** đưa về `CHUA_TINH`; **Tính tuyến** gọi quy trình `BHTLYTRINH`.
- Trường Ảnh của hồ sơ luôn có thông báo khi chưa gắn ảnh; nút **Xem ở tab Ảnh** chuyển sang quy trình chọn và xác nhận gắn.

### Block ký hiệu tùy chọn

`BHTBLOCK` hoặc nút **Thư viện block** mở danh mục chuẩn và cho nạp một tệp DWG riêng cho từng nhóm đối tượng.

1. Với biển báo chuẩn, nhập mã QCVN trong hồ sơ rồi chạy `BHTKYHIEU`; BHT tự chọn block tương ứng.
2. Với mẫu riêng, chuẩn bị một DWG chỉ chứa hình ký hiệu; đặt `INSBASE` tại đúng tâm chèn, chạy `BHTBLOCK`, chọn nhóm, chọn `N` và chỉ tới tệp DWG.
3. Chạy `BHTKYHIEU` để tạo/cập nhật ký hiệu. BHT giữ hình học nguồn và tự áp dụng hệ số đơn vị của DWG.
4. Chọn `M` trong `BHTBLOCK` để nhóm đó trở lại ký hiệu mặc định; chọn `X` để xem cấu hình hiện tại.

Mỗi nhóm dùng một định nghĩa `BHT_USER_<NHOM>` được lưu trong DWG hiện hành. Tệp nguồn không bị sửa. Nhãn phía trên block dùng tên nghiệp vụ và mã hiệu/lý trình, ví dụ `Cọc tiêu Km 48+500`; ID hồ sơ được giữ trong XData để tra cứu nhưng không in lên bản vẽ.

## 4. Lệnh mới / thay đổi từ 0.3.3

### Nhãn điểm RTK: bố trí tự động, sắp xếp lại, dời tay

**`BHTNHANDIEM`** (bí danh `BHTNHANDIEM`). Các lựa chọn:

- `1` Tên · `2` Tên + mô tả · `3` Tên + mô tả + cao độ (mặc định).
- `4` Bật / tắt **ưu tiên hồ sơ**: điểm đã thuộc hồ sơ đối tượng chỉ còn nhãn tên, bớt rối ở chỗ có ký hiệu. Nhãn phụ được gỡ; tắt chế độ thì tạo lại. Dữ liệu điểm không đổi.
- `I` Bật / tắt dòng ID nội bộ.
- `S` Sắp xếp lại (như `BHTSAPNHAN`).
- `R` Trả nhãn về tự động (như `BHTNHANTUDONG`).
- `A` Ẩn · `H` Hiện · `C` Cài đặt (cao chữ, khoảng lệch, kiểu chữ) · `X` Xóa mọi nhãn BHT.

Nhãn mới được **bố trí tự động** để tránh chồng lấn:

- BHT thử 8 hướng quanh điểm, mỗi hướng 8 khoảng cách.
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

## 5. Các chức năng trình bày

### Nhãn điểm: layer, kiểu chữ, nội dung

- Layer: `BHT_RTK_TEN`, `BHT_RTK_MOTA`, `BHT_RTK_CAO_DO`, `BHT_RTK_ID`. Kiểu chữ: `BHT_ARIAL` (arial.ttf).
- Nội dung lấy **nguyên văn** từ CSV gốc; cao độ ghi `H = <Z gốc>`, không làm tròn; mô tả rỗng thì không có dòng mô tả.
- Mỗi nhãn gắn với ID điểm qua XData `BHT_NHAN`; chạy lại không nhân đôi; chỉ sửa / xóa TEXT có XData `BHT_NHAN`.
- Sau khi nhập CSV, chương trình hỏi có tạo / cập nhật nhãn ngay không.

### `BHTANNHAN`

Ẩn hoặc hiện toàn bộ nhãn điểm RTK. Lệnh chỉ bật / tắt layer, không xóa gì.

### `BHTDONGBOANH` (bí danh `BHTDONGBOANH`) — đồng bộ ký hiệu ảnh

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

## 6. Nguyên tắc dữ liệu (không đổi)

- CAD X = Easting (Đông), Y = Northing (Bắc), Z = cao độ. Không làm tròn và không sửa dữ liệu khảo sát. BHT không bao giờ thay đổi tọa độ POINT.
- Một điểm RTK không phải một biển. Một đối tượng có thể gồm nhiều điểm và nhiều ảnh; một trụ có thể có nhiều mặt biển.
- GPS ảnh là vị trí **chụp**, không ghi đè RTK. Ghép ảnh tự động chỉ là đề xuất.
- Không đọc hình học proxy `TDTDBALIGNMENT` bằng `vlax-curve-*`. `BHTTUYENTDT` chỉ chạy khi TDTSolution 9.1 bản thường đã nạp; `Tdt91Interop` dùng `Entity.Explode` trên đối tượng mở `ForRead`, sau đó BHT chỉ tính trên Polyline riêng `BHT_TUYEN_TDT` và mốc Km đã xác nhận.
- Hệ tọa độ ảnh mặc định là VN-2000 múi 3°, KTT 105°45', k = 0.9999. **Hệ này chưa được xác nhận chính thức**; kiểm tra bằng `BHTHETOADO`.

## 7. Lưu ý

- Luôn làm việc trên **bản sao** bản vẽ.
- Ảnh GPS 0,0 (`BOT19-P-000204`, `-000205` trong KMZ mẫu) được giữ nhưng không có ký hiệu. Ghép thủ công bằng `BHTGANANH` hoặc `BHTXEMANH` > `G`.
- Kết quả kiểm thử của bản này nằm ở `TEST_REPORT_0.4.6.md`.
- Các giới hạn đã biết nằm ở `KNOWN_ISSUES_0.4.6.md`; checklist Palette/DCL nằm ở `CHECKLIST_NGHIEM_THU_0.4.6.md`.

Chèn biển tự do: lưu hồ sơ Biển báo có điểm RTK, bấm **Chèn biển tự do** (hoặc `BHTBIENTUDO`), chọn hướng → điểm trung gian (`Xoa` để bỏ điểm cuối; `Dat`/Enter để kết thúc) → vị trí đặt biển. BHT lưu đường dẫn gấp khúc và hướng; cập nhật ký hiệu vẫn giữ bố trí này. `BHTKYHIEU` > `R` trả về tự động theo tuyến. Xem `docs/RELEASE_NOTES_0.5.3.md`.


### Tô màu báo hiệu — v0.6.1

Trong **Hồ sơ đối tượng** hoặc **Thư viện block**, bật/tắt **Tô màu báo hiệu (Hatch)**. Bấm **Chọn biển** để nhận lựa chọn từ thư viện, **Lưu**, rồi **Chèn/Cập nhật ký hiệu** để áp dụng lên CAD. Đóng thư viện không ghi thay đổi. Hồ sơ cũ mặc định tô màu.

Tắt tô màu ẩn Hatch và Solid trong bản sao block riêng, tạo đường bao để giữ hình; không sửa block gốc hay FILLMODE toàn bản vẽ. Màu đường nét vẫn giữ theo nguồn. Ảnh thumbnail giữ màu minh họa gốc. Block tùy chỉnh cũng được sao riêng. Khi sửa hình block gốc sau khi đã tạo biến thể, cần chọn một block có tên mới để tạo lại biến thể.


### BHT v0.6.2 — Đặt biển và nhãn

- Layer ký hiệu mới dùng ACI 7 (trắng trên nền CAD tối). Khi đồng bộ, màu đỏ mặc định cũ của BHT_KYHIEU đổi thành trắng; màu tùy chỉnh khác được giữ. Biển không tô màu dùng ByBlock nên nét theo màu layer/INSERT; biển có tô màu giữ màu mặt biển.
- Nhãn mặc định 0.35 đơn vị CAD. Điền **Cỡ nhãn CAD** trong hồ sơ → **Lưu** → **Chèn/Cập nhật ký hiệu**. Chỉ nhãn BHT thay đổi; dữ liệu/nhãn khảo sát ngoài BHT không bị sửa. Giá trị mặc định cũ 1.5 được thay bằng 0.35, muốn dùng 1.5 hãy nhập riêng trong hồ sơ.
- Trong **Đặt tự do**, chọn **Gấp khúc tự động** hoặc **Đường dẫn thẳng**. Chọn **Hướng biển**: ngang 0° (WCS), theo tuyến, chọn trên CAD, hoặc nhập góc WCS theo độ. Bấm **Chèn biển tự do**, chọn một vị trí. Nếu chọn hướng trên CAD thì chọn hướng sau vị trí. Enter/Esc hủy trước khi hoàn tất sẽ giữ hồ sơ.
- **Chọn điểm trung gian** giữ luồng nâng cao: chọn hướng → điểm trung gian → Dat → vị trí. Lúc đó ô hướng trên Palette bị vô hiệu hóa, hướng chọn trực tiếp trên CAD.
- Các ô lựa chọn không đổi giá trị khi cuộn con lăn; dùng nhấp chọn/bàn phím. Trong lúc BHT chạy thao tác, bấm lặp được bỏ qua với thông báo chờ.
- Đóng và mở lại AutoCAD sau cài đặt để nạp đúng DLL/Lisp v0.6.2.

## Thao tác từ v0.6.3

Gõ BTH hoặc BHT để mở bảng. Đóng bảng sẽ ngắt timer và theo dõi thay đổi; khi chuyển bản vẽ bảng đóng, gọi lại lệnh để mở cho bản vẽ đó. Cài bundle không cần NETLOAD; dùng APPLOAD di động thì gọi BHTLOAD rồi BTH.

Ô Tô màu biển nằm cạnh Chèn biển tự do. Đây là lựa chọn cho cả bản vẽ: bật có Hatch, tắt dùng biến thể đường nét cho tất cả biển BHT đã chèn và biển chèn tiếp theo. Không thay Hatch của đối tượng CAD ngoài BHT. Lựa chọn được lưu trong DWG.

Nhãn tự căn giữa dưới khung block và quay cùng biển; không cần nhập cỡ nhãn riêng. Cỡ chữ bằng 15% chiều cao toàn block (bao gồm trụ), khoảng cách dưới bằng 8%. Đây là tỷ lệ BHT hiện tại, chưa xác nhận trị số mặc định TDT trực tiếp.

Cho phép dùng chung điểm RTK chỉ áp dụng khi tạo hồ sơ mới: cho phép một điểm đã thuộc hồ sơ khác được dùng thêm, ví dụ biển và cọc tiêu cùng vị trí. BHT vẫn hỏi xác nhận; không ghi đè hồ sơ cũ. Để chuột trên ô này để xem gợi ý phân nhóm và giải thích; tiêu đề hồ sơ chỉ hiển thị số điểm.