# BHT 0.6.53 — Hướng dẫn sử dụng

BHT là bộ lệnh AutoLISP quản lý điểm khảo sát RTK, hồ sơ đối tượng (biển báo, cọc tiêu, cột Km…), ảnh TimeMark (KMZ), tuyến / lý trình và xuất thống kê.

- Lệnh chính: **`BTH`** hoặc **`BHT`** mở một Palette gắn bên trái AutoCAD.
- Bản 0.6.53 gồm `BHT-0.6.53.lsp`, `BHT.Palette.dll`, `BHT.Bridge.dll` và `BHT.Core.dll`, cùng thư mục `modules` chứa 12 module.
- Palette .NET là giao diện chính. Từ v0.5.5 đã bỏ bảng DCL dự phòng.
- Định dạng dữ liệu trong bản vẽ không đổi: bản vẽ từ 0.3.2 đến 0.5.5 mở bằng 0.6.0 mà không cần chuyển đổi.
- Mục tiêu hỗ trợ AutoCAD 2021–2024 và Civil 3D 2023 trên Windows.

## Phông chữ mặc định

Chữ CAD mặc định dùng `VNRomancUpdate.shx` với bảng mã **Unicode**. Phông được kiểm tra trên máy là SHX Unicode, có glyph riêng cho `Ê`, `ê`, `Ế`, `Ệ`; không chuyển TCVN3 cho phông này. Khi gõ trực tiếp vào TEXT có kiểu `BHT_TCVN`/`BHT_BIENBAO`, chọn Unicode trong bộ gõ. Tên kiểu `BHT_TCVN` được giữ để tương thích bản vẽ cũ. Kiểu tùy chỉnh dùng `vnromanc.shx` vẫn dùng TCVN3; Palette, CSV/Excel và hồ sơ luôn giữ Unicode. Xem `RELEASE_NOTES_0.5.2.md` để cập nhật nhãn cũ.

## Luồng hồ sơ từ bản 0.6.15

1. Ở Điểm RTK, chọn điểm rồi bấm Tạo hồ sơ từ điểm; hoặc ở Hồ sơ đối tượng, bấm Tạo từ RTK để chọn trên CAD.
2. Kiểm tra nhóm, mô tả, tình trạng và phía đường. Với biển báo, bấm Chọn biển để chọn mã/các mặt và nội dung biển.
3. Bấm Lưu hồ sơ để ghi dữ liệu. Lý trình nhập tay trong ô Lý trình cũng được ghi; cọc Km/H hợp lệ vẫn tự suy ra lý trình.
4. Bấm Chèn / cập nhật ký hiệu để áp dụng dữ liệu lên CAD, hoặc Đặt ký hiệu để chọn cách đặt và vị trí.

Ô Tìm lọc theo ID, nhóm, mã biển, mô tả và tình trạng, hỗ trợ gõ không dấu. Kéo thanh phân cách ngang để tăng vùng danh sách hoặc vùng nhập.

Nhấp một lần trên dòng để mở/sửa hồ sơ, nhấp đúp để thu phóng tới vị trí RTK của hồ sơ đó. Đã bỏ nút Thu phóng ở dưới form. Nhấp đúp không lưu nội dung đang sửa; nếu chuyển hồ sơ khác, xác nhận bỏ thay đổi vẫn hoạt động như khi chọn một lần.

Khi đặt ký hiệu trên CAD, gõ **G** (Gốc) để đặt tại tâm X gốc hoặc **T** (Tuỳ chọn) rồi bấm vị trí mong muốn; vẫn có thể bấm vị trí trực tiếp. Phím G/T dùng được cả lúc chọn điểm trung gian và vị trí cuối. G bỏ các điểm trung gian/đường dẫn cũ, giữ hướng ký hiệu đã chọn. Nếu chọn hướng trên CAD, cần chọn hướng sau vị trí. Với hồ sơ nhiều điểm, tâm gốc là vị trí trung bình của các điểm RTK hợp lệ. Enter ở bước vị trí cuối hoặc Esc hủy thao tác; điểm RTK không bị di chuyển.

Trạng thái Chưa lưu thay đổi giúp nhận biết dữ liệu còn trong vùng nhập. Làm mới/lọc danh sách giữ nội dung đang sửa; chuyển sang hồ sơ khác sẽ hỏi trước khi bỏ thay đổi. Khi đổi bản vẽ rồi quay lại trong cùng phiên AutoCAD, bản nháp được khôi phục theo đúng bản vẽ. Bản nháp nằm trong bộ nhớ, không thay cho việc bấm Lưu hồ sơ trước khi đóng bản vẽ/AutoCAD.

**Tô nền tất cả biển** áp dụng cho toàn bộ biển BHT trong bản vẽ. Từ 0.6.33, tắt lựa chọn này chỉ bỏ nền màu, giữ đầy đủ viền và hatch của biểu tượng. Ví dụ W.207a vẫn có viền tam giác, mũi tên và đường nhánh tô đậm; R.415 vẫn giữ hình xe và vạch phân làn. Các vùng rỗng bên trong hình được giữ trắng để rõ khi in. Nét khung dùng 0,25 mm; bật in lineweight trong thiết lập Plot để thể hiện đúng.

Khi bật/tắt **Tô nền tất cả biển**, checkbox tạm khóa trong lúc AutoCAD xử lý. Làm mới/lọc hồ sơ không đổi lựa chọn đang chờ. Khi xong, checkbox đọc lại trạng thái đã lưu trong bản vẽ. Nếu AutoCAD đang chạy lệnh khác, kết thúc lệnh bằng Esc rồi thử lại; vùng trạng thái báo rõ nếu thao tác chưa thực hiện hoặc thất bại.

## 1. Cài đặt khuyến nghị

1. Đóng AutoCAD.
2. Giải nén gói `BHT-0.6.53.zip` và chạy `INSTALL_BHT.cmd`.
3. Mở AutoCAD, gõ `BTH` hoặc `BHT`.

AutoCAD tự nhận `BHT.bundle`; không cần `APPLOAD` hoặc `NETLOAD`. Nếu từng cài bản cũ bằng Startup Suite, hãy gỡ file Lisp cũ để tránh hai phiên bản cùng nạp.

