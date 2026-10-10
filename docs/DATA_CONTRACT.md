# BHT — HỢP ĐỒNG DỮ LIỆU DWG (0.4.6)

Tài liệu này mô tả **đúng định dạng mà mã Lisp (BHT-0.4.6.lsp) ghi vào bản vẽ**, lấy trực tiếp từ mã nguồn
(`bht:rec-encode`, `bht:rec-decode`, `bht:rec-write`, `bht:pt-write-xdata`, `bht:obj-create`, `bht:photo-link`,
các hàm ký hiệu / nhãn). Plugin .NET (BHT.Bridge) đọc/ghi **chính định dạng này**; DWG là nguồn dữ liệu duy nhất.
Định dạng 0.4.6 **giống hệt 0.4.5 / 0.3.3 / 0.3.2** (không đổi cấu trúc) — bản vẽ cũ mở bình thường.

## 1. Kho bản ghi: Named Object Dictionary `BHT_V02`

```
NOD
 └─ BHT_V02            (DICTIONARY)
     ├─ META           (DICTIONARY)  khóa "CONFIG"      – cấu hình chung
     ├─ DATASET        (DICTIONARY)  khóa = mã bộ dữ liệu (vd BOT19)
     ├─ OBJ            (DICTIONARY)  khóa = object_id (vd OBJ-000001)
     ├─ PHOTO          (DICTIONARY)  khóa = photo_id
     ├─ ROUTE          (DICTIONARY)  tuyến tham chiếu + mốc Km
     └─ SEG            (DICTIONARY)  gói thầu / đoạn tuyến (từ BHT_GOI_THAU.tsv)
```

* Khóa luôn **CHỮ HOA** (`strcase`). Khóa kết thúc bằng `__BHT_CU` là bản sao lưu tạm trong lúc ghi — **bỏ qua khi đọc**.
* Mỗi bản ghi = một `XRECORD` (`280 = 1`, MergeStyle giữ nguyên khi chèn/ghép bản vẽ) chứa dãy nhóm mã `1`:
  * `(1 . "khoa=gia tri")` — một cặp khóa/giá trị;
  * giá trị dài hơn 200 ký tự được chia khúc 200 ký tự; khúc tiếp theo ghi `(1 . "khoa+=phan tiep")` và
    **được nối vào cặp ĐỨNG NGAY TRƯỚC** (không tìm theo tên khóa);
  * một khóa có thể lặp lại (danh sách): `pt=…`, `pt=…` ; `anh=…` ; `mat=…` ; `doi_tuong=…`. **Thứ tự được giữ**.
  * Dấu `=` đầu tiên tách khóa và giá trị; giá trị có thể chứa `=`.
