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
| mo_ta, so_tru, so_mat, tinh_trang, ghi_chu | nhập tay |
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