## 1b. Cách di động bằng APPLOAD

1. Đặt `BHT-0.6.53.lsp` và ba DLL cùng thư mục `modules` trong một thư mục tin cậy đã có trên Support Path.
2. Kiểm tra **LISPSYS = 1**. Nếu phải đổi từ 0 sang 1, khởi động lại AutoCAD.
3. Gõ `APPLOAD`, chọn duy nhất `BHT-0.6.53.lsp`. Sau APPLOAD, gõ BHTLOAD để nạp giao diện khi cần.
4. Khi dòng lệnh báo `BHT 0.6.53 đã nạp thành công`, gõ `BTH` hoặc `BHT`.

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
  / tình trạng / ghi chú → **Lưu hồ sơ**; **Chèn / cập nhật ký hiệu** gọi BHTKYHIEU theo object_id. Điểm đã thuộc hồ sơ khác:
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
- Trường **Mã hiệu** của hồ sơ biển báo là ô gợi ý có thể nhập. Danh mục hiện `Mã — Tên biển` từ 467 mẫu BHT; chọn mã để BHT clone mặt biển CAD gốc vào DWG. Hai mã cũ R.415/W.239 quy về biến thể a.
- Block BHT được bọc trong `BHT_ADS_V0631_<MA>`, mặt biển cao 1,8 và trụ cao 0,6 đơn vị. Bộ cài kèm bản sao thư viện BHT cục bộ, giữ tài nguyên cài đặt gốc. Ảnh chọn biển là mẫu thư viện; thông số nhập được áp dụng vào CAD. Thư viện TDT vẫn là nguồn dự phòng.
- Biển báo tự đặt ra ngoài tim theo phía tuyến, xoay theo hướng tuyến, có leader nối về điểm RTK. Nhãn hiện mã biển và lý trình; ID hồ sơ chỉ nằm trong XData.
- Nút **Xuất báo cáo biển báo Excel** tạo `.xlsx` Unicode gồm sheet tổng hợp và danh sách chi tiết. Báo cáo có STT, công trình, đoạn/gói, loại và tên biển, phía, lý trình, tình trạng, số trụ/mặt, trạng thái kiểm tra, ghi chú và ID hồ sơ.
- Báo cáo kiểm tra/trạng thái mở trong hộp thoại lớn; vùng thông báo dưới Palette chỉ hiển thị trạng thái ngắn và không nhận con trỏ nhập.
- Toàn bộ block dự phòng vẫn nằm trong `BHT-0.6.53.lsp`; không nạp thêm `BHT-BIENBAO.lsp`. `BHTBLOCK` tiếp tục nhận DWG tùy chọn khi cần mẫu riêng.

### Biển hoặc bảng có hai trụ/chân

Đặt **Số trụ/chân = 2**, rồi gắn **hai điểm RTK đã đo ở hai chân** vào cùng hồ sơ. Nếu hồ sơ chỉ có một điểm như ảnh phản hồi, bấm **Thêm điểm CAD…** để chọn điểm chân còn lại. Bấm **Lưu hồ sơ**, rồi **Chèn / cập nhật** hoặc **Đặt ký hiệu…**. Hai điểm khảo sát có hai đường nối riêng vào hai dấu chân của ký hiệu; không nối từ điểm trung bình. Điểm RTK giữ tọa độ đo gốc.

Khi đặt lại, xoay hoặc đổi tỷ lệ biển, các đầu đường nối bám theo chân ký hiệu. Thêm/gỡ điểm cập nhật đường tương ứng, không tạo đường trùng khi cập nhật lặp. Nếu dùng đường gấp khúc, mỗi đường đi qua các góc đã chọn. Chân ký hiệu là vị trí trình bày, không phải POINT khảo sát được tạo thêm.

Nếu số điểm gắn chưa đủ số chân, hồ sơ hiện **Thiếu … điểm chân RTK** cạnh vùng chọn điểm; **BHTKT** cũng cảnh báo. Vẫn lưu được hồ sơ khảo sát chưa đủ điểm; phần mềm chỉ nối các điểm thực đã gắn. **Một trụ mang hai mặt biển** dùng Số trụ `1`, Số mặt `2`; số mặt không làm tăng số chân. Ký hiệu mặc định nhận số trụ từ `0` đến `100`; để trống dùng hình một trụ như trước. Block tùy chỉnh giữ hình đã chọn và dùng các dấu chân có sẵn nếu nhận diện được, hoặc nối vào điểm chèn.

![Hai điểm RTK nối vào hai chân ký hiệu](HAI_CHAN_BIEN_0.6.25.png)

### Tỷ lệ biển báo và nhãn

Trong thẻ **Hồ sơ đối tượng**, bấm **Tỷ lệ biển / nhãn…**. Chọn mức có sẵn hoặc nhập riêng **Tỷ lệ hình biển** và **Tỷ lệ nhãn mã biển**, rồi bấm **Áp dụng**. Giá trị từ `0,01` đến `100`, tối đa 3 chữ số thập phân; nhận dấu phẩy hoặc dấu chấm. Mức `1` là kích thước chuẩn, `2` là gấp đôi. Đây là hệ số kích thước trong CAD. Ví dụ hình biển `2`, nhãn `1` làm biển lớn gấp đôi và giữ nhãn ở cỡ chuẩn. **Về chuẩn 1:1** đưa cả hai ô về `1`; bấm **Áp dụng** để ghi, hoặc **Hủy** để đóng.

Thiết lập áp dụng cho tất cả hồ sơ thuộc nhóm **Biển báo** trong bản vẽ: cập nhật ký hiệu đã chèn, dùng cho biển chèn sau. Biển giữ vị trí, góc và đường dẫn; dữ liệu RTK và các nhóm khác giữ nguyên. Nhãn của mọi mặt biển dùng cùng tỷ lệ nhãn. Khi mở bản vẽ cũ chưa có thiết lập này, BHT giữ cách tính kích thước cũ đến khi bạn áp dụng.