* **Ghi an toàn** (0.3.2+; C# làm y hệt trong một Transaction): tạo XRECORD mới **trước** → đổi tên bản cũ thành
  `KHOA__BHT_CU` → gắn bản mới vào khóa → xóa bản cũ. Lỗi ở bước nào thì giữ bản cũ.
* Hàm Lisp: `bht:get` (giá trị đầu tiên hoặc ""), `bht:get-all`, `bht:set` (thay cặp đầu tiên, xóa các cặp trùng
  sau đó, thêm cuối nếu chưa có), `bht:set-all` (xóa hết cặp khóa đó rồi thêm vào cuối). C#: `BhtRecord.Get/GetAll/Set/SetAll`.

### 1.1 OBJ — hồ sơ đối tượng (đơn vị quản lý)
Thứ tự trường khi tạo (`bht:obj-create`, C# `ObjectLogic.BuildNew` giống hệt):

| khóa | ý nghĩa |
|---|---|
| object_id | ID (A-Z 0-9 _ - .) |
| nhom | mã nhóm (vd `COC_TIEU`, `BIEN_BAO`, …; `CHUA_XAC_DINH`) |
| ma_hieu | mã hiệu do người dùng nhập (không tự bịa mã QCVN) |
| loai_ma | mặc định `CHUA_XAC_DINH` |
| mo_ta, so_tru, tinh_trang, ghi_chu | nhập tay |
| so_mat | nhóm BIEN_BAO: đếm danh sách mat, hoặc 1 khi chỉ có ma_hieu; nhóm khác giữ số đã nhập |
| trang_thai_kt | mặc định `CHUA_KIEM_TRA` |
| phia_duong | mặc định `CHUA_XAC_DINH` |
| doan, goi | gói/đoạn (rỗng khi tạo) |
| gan_doan_pp | `CHUA_PHAN_DOAN` |
| route_id, ly_trinh_m, ly_trinh_km, offset_m, phia_tuyen, nguon_km | kết quả tính theo tuyến hoặc giá trị ghi tay từ Palette |
| trang_thai_km | `CHUA_TINH` khi mới tạo; `NHAP_TAY` khi người dùng ghi lý trình trong Palette; các trạng thái tính tuyến giữ quy ước cũ |
| tao_luc | thời điểm tạo (`bht:now`) |
| mat (lặp) | các mặt biển |
| pt (lặp) | ID điểm RTK (CHỮ HOA) — một hồ sơ nhiều điểm |
| anh (lặp) | `PHOTO_ID|DA_XAC_NHAN|CACH` (CACH = `THU_CONG`, …) — chỉ khi người dùng xác nhận |
| sua_luc | luôn được đặt lại khi ghi (`bht:obj-write`) |
| sign_heading_mode | `ROUTE` hoặc `FIXED`; rỗng dùng quy tắc góc cũ. Chỉ áp dụng BIEN_BAO |
| sign_heading_route | ID tuyến tham chiếu cho `ROUTE`; không thay `route_id` hoặc kết quả lý trình |
| sign_heading_angle | góc hướng đầu A→B trong WCS, radian, 8 chữ số thập phân cho `FIXED`; chuyển sang góc INSERT theo hướng đầu của block |

`BHTHUONGBIEN` chỉ ghi các trường hướng cho biển đã đặt và phù hợp phạm vi đã chọn. Khi đồng bộ, góc INSERT đổi nhưng điểm chèn/tỷ lệ và `kh_via` giữ nguyên. Đặt riêng một biển hoặc xóa cấu hình đặt tự do sẽ xóa ba trường hướng này cùng cấu hình cũ. Các trường được lưu trong OBJ XRecord và giữ qua chỉnh sửa hồ sơ nhờ cơ chế sao chép bản ghi.

Sau khi tạo: `META/CONFIG obj_seq` = số thứ tự lớn nhất đã dùng (ID mới không dùng lại số đã xóa).
Một điểm có thể thuộc nhiều hồ sơ **chỉ khi người dùng xác nhận rõ** (mặc định từ chối).

### 1.2 PHOTO — ảnh TimeMark (media liên kết)
`photo_id, ten, thoi_gian, lon, lat, gps_hop_le ("1"/"0": 0,0 hoặc không có số = "0"), duong_dan (đường dẫn tương đối
trong chỉ mục), goc (thư mục gốc khi nhập), nguon, antifake, dia_chi, e, n, crs` (e/n = chiếu từ GPS chỉ để **gợi ý
vị trí chụp**, KHÔNG thay tọa độ RTK), `trang_thai` (`CHUA_GHEP` / `DA_XAC_NHAN`), `doi_tuong` (lặp, object_id).
Tìm file JPG (`bht:photo-path-candidates`, C# `PhotoLogic.Candidates`): thứ tự ứng viên `file_tt` → `META thu_muc_anh`
+ tương đối / tên file / `photos\tên file` → `goc` + tương đối … → thư mục DWG + tương đối.

### 1.3 META / CONFIG (một số khóa)
`obj_seq, thu_muc_anh, dataset_cuoi, crs_idx, crs_trang_thai, pt_size, nhan_che_do, nhan_h, nhan_offset, nhan_id, nhan_an,
nhan_kieu_chu, nhan_uu_tien_dt, kh_h, kh_scale, anh_scale, anh_nhan_h, anh_nhan_an, anh_raster_w, anh_duong_dan,
ghep_m, ghep_r, irt_mau_lop, irt_mau_file, irt_mau_thumuc`.

Block tùy chọn theo nhóm dùng ba khóa động: `kh_block_<nhom>` (tên định nghĩa trong DWG), `kh_block_src_<nhom>`
(đường dẫn nguồn để truy vết) và `kh_block_factor_<nhom>` (hệ số đơn vị đọc lúc nạp). Đây là cấu hình trình bày;
hồ sơ và hình học block đã nhập vẫn nằm trong DWG.

### 1.4 DATASET
Mỗi bộ dữ liệu điểm: số dòng, file nguồn, `dinh_dang` (`CSV` / `TSV` — phát hiện nhập cùng bộ dữ liệu bằng cả hai).

## 2. Thực thể và XData (app id)

| Thực thể | Layer | XData app | Nội dung (nhóm 1000, theo thứ tự) |
|---|---|---|---|
| POINT điểm RTK | BHT_RTK | `BHT_PT` | id, dataset, dòng, tên, N gốc, E gốc, Z gốc, phân loại gợi ý, file nguồn, thời điểm nhập, **mô tả gốc chia khúc 80 ký tự** (nối lại khi đọc). ≥ 10 chuỗi. Tọa độ POINT: X=E, Y=N, Z=cao độ — **không bao giờ bị dời** |
| POINT (tương thích v0.1) | BHT_RTK | `BHT_RTK` | tên, mô tả (≤ 80 ký tự đầu) |
| TEXT nhãn điểm | BHT_RTK_TEN / _MOTA / _CAO_DO / _ID | `BHT_NHAN` | pid, loại (`TEN`/`MOTA`/`CAODO`/`ID`), trạng thái (`TU_DONG`/`TAY`), x, y vị trí BHT đặt gần nhất |
| INSERT ký hiệu đối tượng | BHT_KYHIEU | `BHT_KH` | object_id, trạng thái, x, y, góc, tỉ lệ (vị trí trình bày người dùng đã xác nhận được giữ) |
| TEXT nhãn ký hiệu | (layer BHT) | `BHT_KH` | object_id, "NHAN", trạng thái, x, y |
| INSERT ký hiệu ảnh | BHT_ANH_GPS | `BHT_ANHPT` | photo_id |
| TEXT tên ảnh | BHT_ANH_TEN | `BHT_ANHTEN` | photo_id |
| IMAGE raster ảnh | BHT_ANH_RASTER | `BHT_ANHRS` | photo_id |
| LINE dẫn ảnh → raster | BHT_ANH_DAN | `BHT_ANHDAN` | photo_id |

Thực thể BHT được nhận ra **chỉ bằng XData app id** — không dựa vào layer. Lisp và C# không bao giờ sửa thực thể
không có XData BHT (trừ bảng thứ tự hiển thị SORTENTS đối với ảnh nền IRT, xem 4).

## 3. API Lisp cho plugin .NET (0.4.0)

Đăng ký bằng `vl-acad-defun` (gọi được qua `Autodesk.AutoCAD.ApplicationServices.Core.Application.Invoke`).
Mọi hàm nhận/trả **chuỗi**; trả về danh sách `("OK" …)` hoặc `("LOI" "lý do")`; không hỏi người dùng, không mở DCL.

| Hàm | Đối số | Kết quả |
|---|---|---|
| `bht:api-version` | – | `("OK" phiên_bản api_level build)` |
| `bht:api-info-handle` | handle | các dòng giống BHTINFO |
| `bht:api-info-point` / `-info-object` / `-info-photo` | ID | các dòng giống BHTINFO |
| `bht:api-photo-path` | photo_id | `("OK" "đường dẫn JPG Lisp tìm thấy" )` hoặc "" |
| `bht:api-symbol-sync` | "" = mọi hồ sơ / "OBJ-1,OBJ-2" | số tạo/cập nhật/xóa/trùng |
| `bht:api-label-sync` | "" / "ALL" / danh sách ID | nhãn (nhãn dời tay vẫn giữ) |
| `bht:api-point-style` | kích thước dương, ví dụ `"1"` | đặt POINT thành dấu X với kích thước tuyệt đối và sắp lại nhãn |
| `bht:api-rtk-scale` | tỷ lệ X, tỷ lệ nhãn, ví dụ `"2"`, `"0.75"` | đặt PDMODE=3, PDSIZE=tỷ lệ X, đổi chiều cao TEXT BHT_NHAN; giữ vị trí, không tạo/sắp nhãn |
| `bht:api-photo-sync`, `bht:api-photo-stats` | – | đồng bộ / thống kê ký hiệu ảnh |
| `bht:api-check` | – | `("OK" "loi=n" "canh_bao=n" …)` giống BHTKT |
| `bht:api-draworder` | – | thứ tự hiển thị (dùng lệnh DRAWORDER: chỉ gọi khi không có lệnh đang chạy) |

Đã kiểm chứng trong Core Console: `Application.Invoke` trả kết quả khi lệnh .NET được gõ **ở cấp script/dòng lệnh**
(Lisp đang rảnh); khi lệnh .NET bị gọi từ bên trong `(command …)` của Lisp thì Invoke không trả gì → C# báo LỖI,
**không coi là thành công**.

## 4. Ảnh nền IRT (chỉ đổi thứ tự hiển thị)
BHT **không đọc/sửa/xóa** ảnh IRT; chỉ đưa xuống dưới cùng bằng DRAWORDER. Một IMAGE là IRT khi (mẫu cấu hình trong
`META`, BHTTHUTUVE > C): layer khớp `irt_mau_lop`, hoặc đường dẫn file khớp `irt_mau_thumuc` (mặc định
`*\IRT\*, IRT\*, *\IRT.CACHE\*, *\IRT.CACHE, *\IRT_CACHE\*` — IRTv6 lưu tile trong bộ nhớ đệm thư mục `IRT\`),
hoặc tên file / tên ảnh khớp `irt_mau_file`. **Không bao giờ** coi là IRT: thực thể có XData BHT, layer `BHT*`, file
nằm trong thư mục ảnh BHT (`thu_muc_anh`). Ảnh trong Xref không bị đụng tới.

## Bố trí biển tự do (tùy chọn từ v0.5.3)

XRecord hồ sơ OBJ có `kh_mode=TU_DO`, `kh_free_x/y/z` (tọa độ WCS), `kh_free_rot` (radian WCS) và nhiều mục `kh_via` (chuỗi x,y,z WCS theo thứ tự đường dẫn). Không thay đổi `pt`, route_id hay dữ liệu khảo sát. Thiếu cấu hình hợp lệ thì dùng bố trí tự động trước đây. INSERT vẫn dùng XData BHT_KH hiện có; đường dẫn LINE hoặc LWPOLYLINE gắn BHT_KH(object_id,DAN). LWPOLYLINE có các đỉnh từ RTK qua kh_via tới block, theo XY ở cao độ RTK. Reset tự động loại bỏ toàn bộ trường kh tự do, không xóa hồ sơ.

`bht:api-sign-free(object_id)` chạy trong command context; cần hồ sơ BIEN_BAO có vị trí RTK hợp lệ. Các bước chọn hoàn tất trước khi ghi dữ liệu.


## Bổ sung v0.6.1: chế độ tô màu báo hiệu

OBJ có trường tùy chọn `sign_fill`: `0` = không tô màu, `1` = tô màu. Thiếu trường hoặc giá trị khác `0` được hiểu là tô màu để giữ tương thích hồ sơ cũ. Trường này chỉ áp dụng nhóm BIEN_BAO, giữ nguyên Unicode, không thay cấu trúc XRecord. Palette tạo/sửa gửi trường này; Lisp đọc hồ sơ cũ không bắt buộc bổ sung trường.

Block không tô màu có hậu tố `_NOFILL_V061`, sao chép riêng toàn bộ cây block qua database tạm; không dùng chung các định nghĩa con với bản có màu. Hatch/Solid giữ trong định nghĩa với Visible=false; đường bao được thêm để biểu diễn dạng nét. Loop polyline giữ bulge, loop line/circular arc chuyển thành nét/bulge; curve khác dùng 65 điểm lấy mẫu (giới hạn độ chính xác với spline). FILLMODE không đổi. Nếu Bridge không nạp hoặc tạo biến thể thất bại, Lisp báo rõ và giữ block có màu, không ghi tên block rỗng vào INSERT.


## Bổ sung v0.6.2

OBJ có trường tùy chọn `kh_label_h`: chiều cao nhãn dương theo đơn vị CAD. Palette mặc định 0.35, lưu khi tạo và sửa; thiếu trường dùng cấu hình kh_h, riêng mặc định cũ 1.5 được hiểu là 0.35. Bộ API thêm `bht:api-sign-place(oid, mode, direction, degrees)`; giữ API chèn tự do cũ. Mode DIRECT/ELBOW; direction HORIZONTAL/ROUTE/PICK/ANGLE. Điểm/góc vẫn ghi theo WCS vào kh_free_*, kh_via sau khi mọi lựa chọn hợp lệ; không sửa điểm RTK/tuyến.

Biến thể không tô màu dùng `_NOFILL_V062` để bản vẽ đã có cache V061 được tạo lại với ByBlock/layer 0. Bản có màu giữ nguyên. Layer BHT_KYHIEU mới có ACI 7; chỉ ACI 1 cũ được chuyển 7 khi đồng bộ. Nhãn tự động cách chân biển 2.65 × tỉ lệ ký hiệu, giữ vị trí chỉnh tay.

## Bổ sung v0.6.3 (thay quy tắc tô màu/nhãn biển v0.6.1–0.6.2)

META.sign_fill_all: chuỗi 1 (mặc định) hoặc 0, điều khiển tô màu toàn bộ BIEN_BAO BHT. API bht:api-sign-fill(value) kiểm tra giá trị, lưu META rồi đồng bộ riêng các INSERT biển đã có; không chèn hồ sơ chưa có ký hiệu. Các trường OBJ.sign_fill và kh_label_h cũ vẫn giữ nhưng không còn điều khiển biển; Palette không ghi hai trường này.

BHTSIGNBOUNDS(blockName) trả minX,minY,maxX,maxY của BlockReference tại gốc, gồm trụ. Nhãn tại ((minX+maxX)/2, minY−0.08×height), cỡ chữ 0.15×height, sau đó áp dụng scale/rotation/translation INSERT. TEXT dùng DXF72=1,73=3,11 làm điểm căn chỉnh; DXF50 bằng Rotation INSERT, không lật chữ sang góc khác. Nhãn biển được bố trí lại theo quy tắc này khi đồng bộ; nhãn nhóm khác vẫn giữ xử lý vị trí tay trước đây. Khi Bridge chưa đăng ký, dùng khung dự phòng và không gọi hàm native chưa tồn tại.

Các biến thể không tô màu tiếp tục dùng hậu tố V062; không sửa block nguồn TDT, không đổi FILLMODE. API đăng ký hiện có 19 hàm.


## Nội dung thể hiện từ v0.6.10

Các trường OBJ tùy chọn `bridge_name`, `sign_chainage`, `road_name` giữ nội dung I.439 bằng Unicode NFC. Mỗi ô giao diện tối đa 80 ký tự. Đây là chữ in trên biển; `sign_chainage` không thay `ly_trinh_km` tính theo tuyến. Các mặt I.439 trong cùng hồ sơ dùng chung ba trường này.

`marker_km` chứa số Km nguyên từ 0 đến 99999; chuỗi rỗng tương ứng không ghi số. `marker_h` chứa số H từ 0 đến 9 cho cọc tiêu. Km 39 và H 9 tạo nhãn H9/39. Cọc Km tạo block riêng theo số; cập nhật một số không đổi nội dung block của các số khác. Hồ sơ cũ thiếu các trường này tiếp tục dùng ký hiệu không ghi số.

Chữ được chuyển theo phông tại lớp thể hiện; hồ sơ vẫn giữ Unicode. Block tùy chỉnh do người dùng gán được ưu tiên hơn hình mặc định có tham số.

### Tỷ lệ biển và nhãn (0.6.21)

META.sign_scale là hệ số kích thước của INSERT thuộc BIEN_BAO; thiếu khóa dùng kh_scale để giữ tương thích. META.sign_label_scale là hệ số cỡ nhãn mã, độc lập với INSERT; thiếu khóa dùng tỷ lệ thực tế của INSERT như trước. Cả hai lưu dạng số thập phân 3 số lẻ. Nhãn chuẩn có chiều cao 15% chiều cao cụm biển trong block, giới hạn chiều cao cụm ở 2.46; vị trí nhãn theo điểm chèn/góc/tỷ lệ thực tế của cụm. Các mặt phụ cách nhau 1.5 lần chiều cao nhãn.

API bht:api-sign-scale(symbol, label) nhận từ 0.01 đến 100, tối đa 3 chữ số thập phân và nhận dấu phẩy. Kiểm tra cả hai giá trị trước khi ghi. API đổi tỷ lệ DXF 41/42/43 của INSERT biển đã có, giữ vị trí/góc/trạng thái AUTO hoặc TAY trong BHT_KH và đồng bộ nhãn, không tạo ký hiệu còn thiếu. Kích thước biển không đổi khoảng lệch tự động từ điểm RTK; kh_scale vẫn điều khiển khoảng lệch và các nhóm khác. Không thêm trường OBJ hoặc thay định dạng XRecord/XData.

### Tỷ lệ ký hiệu và nhãn RTK (0.6.24)

API `bht:api-rtk-scale(symbol, label)` nhận hai hệ số từ 0.01 đến 100, tối đa 3 số lẻ, nhận dấu phẩy. Kiểm tra cả hai trước khi ghi. META.pt_size giữ kích thước X tuyệt đối (chuẩn 1 đơn vị, 3 số lẻ), META.nhan_h giữ chiều cao chữ bằng 0.5 × label (6 số lẻ để giữ trường hợp hệ số 0.015 cho chữ cao 0.0075). Không thêm trường OBJ hoặc thay cấu trúc XRecord/XData.

PDMODE=3 và PDSIZE=pt_size dùng chung cho mọi POINT của bản vẽ. API chỉ đổi DXF40 của TEXT mang BHT_NHAN, giữ vị trí/nội dung/XData, không tạo nhãn còn thiếu. API `bht:api-label-sync` riêng dùng cỡ đã lưu, tạo nhãn thiếu/cập nhật nội dung và sắp nhãn tự động; nhãn dời tay giữ vị trí. Danh sách ID xác định phạm vi sắp lại; dữ liệu và nhãn còn thiếu vẫn được đồng bộ toàn bản vẽ theo cơ chế hiện có. POINT và BHT_PT không được sửa.


### Trụ/chân và đường nối từng điểm RTK (0.6.25)

OBJ.so_tru được dùng cho hình mặc định thuộc BIEN_BAO/BANG_QC/KHAC/CHUA_XAC_DINH: để trống/1 giữ một trụ, 0 bỏ trụ/chân, 2–100 tạo biến thể theo số trụ. BHTSIGNPOSTS(block, count) clone block trong database riêng, thay các trụ/chân gốc bằng trụ có vòng chân; cache BHT_SUPPORT_V0625_count_hash. Bảng tên đổi cache BHT_BOARD_V0625 để bổ sung vòng chân. Không sửa block nguồn, tài nguyên TDT hoặc block tùy chỉnh.

BHTSIGNFEET(block) trả các tọa độ chân cục bộ x/y/z liên tiếp, sắp theo x. Với hồ sơ nhiều trụ, đường nối lấy từng survey ID có thật trong OBJ.pt và tọa độ POINT trong BHT_PT, không lấy điểm trung bình. Đích được biến đổi theo điểm chèn/góc/tỷ lệ INSERT. Sắp nguồn theo hướng ngang của ký hiệu để ghép các chân; nếu chỉ có một điểm thì nối chân gần nhất. Block tùy chỉnh không nhận diện được chân dùng điểm chèn làm đích.

LINE/LWPOLYLINE trên BHT_DUONG_DAN mang XData BHT_KH (object_id, DAN, survey_point_id). Trường thứ ba là tùy chọn, chỉ đường nối từng chân; đường nối cũ vẫn dùng (object_id, DAN). Khi đồng bộ, giữ/cập nhật theo survey ID, xóa đường trung bình cũ, đường trùng và đường của điểm đã gỡ. Không đổi cấu trúc XRecord OBJ/BHT_PT hoặc tọa độ RTK. Hồ sơ thiếu điểm chân vẫn lưu được và được cảnh báo; không sinh điểm RTK giả.

### Biển tốc độ và số mặt 0.6.26

`DP.134-N` và `R.306-N` dùng N nguyên 5–130 km/h, tương tự `P.127-N`; mỗi giá trị thuộc từng mục `mat`, không dùng chung cho cả trụ. Mã không kèm số vẫn nhận mẫu mặc định 50/30 khi tạo CAD. Dữ liệu và nhãn giữ đúng họ biển.

Palette tự tính `so_mat` cho `BIEN_BAO` từ số mục `mat`; không gộp mã trùng. Nếu danh sách trống nhưng `ma_hieu` có giá trị thì tính một mặt. Chọn một biển trong thư viện thay danh sách cũ, nên không giữ lại mặt thừa. Đọc hồ sơ cũ không tự ghi XRecord; số được cập nhật khi người dùng Lưu. Lisp vẫn đọc `so_mat` cũ để tái dựng mặt lặp cho bản vẽ chưa lưu lại qua Palette. `so_tru` và các liên kết điểm RTK giữ độc lập.

Block sửa W.207a, R.415a/b, DP.134 và R.306 dùng cache `BHT_TDT_V0626_…`. Các block TDT gốc và block người dùng không bị sửa.

Từ 0.6.27, R.415a/b dùng cache `BHT_TDT_V0627_…` để thay các đoạn thừa sát khung; các họ biển khác giữ cache nêu trên.

### Biển trạm thu phí và cửa sổ chọn biển (0.6.28)

`IE.472a@M` dùng M > 0 đến 100000, tối đa 3 số thập phân; chuẩn hóa dấu phẩy sang dấu chấm. Mã không có @ dùng mẫu mặc định 750 m. `IE.472b` không có giá trị mét. Giá trị lưu trong `ma_hieu` hoặc từng mục `mat`, không thêm trường XRecord. Block native dùng cache `BHT_TDT_V0628_…`, phông Giaothong2, hatch xanh RGB(0,152,65), chữ trắng RGB(255, 255, 255), khung bo góc và chân trụ. Không sửa TDT gốc.

Nhãn nhóm DEN dùng đáy extents block để đặt phía dưới, căn giữa/top và biến đổi theo INSERT; cỡ chữ giữ theo kh_scale. XData nhãn và dữ liệu điểm không đổi.

Thư viện dùng [Application.ShowModelessDialog của AutoCAD](https://help.autodesk.com/cloudhelp/2022/ENU/OARX-ManagedRefGuide/files/OARX-ManagedRefGuide-Autodesk_AutoCAD_ApplicationServices_Application_ShowModelessDialog_IWin32Window_Form.html). Cửa sổ chỉ sửa bản nháp Palette; ghi CAD vẫn qua luồng Lưu/Chèn hiện có. Mỗi Palette có một cửa sổ; FormClosed chỉ áp dụng OK nếu document, object ID và trạng thái hồ sơ mới còn khớp. Unbind/đổi hồ sơ hủy cửa sổ. Đồng bộ implied selection vào Palette tạm dừng khi thư viện mở để giữ đích chỉnh sửa; lựa chọn CAD vẫn hoạt động.

Từ 0.6.29, IE.472a/b dùng cache `BHT_TDT_V0629_…`; cả hai mẫu có trụ từ y=0 tới y=0.6 để cơ chế hai chân và ghép mặt loại bỏ trụ gốc đúng cách.


### Nội dung biển và CAP1 (0.6.32)

OBJ thêm bốn trường scalar: `sign_content`, `sign_layout`, `sign_gap`, `sign_clearance`. Hồ sơ thiếu trường dùng LEGACY / 0.2 / 0.6. Đọc hồ sơ cũ không tự ghi trường mới.

`sign_content` là XML `sign-content version="1"`, gồm `face index="0..19" code="mã thực tế"` và `field key="tag#occurrence"`. Chỉ áp dụng nếu cả chỉ số và mã mặt khớp. Mã trùng vẫn có nội dung riêng; đổi thứ tự/bỏ mặt trong picker cập nhật chỉ số. Giá trị trim/NFC, tối đa 160 ký tự; DTD bị chặn. Codec XRecord hiện có chia XML thành các đoạn và ghép lại khi đọc.

`sign_layout`: LEGACY hoặc CAP1_1 đến CAP1_10. Khoảng cách/chiều cao dùng số invariant. API `BHTSIGNCONTENT(block, code, index, xml)` tạo block riêng `BHT_SIGN_CONTENT_V0632_hash`; giữ nguồn, dependencies và draw order. API `BHTSIGNLAYOUT(names, layout, gap, clearance)` bố trí mặt bằng extents trong block `BHT_SIGN_LAYOUT_V0632_hash`. CAP1 dùng số chân theo spec, bỏ bước thay trụ LEGACY để tránh trụ thừa. `BHTSIGNFEET` và XData đường nối vẫn dùng hợp đồng hiện có.

### Nền biển và thông số thực tế (0.6.33)

`META.sign_fill_all` giữ giao thức 1/0. Giá trị 0 chỉ ẩn nền của cây block sao riêng; phần tô biểu tượng được giữ. XData `BHT_SIGN_PRINT` dùng vai trò `BACKGROUND`, `INK`, `VOID`, `PAPER`, `BACKING`, `DERIVED_INK`. VOID/PAPER/BACKING giữ RGB trắng; INK/DERIVED_INK dùng ByBlock/layer 0. Các vòng hatch nguồn được bảo toàn. BACKING đưa đĩa trắng lên trên mũi tên cùng làn, dưới vòng biển và số. DERIVED_INK giữ hình tô từ vòng rỗng của hatch nền, như mũi tên R.310b. Ô bàn cờ có mặt nạ giấy riêng để vùng rỗng không bị hình bên dưới lấp đen.

`FRAME` giữ dải viền theo cặp đường bao nền ngoài/trong. Đường bao đơn được sao nguyên dạng, gồm cung tròn và bulge. Mảng nền bị tách nhiều vòng dùng bao lồi của các vòng để khôi phục toàn bộ chu vi; các đĩa tròn được khôi phục bằng cung tròn. Tâm biển không tô. Các nét đường bao nền giữ nét in 0,25 mm. Viền và hình bên trong cùng dùng ByBlock/layer 0.

Phân loại nền dựa trên hình học, màu và thứ tự vẽ; các mẫu đặc biệt có quy tắc đã đối chiếu bằng mã biển và handle nguồn trong bản thư viện đóng gói. Quy tắc chỉ áp dụng lúc sao thư viện, không ghi vào DWG nguồn. Cache native đổi thành `BHT_SIGN_V0633_…`, biến thể bỏ nền dùng `_NOFILL_V0633` để không tái dùng bản cũ đã ẩn toàn bộ hatch.

`OBJ.sign_content` tiếp tục XML version 1: chỉ số mặt, mã và các field. Attribute giữ khóa `<tag>#<occurrence>` của 0.6.32; TEXT/MTEXT số dùng `TEXT#n` / `MTEXT#n` theo thứ tự vẽ đệ quy. Hai attribute trùng tag giữ riêng giá trị. Khóa DESC_3 cũ vẫn đọc/sửa được. Cache nội dung đổi thành `BHT_SIGN_CONTENT_V0633_…`.

Bridge áp dụng lên database sao riêng, giữ font/đơn vị mẫu; giá trị được chuẩn hóa NFC. Số nhận dấu phẩy/chấm thập phân, không âm, tối đa 1000000000 và 8 số thập phân; tốc độ theo làn là số nguyên 5–130 km/h, mỗi hàng chữ số lý trình là 0–9; đơn vị đã nhập phải khớp mẫu. Giờ nhận HH:mm hoặc HH:mm-HH:mm trong 00:00–23:59 và cho phép qua đêm. Các kiểm tra này dùng chung ở giao diện và Bridge. Giá trị rỗng giữ khả năng bỏ chữ của hồ sơ cũ; số điện thoại/địa danh/lý trình là văn bản. CAP1 và liên kết RTK giữ quy tắc 0.6.32.

## Dấu gốc biển báo (0.6.34)

INSERT block `BHT_SIGN_ORIGIN_V0634` trên layer `BHT_KYHIEU` mang XData `BHT_SIGN_ORIGIN`: hai chuỗi 1000 lần lượt là `object_id`, `survey_id` (viết hoa). Mỗi hồ sơ/điểm có một dấu. Điểm chèn là XYZ RTK, tỷ lệ bằng tỷ lệ ký hiệu biển, góc 0, màu ACI 7.

Block chứa polyline đóng với hai cung bán nguyệt, bán kính đường tâm 0.035 và bề rộng 0,07; bán kính ngoài 0,07, bán kính trong 0. Đây là hình tròn đặc. XData riêng giúp giữ thống kê INSERT `BHT_KH` cho ký hiệu chính. Dấu được đồng bộ khi chèn/cập nhật/nâng cấp và xóa khi xóa ký hiệu/hồ sơ; không ghi vào POINT hoặc XData `BHT_PT`.

## Hướng và nhập nội dung thống nhất (0.6.37)

Chế độ hướng mới: `ROUTE_PERP` và `FIXED_PERP`. Tính hướng như ROUTE/FIXED rồi cộng pi/2 vào góc INSERT. ROUTE/FIXED cũ vẫn giữ cách hiểu ban đầu. `sign_heading_route` dùng cho cả hai chế độ tuyến; `sign_heading_angle` dùng cho cả hai chế độ hướng cố định, lưu phương A→B trong WCS. Hướng vuông góc được giữ khi cập nhật ký hiệu.

Các dòng tốc độ/giờ/mét/tải trọng trong bảng Nội dung biển vẫn lưu theo mã có hậu tố `-value` hoặc `@value`; thông tin cầu giữ trường hồ sơ cũ. Khóa dòng bắt đầu bằng @ chỉ dùng nội bộ giao diện, không ghi vào sign_content. Các trường attribute/TEXT khác vẫn dùng XML version 1 và khóa cũ, cập nhật mã mặt khi giá trị hậu tố thay đổi.

## Route maintenance 0.6.38

`bht:api-route-select(id)` chọn tuyến cho lần gọi `bht:ask-route` kế tiếp trong tài liệu. Giá trị được lấy và xóa ngay khi hỏi tuyến.
Đổi ID cập nhật `route_id` và `sign_heading_route` của hồ sơ; tăng revision. Sửa thuộc tính hoặc thay hình học xóa giá trị lý trình/offset/phía/loại đã tính, đặt `station_status=STALE` và `trang_thai_km=CAN_CAP_NHAT`.
Thay hình học xóa mốc, reset điểm đầu/chiều và xóa metadata nguồn TDT. Xóa khai báo chuyển hồ sơ sang `NO_ROUTE`, xóa liên kết và dữ liệu lý trình. Hướng biển phụ thuộc tuyến chuyển sang FIXED với góc tương đương; không sửa INSERT/RTK/Polyline gốc trong thao tác xóa.