Thanh nút có ba hàng: **Tạo từ RTK / Lưu hồ sơ**, **Chọn biển / Tỷ lệ biển, nhãn**, **Đặt ký hiệu / Chèn, cập nhật**. **Đặt ký hiệu** chọn vị trí và hướng trên CAD; **Chèn / cập nhật** dùng vị trí đã lưu. Hai thao tác này lưu thay đổi hồ sơ trước khi xử lý ký hiệu. **Lưu hồ sơ** chỉ ghi thông tin. **Thêm điểm CAD / Gỡ điểm chọn** nằm cạnh danh sách điểm RTK trong vùng nhập.

### Nét biển và nhãn từng mặt

Từ 0.6.20, R.415a/b và ký hiệu điện W.239a dùng nét đã sửa. Khi tắt **Tô nền tất cả biển**, đường nét và số trong biển kế thừa màu của ký hiệu, mặc định màu trắng trên nền CAD tối. Khi bật tô màu, biển tốc độ giữ số đen trên nền trắng.

Mỗi mặt trên cùng trụ có một nhãn mã riêng, xếp thành các dòng phía dưới ký hiệu theo thứ tự mặt trong hồ sơ. Ví dụ cụm `W.239a; S.509a@4.75` hiển thị hai nhãn `W.239a` và `S.509a (4.75 m)`. Khi bỏ mặt phụ rồi cập nhật ký hiệu, nhãn tương ứng cũng được dọn.

Sau khi cập nhật bộ cài, mở hồ sơ và bấm **Chèn / cập nhật ký hiệu** để thay mẫu/nhãn đã chèn bằng bản mới. Danh sách giữ vị trí cuộn khi làm mới sau chỉnh sửa; thư viện biển trả về đúng vùng nhập đang xem.

### Trọng lượng trên biển phụ S.505a

Chọn **S.505a — Loại xe** trong thư viện biển, nhập **Trọng lượng (tấn)**: `8` để hiện **8T**, hoặc `8,5` để hiện **8.5T** dưới hình xe. Để trống nếu biển thực tế chỉ có hình xe.

Nếu ghép nhiều mặt trên cùng trụ, chọn biển chính, sau đó chọn S.505a, nhập trọng lượng và bấm **Thêm mặt**. Bấm **Chọn biển**, lưu hồ sơ rồi chèn/cập nhật ký hiệu. Nhấp đúp S.505a đưa con trỏ vào ô trọng lượng để nhập trước khi thêm mặt. Giá trị được lưu riêng trong mã từng mặt, ví dụ `S.505a@8`.

Trọng lượng phải lớn hơn 0, tối đa 100000 tấn và có tối đa 3 chữ số thập phân. Nhập số, không nhập chữ T. Mẫu mới lấy hình xe từ BHT, thêm trọng lượng trong khung BHT nền trắng, viền và chữ đen. Bộ cài đã kèm mẫu CAD S.505a. Mẫu TDT tiếp tục dùng được khi chọn nguồn dự phòng.

### Lấy tim từ TDTSolution 9.1 bằng `BHTTUYENTDT`

1. Mở AutoCAD bằng profile TDTSolution 9.1 bản thường và chờ TDT nạp xong.
2. Mở bản vẽ có tim TDT, gõ `BHTTUYENTDT`, rồi chọn đúng đối tượng tim.
3. `Tdt91Interop` mở đối tượng nguồn ở chế độ `ForRead`, gọi `Entity.Explode` và tạo một Polyline riêng trên layer `BHT_TUYEN_TDT`.
4. BHT lưu handle/class nguồn để lần chạy sau cập nhật đúng Polyline tham chiếu. Tính lý trình và phía đường diễn ra trên Polyline BHT này.

`BHTTUYENTDT` từ chối tim đang là proxy (từ 0.4.6-fix3 thông báo nêu rõ: phiên AutoCAD chưa nạp TDTSolution 9.1 — lưu, đóng AutoCAD, mở lại bằng biểu tượng/profile TDTSolution 9.1, cắm khóa USB TDT nếu cần, rồi chạy lại). Không dùng `BHTTUYENTDT` trong AutoCAD chưa nạp TDT, và không dùng `vlax-curve-*` trực tiếp trên `TDTDBALIGNMENT`. Nếu TDT chưa sẵn sàng, dùng `BHTTUYEN` với một Polyline tham chiếu đã được kiểm tra.

### Chọn chiều và đọc cọc trên tuyến

Trong **Tuyến & báo cáo**, chọn **Chọn điểm đầu và chiều tuyến**. Mũi tên vàng có đầu đặc được giữ trong lúc xác nhận; chọn `C` để lưu chiều, `D` để đảo hoặc `K` để hủy. Hình xem trước được dọn sau khi kết thúc lệnh.

Chọn **Đọc / kiểm tra cọc TDT** để đọc nhãn `KmN+M` trong đối tượng TDT, TEXT/MTEXT, thuộc tính và block lồng nhau. Từ v0.6.9, BHT lấy vị trí tại vạch cọc trên tim khi nhận diện được vạch; nếu chỉ có nhãn chữ thì chiếu vị trí nhãn lên tuyến và hiển thị offset để kiểm tra.

BHT liệt kê cọc và cảnh báo trước khi hỏi nạp Station Control. Cọc trùng, lý trình giảm hoặc tỷ lệ khoảng cách bất thường được giữ để kiểm tra, không tự nạp. Quét lại không tạo mốc trùng. Nếu chưa đọc được cọc, kiểm tra TDT đã nạp, chọn đúng tim và khoảng cách quét tới nhãn.

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
- Trong thẻ **Điểm RTK**, bấm **Tỷ lệ ký hiệu và nhãn RTK…** để chọn riêng tỷ lệ dấu X và tỷ lệ chữ. Mức `1` là dấu X cỡ `1` đơn vị bản vẽ và chữ cao `0,5` đơn vị. Ví dụ X `2`, nhãn `0,75` cho X cỡ `2` và chữ cao `0,375`. Nhận dấu chấm/phẩy, từ `0,01` đến `100`, tối đa 3 chữ số thập phân. Bấm **Áp dụng tỷ lệ** để lưu theo bản vẽ; **Về chuẩn 1:1** đưa hai ô về `1`, rồi áp dụng. **Hủy** giữ cài đặt cũ.
- Đổi tỷ lệ giữ vị trí nhãn hiện có và tọa độ RTK. Cỡ dấu X dùng chung cho mọi thực thể POINT trong bản vẽ vì AutoCAD dùng `PDMODE/PDSIZE` chung; cỡ chữ chỉ đổi các TEXT mang XData `BHT_NHAN`. Ký hiệu/nhãn biển báo có nút tỷ lệ riêng trong thẻ Hồ sơ đối tượng.
- **Cập nhật nhãn RTK** là nút riêng: tạo nhãn thiếu, cập nhật nội dung và sắp lại nhãn tự động. Chọn các điểm để ưu tiên sắp lại nhãn của chúng; không chọn điểm sẽ sắp toàn bộ. Nhãn dời tay giữ vị trí và tỷ lệ đã lưu được dùng cho cả nhãn mới. Làm mới danh sách giữ các dòng đang chọn và dòng đầu đang xem.
- Lệnh `BHTKIEUDIEM` vẫn cho nhập kích thước dấu X và chọn sắp lại toàn bộ nhãn.
- BHT thử 64 vị trí quanh mỗi điểm (8 hướng × 8 khoảng cách), tránh dấu X, nhãn điểm, ký hiệu đối tượng, ký hiệu ảnh và chữ khác của BHT.

### Ảnh và lý trình trong Palette

- Thẻ **Ảnh** không còn dùng các vùng Dock chồng nhau. Khi danh sách rỗng, thẻ nêu rõ cần nhập KMZ hoặc chỉ lại thư mục ảnh.
- Trong thẻ **Hồ sơ**, ô **Lý trình tay** chấp nhận `Km39+050.50`, `39+050,50` hoặc tổng số mét `39050.5`. Nút **Ghi tay** lưu `ly_trinh_m`, `ly_trinh_km` và trạng thái `NHAP_TAY`; **Xóa** đưa về `CHUA_TINH`; **Tính tuyến** gọi quy trình `BHTLYTRINH`.
- Trường Ảnh của hồ sơ luôn có thông báo khi chưa gắn ảnh; nút **Xem ở tab Ảnh** chuyển sang quy trình chọn và xác nhận gắn.

### Bảng quảng cáo, Khác và Chưa xác định

- Chọn nhóm **Bảng quảng cáo** hoặc **Khác**, nhập **Tên trên bảng**, bấm **Lưu hồ sơ**, rồi **Chèn / cập nhật ký hiệu**. Tên được lưu trong trường mô tả; tên đã lưu ở hồ sơ cũ vẫn dùng được.
- Mẫu mặc định có hình chữ nhật Hatch xanh, viền trắng và tên màu trắng ở giữa. Tên dài tự xuống dòng; tên trống dùng tên nhóm.
- Nhóm **Chưa xác định** dùng cùng mẫu nhưng luôn ghi **Chưa xác định** ở giữa. Không có nhãn vàng riêng ngoài bảng.
- Ký hiệu cũ đổi sang mẫu mới khi bấm **Chèn / cập nhật ký hiệu**, giữ vị trí/góc đã đặt. Block tuỳ chỉnh đã gán được ưu tiên. Tuỳ chọn **Tô nền tất cả biển** áp dụng cho toàn bộ ký hiệu biển BHT, gồm bảng tên và các nhóm bảng khác.

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

Trong **Hồ sơ đối tượng** hoặc **Thư viện block**, bật/tắt **Tô màu báo hiệu (Hatch)**. Bấm **Chọn biển** để nhận lựa chọn từ thư viện, **Lưu hồ sơ**, rồi **Chèn / cập nhật ký hiệu** để áp dụng lên CAD. Đóng thư viện không ghi thay đổi. Hồ sơ cũ mặc định tô màu.

Từ 0.6.33, tắt tô nền chỉ ẩn Hatch/Solid đã nhận diện là nền trong bản sao riêng; giữ phần tô của biểu tượng và các vùng rỗng, thêm đường bao nền. Nét và hình theo màu ký hiệu, vùng rỗng giữ trắng khi in. Block gốc và FILLMODE không đổi. Ảnh thumbnail giữ màu minh họa gốc. Block tùy chỉnh cũng được sao riêng. Khi sửa hình block gốc sau khi đã tạo biến thể, cần chọn một block có tên mới để tạo lại biến thể.


### BHT v0.6.2 — Đặt biển và nhãn

- Layer ký hiệu mới dùng ACI 7 (trắng trên nền CAD tối). Khi đồng bộ, màu đỏ mặc định cũ của BHT_KYHIEU đổi thành trắng; màu tùy chỉnh khác được giữ. Biển không tô màu dùng ByBlock nên nét theo màu layer/INSERT; biển có tô màu giữ màu mặt biển.
- Nhãn mặc định 0.35 đơn vị CAD. Điền **Cỡ nhãn CAD** trong hồ sơ → **Lưu hồ sơ** → **Chèn / cập nhật ký hiệu**. Chỉ nhãn BHT thay đổi; dữ liệu/nhãn khảo sát ngoài BHT không bị sửa. Giá trị mặc định cũ 1.5 được thay bằng 0.35, muốn dùng 1.5 hãy nhập riêng trong hồ sơ.
- Trong **Đặt tự do**, chọn **Gấp khúc tự động** hoặc **Đường dẫn thẳng**. Chọn **Hướng biển**: ngang 0° (WCS), theo tuyến, chọn trên CAD, hoặc nhập góc WCS theo độ. Bấm **Chèn biển tự do**, chọn một vị trí. Nếu chọn hướng trên CAD thì chọn hướng sau vị trí. Enter/Esc hủy trước khi hoàn tất sẽ giữ hồ sơ.
- **Chọn điểm trung gian** giữ luồng nâng cao: chọn hướng → điểm trung gian → Dat → vị trí. Lúc đó ô hướng trên Palette bị vô hiệu hóa, hướng chọn trực tiếp trên CAD.
- Các ô lựa chọn không đổi giá trị khi cuộn con lăn; dùng nhấp chọn/bàn phím. Trong lúc BHT chạy thao tác, bấm lặp được bỏ qua với thông báo chờ.
- Đóng và mở lại AutoCAD sau cài đặt để nạp đúng DLL/Lisp v0.6.2.

## Thao tác từ v0.6.3

Gõ BTH hoặc BHT để mở bảng. Đóng bảng sẽ ngắt timer và theo dõi thay đổi; khi chuyển bản vẽ bảng đóng, gọi lại lệnh để mở cho bản vẽ đó. Cài bundle không cần NETLOAD; dùng APPLOAD di động thì gọi BHTLOAD rồi BTH.

Ô Tô màu biển nằm cạnh Chèn biển tự do. Đây là lựa chọn cho cả bản vẽ: bật giữ màu thư viện, tắt bỏ nền và giữ hatch biểu tượng cho biển đã chèn và biển chèn tiếp theo. Không thay Hatch của đối tượng CAD ngoài BHT. Lựa chọn được lưu trong DWG.

Nhãn tự căn giữa dưới khung block và quay cùng biển; không cần nhập cỡ nhãn riêng. Cỡ chữ bằng 15% chiều cao toàn block (bao gồm trụ), khoảng cách dưới bằng 8%. Đây là tỷ lệ BHT hiện tại, chưa xác nhận trị số mặc định TDT trực tiếp.

Cho phép dùng chung điểm RTK chỉ áp dụng khi tạo hồ sơ mới: cho phép một điểm đã thuộc hồ sơ khác được dùng thêm, ví dụ biển và cọc tiêu cùng vị trí. BHT vẫn hỏi xác nhận; không ghi đè hồ sơ cũ. Để chuột trên ô này để xem gợi ý phân nhóm và giải thích; tiêu đề hồ sơ chỉ hiển thị số điểm.


## Nội dung biển và số ghi trên cọc từ v0.6.11

Trong **Thư viện hình ảnh biển báo**, chọn I.439 để nhập tên cầu, lý trình trên biển và tên đường. Ảnh xem trước cập nhật theo nội dung nhập. Bấm Chọn biển, rồi Lưu hồ sơ, sau đó Chèn / cập nhật ký hiệu để cập nhật CAD. Các mặt I.439 trong cùng hồ sơ dùng chung nội dung này.

R.415a là biển gộp làn theo phương tiện; R.415b là biển kết thúc. W.239a dùng biểu tượng điện và có thể ghép S.509a ở dưới; W.239b có ô nhập chiều cao tĩnh không thực tế. Mã chung R.415/W.239 cũ được đổi sang biến thể a khi cập nhật ký hiệu.

Với nhóm Cọc tiêu/Cột Km, bật **Ghi số Km trên ký hiệu** và nhập Số Km. Cọc tiêu nhập thêm H: Km 39, H 9 hiển thị H9/39 cạnh đầu cọc; cọc Km hiển thị KM và 39 trong block. Bỏ chọn để không ghi số. Cọc tiêu chưa có lý trình và mọi cọc Km không hiện nhãn ngoài; H9/39 vẫn hiện cạnh đầu cọc. Điểm chèn cọc Km nằm giữa thanh đen ở đuôi block. Lý trình tự lấy từ số Km/H khi lưu: Km 46, H 1 là Km46+100; cọc Km 39 là Km39+000. Không cần ghi tay lại. BHT ghi rõ nguồn “Số Km/H đã nhập”; giữ liên kết tuyến, điểm RTK và ảnh. Khi tắt ghi số, chỉ lý trình do các ô này tạo ra được xóa; lý trình tay độc lập vẫn được giữ. Nếu đã gán block tùy chỉnh, bỏ gán khi muốn dùng mẫu mặc định này.

Biển I.439 giữ khung đôi, nền xanh, phông Giaothong1 và chân trụ của mẫu TDT cũ. Dòng dưới ghép lý trình và tên đường, ví dụ **KM38+723-ĐT.830**. Với **Chọn hướng trên CAD**, chọn vị trí rồi chỉ về phía đầu đỏ của cọc (hoặc mặt biển); BHT xét hướng gốc của block và hệ tọa độ đang dùng. **Nhập góc WCS** vẫn là góc quay block, không đổi ý nghĩa.

## Chọn biển và số mặt trong 0.6.26

Vào **Chọn biển…**, chọn W.207a hoặc R.415a/b để dùng hình đã sửa. Sau khi cài bản mới, bấm **Chèn / cập nhật** trên hồ sơ cũ để thay ký hiệu và giữ vị trí đã đặt.

DP.134 (**Hết hạn chế tốc độ tối đa**) và R.306 (**Tốc độ tối thiểu cho phép**) có ô **Tốc độ trên biển (km/h)**. Nhập số nguyên từ 5 đến 130; ảnh xem trước đổi theo số nhập. Khi chọn nhiều mặt, nhập số rồi bấm **Thêm mặt** cho từng biển. Ví dụ: `DP.134-50; R.306-30`. Chỉ chọn mã không kèm số dùng mẫu DP.134 là 50 và R.306 là 30; chọn trong thư viện điền sẵn các giá trị này để người dùng sửa theo khảo sát.

**Số mặt biển** tự đếm và chỉ xem được với nhóm Biển báo: chọn một mặt hiện `1`; hai tấm cùng mã vẫn tính `2`. Thêm/bỏ mặt trong thư viện để đổi số lượng. Tắt **Chọn nhiều mặt trên cùng trụ** rồi chọn một biển sẽ thay danh sách cũ bằng đúng một mặt. **Số trụ/chân** là số chân đỡ thực tế, vẫn nhập riêng và không suy ra từ số mặt.

## Nhãn đèn, trạm thu phí và xem CAD khi chọn biển (0.6.28)

Nhãn **Đèn chiếu sáng / tín hiệu** nằm bên dưới ký hiệu, căn giữa và quay theo hình. Sau khi nâng cấp, chọn hồ sơ cũ và bấm **Chèn / cập nhật** để đổi vị trí nhãn.

**Chọn biển…** mở thư viện song song với CAD: chuyển sang bản vẽ để zoom, pan và xem rồi quay lại chọn. Bấm lại nút này đưa thư viện đang mở lên trước. Bấm **Chọn biển** trong thư viện để nhận vào hồ sơ; **Đóng**, Escape hoặc dấu X hủy lựa chọn. Đổi hồ sơ/bản vẽ sẽ đóng thư viện. Khi thư viện còn mở, chọn hình CAD không tự chuyển hồ sơ đang sửa.

**IE.472a** có nền xanh, chữ trắng TRẠM THU PHÍ / TOLL PLAZA và bảng khoảng cách bên dưới. Nhập ô **Giá trị thực tế (m)**, ví dụ 500 hoặc 750; ảnh xem trước đổi theo số nhập. Chọn nhiều mặt: nhập giá trị rồi bấm **Thêm mặt** cho từng tấm. **IE.472b** chỉ có bảng trạm thu phí, không có khoảng cách. Hai mẫu hoạt động khi không có TDT. Lưu hồ sơ và **Chèn / cập nhật** để nhận hình mới trên CAD.


## Nội dung biển và bố trí CAP1 2D (0.6.32)

Trong hồ sơ Biển báo, mở **Thư viện biển báo BHT**. Nhóm **Biển chỉ dẫn trên đường cao tốc** hiển thị đúng biển cao tốc; biển phụ vẫn tìm được trong **Tất cả** hoặc theo mã S. Mục lọc Biển phụ trống đã được bỏ.

1. Chọn một biển hoặc bật chọn nhiều mặt, thêm từng mặt theo thứ tự. Mã trùng được giữ thành các mặt riêng.
2. Mở **Nội dung / CAP1…**. Chọn bố trí, nhập **Cách mặt** và **Cao đáy**. Sơ đồ phía trên minh hoạ thứ tự mặt; CAD dùng kích thước thật của block.
3. Trong bảng, nhập **Nội dung hồ sơ** cho từng attribute. Cột **Chữ mẫu tham khảo** chỉ dùng khi bấm **Dùng mẫu dòng chọn**. Địa danh cần nhập theo hồ sơ thực tế trước khi xác nhận chọn biển. Tên cầu I.439 nhập tại phần Tên cầu của cửa sổ thư viện.
4. Bấm **Áp dụng**, rồi **Chọn biển** và **Lưu hồ sơ**. Dùng **Chèn/Cập nhật ký hiệu** để đưa thay đổi vào CAD.

CAP1 gồm một biển một/hai trụ; hai hoặc ba biển ngang/dọc; ba biển tam giác/tam giác ngược; khung cổng và cần vươn. Bố trí 1–8 yêu cầu đúng số mặt tương ứng. Khung cổng/cần vươn nhận 1–20 mặt. **Bố trí hiện tại** giữ cách xếp dọc trước đây.

**Cách mặt** từ 0,02 đến 10; **Cao đáy** từ 0,1 đến 100 đơn vị CAD trước khi nhân tỷ lệ ký hiệu. Chấp nhận dấu phẩy hoặc chấm thập phân. Với CAP1, số trụ được lấy theo bố trí. Khung cổng có hai chân, cần vươn có một chân; cơ chế nối điểm RTK dùng đúng các chân này.

Mỗi trường nội dung tối đa 160 ký tự, lưu Unicode NFC. Chữ dài được thu hẹp để giữ chiều rộng ô chữ mẫu. Các thông số mét/tốc độ/giờ và tên cầu vẫn dùng các ô chuyên biệt hiện có. Có thể sửa riêng các attribute của biển tốc độ nhiều làn.

CAP1 là hình trình bày 2D, chưa tính kích thước kết cấu, tải trọng hoặc móng. Địa danh cần được kiểm tra với hồ sơ thực tế; chưa có chức năng tự đối chiếu một bộ hồ sơ bên ngoài.

## Nhập thông số biển theo thiết kế — 0.6.33

Chọn biển hoặc thêm các mặt → **Nội dung / CAP1…** → sửa cột **Nội dung hồ sơ** → **Áp dụng** → **Chọn biển** → **Lưu hồ sơ** → **Chèn / cập nhật ký hiệu**.

Bảng nhận cả attribute và chữ CAD thường (TEXT/MTEXT) chứa số. Có thể sửa khoảng cách trên I.441/biển cao tốc, tốc độ theo làn, tải trọng, kích thước, độ dốc, giờ, tần số và số điện thoại. Mỗi mặt có giá trị riêng, kể cả hai mặt cùng mã. Các ô tốc độ, mét, giờ và tên cầu ở cửa sổ chọn biển tiếp tục hoạt động; nội dung nhập riêng từng trường được ưu tiên khi cùng trường có giá trị.

- Với mẫu `500 m`, nhập `350,5` hoặc `350.5 m` sẽ thành `350.5 m`. Với mẫu `2 km`, giữ đơn vị km. Cho phép khoảng cách `0` như IE.475A. Số có tối đa 8 chữ số thập phân; tốc độ theo làn là số nguyên 5–130 km/h, từng hàng chữ số lý trình là 0–9.
- Giờ nhập `5:00` hoặc `22:00-05:00`, chuẩn hóa thành `05:00`; khoảng giờ có thể qua đêm. Giờ ngoài 00:00–23:59 bị từ chối.
- Địa danh, lý trình và số điện thoại nhận nội dung văn bản theo hồ sơ. Địa danh không tự lấy chữ mẫu; dùng **Dùng mẫu dòng chọn** nếu cần.

Ảnh trong thư viện là mẫu tham khảo. CAD dùng thông số đã lưu. Chữ dài được thu hẹp theo chiều rộng mẫu; kiểm tra độ rõ và tỷ lệ trước khi in.

## Xoay đồng loạt đầu biển — 0.6.35

Mở tab **Tuyến & báo cáo** → **Xoay đồng loạt đầu biển theo hướng…**, hoặc gõ `BHTHUONGBIEN`.

1. Nhập `T` để theo chiều tuyến. Chọn ID tuyến nếu có nhiều tuyến. Đầu biển hướng theo tiếp tuyến A→B tại điểm RTK của từng hồ sơ, kể cả tuyến cong; biển hai bên đường dùng cùng chiều. Cần xác nhận đầu tuyến/chiều bằng `BHTROUTESTART` trước nếu chiều hiện tại chưa đúng.
2. Hoặc nhập `H` để dùng hướng chung. Chọn điểm A rồi B trên CAD: phần đầu của tất cả biển được chọn sẽ hướng A→B. Muốn mọi biển đứng thẳng lên trên màn hình, chọn B phía trên A. Hai điểm này chỉ quy định hướng, không dời biển đến A hoặc B.
3. Nhập `A` để xoay tất cả biển phù hợp, hoặc `C` rồi chọn ký hiệu/nhãn/dấu tròn gốc/điểm RTK của nhóm cần xoay. Enter kết thúc chọn.
4. Kiểm tra kết quả rồi lưu DWG. Dùng `U` để hoàn tác cả lần xoay.

Lệnh chỉ xoay các hồ sơ **BIEN_BAO** đã có ký hiệu BHT. Chế độ theo tuyến bỏ qua hồ sơ thuộc tuyến khác, không chiếu được lên phạm vi tuyến hoặc vượt `max_offset`; hồ sơ chưa gán tuyến có thể dùng tuyến được chọn. Kết quả báo số biển đã xoay, số bỏ qua và ID tương ứng. Lệnh không tự gán tuyến hoặc tính lại Km.

Vị trí và tỷ lệ ký hiệu, tọa độ RTK, tâm X và các điểm gấp khúc giữ nguyên. Nhãn và đầu đường dẫn được cập nhật theo góc mới; khung nhiều chân nối lại từng chân. Hướng đã chọn được lưu trong hồ sơ: chế độ theo tuyến lấy chiều hiện tại khi cập nhật ký hiệu, chế độ hướng chung giữ góc đã chọn. Đặt riêng một biển với lựa chọn vị trí/hướng mới sẽ thay chế độ hàng loạt của biển đó. Block tùy chỉnh dùng trục +X làm hướng đầu; biển BHT dùng hướng đầu thực của mẫu.

## Dấu tròn tại tâm điểm chân biển — 0.6.34

Khi chèn/cập nhật ký hiệu biển báo, BHT thêm block tròn đặc `BHT_SIGN_ORIGIN_V0634` tại tâm X của từng điểm RTK liên kết với hồ sơ. Dấu trên layer `BHT_KYHIEU`, màu 7, nên vẫn hiện khi tắt layer điểm RTK. Bán kính là 0,07 đơn vị CAD trước khi nhân tỷ lệ biển; đổi tỷ lệ biển sẽ đổi kích thước dấu.

Dấu giữ nguyên tọa độ RTK khi dời hoặc xoay hình biển. Đặt tại G vẫn có dấu, kể cả khi không có đường dẫn. Biển có nhiều điểm chân có dấu tại từng điểm. Tắt **Tô nền tất cả biển** vẫn giữ dấu tròn đặc. Cần bật `FILLMODE = 1` rồi REGEN để hiển thị phần đặc của polyline.

Chọn dấu trong CAD để mở hồ sơ biển ở Palette. Khi đổi danh sách điểm hoặc xóa hồ sơ, dấu được đồng bộ/xóa cùng ký hiệu. Bản vẽ cũ nhận dấu sau khi nâng cấp hoặc bấm **Chèn / cập nhật ký hiệu**; lưu DWG để giữ kết quả. Dấu thuộc phần trình bày, không thay đổi điểm và dữ liệu RTK gốc.

## Biển phụ và chọn đầu tuyến — 0.6.34

Trong **Thư viện biển báo BHT**, chọn nhóm **Biển phụ** để xem 47 mẫu mã S. Có thể tìm trực tiếp `S.501`, `S.502`, `S.505a`… Nhóm cao tốc hiển thị riêng biển cao tốc. Chọn nhiều mặt trên cùng trụ để ghép biển chính và biển phụ theo hồ sơ.

Ở tab **Tuyến & báo cáo**, bấm **Chọn Polyline thường** hoặc **Lấy / cập nhật tim từ TDT 9.1**. Sau khi tạo tuyến mới, BHT yêu cầu chọn điểm đầu trên/gần tuyến và hiện mũi tên vàng. Nhập `C` để chấp nhận, `D` để đảo rồi xác nhận, hoặc `K` để hủy bước đổi chiều. Điểm được chiếu lên hình học tuyến và chuyển từ UCS hiện tại sang WCS.

BHT không suy ra đầu tuyến thiết kế hoặc lý trình Km từ hình dạng PL. Nếu bỏ qua bước chọn, tuyến giữ đỉnh đầu và chiều vẽ làm mặc định; cần bấm **Chọn điểm đầu và chiều tuyến** (`BHTROUTESTART`) để xác nhận lại trước khi dùng. Với tuyến TDT đã đăng ký, cập nhật tim giữ điểm đầu/chiều đã chọn; dùng nút trên để đổi khi cần.

Chọn đầu tuyến chỉ đặt gốc khoảng cách và chiều tăng. Lý trình Km cần mốc đã xác nhận qua `BHTMOCKM` hoặc đọc/kiểm tra cọc TDT. Đổi đầu tuyến/chiều sau khi có mốc sẽ giữ mốc và đánh dấu Station Control cần kiểm tra lại.

## Thư viện đèn và chọn biển nhanh — 0.6.36

Thư viện biển hiển thị tối đa 60 mẫu mỗi trang. Dùng Trang trước / Trang sau hoặc gõ mã để tìm trên toàn bộ danh mục. Ảnh xem trước chỉ nạp khi cần; không phải chờ toàn bộ ảnh của thư viện.

Để dùng đèn: chọn hoặc tạo hồ sơ nhóm DEN, bấm **Nạp DWG…** tại phần block tùy chỉnh. Hộp chọn mở thư mục **LightLibrary**. Chọn mẫu, bấm **Lưu**, sau đó **Chèn / cập nhật ký hiệu**. Mẫu chỉ gán cho hồ sơ đang sửa. Có thể chọn DWG khác ngoài thư viện.

- DEN_CS_DON_MB: đèn đơn, mặt bằng.
- DEN_CS_DOI_MB: đèn đôi, mặt bằng.
- DEN_CS_TRANG_TRI_MB: đèn trang trí, mặt bằng.
- DEN_CS_TRAI_MD / DEN_CS_PHAI_MD: mặt đứng cột đèn, cần trái / phải.
- DEN_TIN_HIEU_3_MAU: ký hiệu đèn giao thông ba màu, BHT tạo.
- DEN_CANH_BAO_VANG: ký hiệu đèn cảnh báo vàng, BHT tạo.

Các mẫu là ký hiệu 2D, không thay thế chi tiết cấu tạo hay kích thước thiết kế thực tế. Chọn mẫu MB khi bố trí trên bình đồ, MD khi cần hình mặt đứng. Điểm gốc block đặt tại chân/tâm trụ; điều chỉnh tỷ lệ theo bản vẽ. Việc gán mẫu không thay đổi tọa độ RTK.

Trong **Nội dung biển**, phần **Bố trí khung/trụ nâng cao** mặc định tắt. Bật khi cần bố trí nhiều mặt hoặc khung/trụ CAP1. Hồ sơ cũ có CAP1 vẫn mở lại đúng chế độ; bỏ chọn sẽ chuyển sang bố trí thường khi lưu.

Sau khi cài bản mới cần khởi động lại AutoCAD để nạp DLL mới; DLL đã nạp trong phiên CAD hiện tại không tự thay thế.

## Cách dùng phần cập nhật 0.6.37

**Nội dung biển:** chọn mẫu → Nội dung biển… → sửa các dòng → Áp dụng → Chọn biển. Tốc độ, giờ, khoảng cách, tải trọng và thông tin cầu đều nhập tại đây. Với nhiều mặt, mỗi dòng ghi rõ số mặt và mã biển. Dữ liệu đã lưu ở các phiên bản trước vẫn đọc được.

**Dữ liệu tuyến:** mở Tuyến & báo cáo → Dữ liệu tuyến. Chọn tuyến rồi bấm Hiển thị / zoom tuyến hoặc nhấp đúp. BHT mở lớp của tuyến nếu đang tắt/đóng băng, chọn hình học và zoom vừa toàn tuyến. Bảng báo Thiếu hình học nếu đường tham chiếu đã bị xóa. Chiều dài theo đơn vị bản vẽ. Làm mới tuyến để đọc lại danh sách.

**Xoay vuông góc:** gọi BHTHUONGBIEN → H → chọn A rồi B theo hướng đường → C → chọn nhóm biển → Enter. Đầu biển xoay vuông góc về phía trái A→B. Đổi thứ tự A/B để quay sang phía đối diện. Không cần tạo tuyến cho cách H. Chọn T nếu đã có tuyến và muốn theo tiếp tuyến tại từng vị trí. Chọn A ở bước phạm vi để áp dụng mọi biển phù hợp; Undo một lần hoàn tác cả nhóm.

Đóng AutoCAD trước khi cài; mở lại để nạp DLL 0.6.37. Không NETLOAD chồng DLL mới lên phiên đang dùng 0.6.36.

## Quản lý tuyến 0.6.38

Mở **Tuyến & báo cáo → Dữ liệu tuyến**. Bấm vào dòng để chọn và làm sáng tuyến trên CAD; nhấp đúp hoặc bấm **Hiển thị / zoom tuyến** để nhìn toàn tuyến.

- **Sửa tuyến…** (`BHTSUATUYEN`): đổi ID, loại, khoảng cách tối đa và ngoại suy. Nhập tại dòng lệnh CAD; Enter giữ giá trị cũ. Sau đó chạy Cập nhật lý trình.
- **Chọn lại tuyến…** (`BHTCHONLAITUYEN`): chọn Polyline thay thế, xác nhận C rồi chọn điểm đầu/chiều tuyến. Mốc Km cũ bị bỏ; cần nạp lại mốc trước khi tính lý trình. Tim TDT gốc dùng Lấy / cập nhật tim từ TDT 9.1.
- **Xóa tuyến…** (`BHTXOATUYEN`): xác nhận C để bỏ khai báo; Enter/K hủy. Giữ đường vẽ, điểm RTK và góc biển. Các hồ sơ liên quan chuyển sang chưa có tuyến. Undo khôi phục thao tác.

Khi có nhiều tuyến, các nút điểm đầu, đảo chiều và mốc Km dùng dòng đang chọn. Không chọn dòng thì lệnh sẽ hỏi ID tuyến như trước. Cập nhật lý trình vẫn chạy trên toàn bộ hồ sơ theo cơ chế chọn tuyến hiện có.

Đóng tất cả AutoCAD trước khi cài 0.6.38, sau đó mở lại để nạp DLL mới. Không NETLOAD chồng DLL mới vào phiên đã nạp BHT cũ.
## Lý trình khi chỉ có cọc Km — 0.6.39

Nút **Tính tuyến** ở hồ sơ chỉ tính hồ sơ đang chọn theo các tuyến/mốc đã khai báo; thiếu dữ liệu sẽ báo lý do và giữ giá trị cũ. Bấm **Tuyến & báo cáo → Kiểm tra 2 cọc Km (không có tuyến)** để chọn hai cọc, nhập `Km45+000`, `Km46+000` rồi chọn vị trí. Kết quả là ước tính theo đoạn thẳng nối cọc, không theo đường cong. Lệnh không ghi hồ sơ; sau khi kiểm tra có thể nhập kết quả bằng **Ghi tay**. Không dùng PL vẽ thử để tính lý trình thiết kế.
## Sửa hiển thị và hướng tuyến 0.6.40

Đóng AutoCAD và cài bản mới để nạp DLL 0.6.40. Vào Hồ sơ đối tượng → Đặt ký hiệu → Đặt tự do → Hướng ký hiệu: **Vuông góc với tuyến**. Chọn tuyến nếu được hỏi, sau đó đặt vị trí biển. Hướng đầu biển vuông góc về bên trái chiều A→B; đảo chiều tuyến để đổi phía.

Các biển đã đặt trước đó không tự xoay ngay khi cài. Để sửa cả nhóm, vào Tuyến & báo cáo → Xoay biển vuông góc với hướng… (`BHTHUONGBIEN`), chọn tuyến và phạm vi biển cần áp dụng. Tuyến tham chiếu phải đúng hình học thực tế để hướng xoay có ý nghĩa.
### Cập nhật ký hiệu sau khi cài phiên bản mới

Từ 0.6.44, mở hoặc chuyển bản vẽ không tự dựng lại ký hiệu. Chọn các hồ sơ cần áp dụng mẫu mới rồi bấm **Chèn / cập nhật**.
