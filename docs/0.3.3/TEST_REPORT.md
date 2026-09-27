# BHT 0.3.3 — Báo cáo kiểm thử

- File kiểm thử: `BHT-0.3.3.lsp`, 257 451 byte.
- **SHA-256:** `0F9D41A99E6B36005D6BFD3998AC5D95FA91B180F587C6A862E9F2EC7D8CEA2F`
- Mọi phiên dưới đây chạy trên **đúng file này**, nạp từ bản sao `C:\Users\Le Bao\BHT_TEST_V033\thư mục có dấu\BHT-0.3.3-rc.lsp` (cùng SHA-256). File giao chỉ đổi tên.
- Môi trường: AutoCAD 2024 Core Console (`D:\AutoCAD 2024\accoreconsole.exe`, ACADVER 24.3, LISPSYS = 1), Windows, ngày 2026-09-27.
- Dữ liệu:
  - `survey.csv` thật (526 dòng);
  - chỉ mục ảnh KMZ thật đã giải nén ở 0.3.2 (205 ảnh, 205 JPG);
  - bản sao `sample-route.dwg`;
  - bản sao bản vẽ đã làm bằng 0.3.2 (`test_A_saveas.dwg` của phiên kiểm thử 0.3.2);
  - dữ liệu giả: khu dày 60 điểm, 2 ảnh JPG giả làm ảnh nền IRT / ảnh khác.
- **Không sửa** file gốc (DWG, KMZ, CSV), các bản BHT cũ và IRTv6. Mọi thao tác làm trên bản sao trong `BHT_TEST_V033`.

## Tổng hợp

| Phiên | PASS | FAIL | SKIP | BLOCKED |
|---|---|---|---|---|
| S0 (bản vẽ trống) | 6 | 0 | 0 | 1 |
| A (tính năng mới, bản sao sample-route) | 39 | 0 | 0 | 0 |
| B (mở lại SAVEAS 2018 của A) | 8 | 0 | 0 | 0 |
| L (mở bản vẽ làm bằng 0.3.2) | 11 | 0 | 0 | 0 |
| L2 (mở lại bản vẽ 0.3.2 đã nâng cấp) | 2 | 0 | 0 | 0 |
| R (hồi quy 0.3.2) | 29 | 0 | 0 | 0 |
| **Tổng (lần chạy cuối)** | **95** | **0** | **0** | **1** |

BLOCKED: T05, mở bảng DCL. Core Console không có DCL. Mục này và các mục giao diện khác (chọn đối tượng bằng chuột, trình xem ảnh, hiển thị trên màn hình) phải kiểm tay theo `CHECKLIST_NGHIEM_THU.md`. **Chưa có nghiệm thu nào trong AutoCAD đầy đủ.**

## Số liệu chính

- **Chồng lấn nhãn**. BHT tự đếm bằng `bht:lbl-overlaps` trên hộp `textbox`. Một nhãn được tính là chồng lấn nếu đè nhãn của điểm khác, hoặc đè ký hiệu / điểm RTK khác.

  | Trường hợp | Vị trí mặc định 0.3.2 | Sau bố trí 0.3.3 |
  |---|---|---|
  | 526 điểm thật, 1574 nhãn | 941 nhãn chồng lấn (1306 cặp nhãn-nhãn, 216 nhãn đè ký hiệu/điểm) | 26 nhãn (5 cặp, 19 nhãn đè) |
  | Khu dày giả lập, 60 điểm lưới 1,2 m, 160 nhãn | 160 (1351 cặp, 123 đè) | 141 (143 cặp, 25 đè) |
  | Bản vẽ 0.3.2 (531 điểm, 2119 nhãn), `BHTSAPNHAN` > Tất cả | 1480 (2153 cặp, 538 đè) | 133 (37 cặp, 77 đè) |

  **Không khẳng định hết chồng lấn**, nhất là ở khu dày.

- **Thời gian bố trí** (Core Console): 526 điểm / 1574 nhãn khoảng 1,0 s; trả về tự động + bố trí lại toàn bộ khoảng 2,7 s.
- **Điểm RTK không bị di chuyển.** Tọa độ 526 POINT được so trước và sau mọi thao tác nhãn / ký hiệu / ảnh / BHTVEMODEL: 0 lệch (A-L09, A-P03, L-L02, L-L06, L-L08).
- **Thực thể ngoài BHT.** 49 634 thực thể của bản vẽ mẫu, cộng TEXT cùng layer BHT, INSERT cùng block `BHT_KH_*` và XData app khác, được chụp lại trước khi chạy: sau cùng 0 mất, 0 bị sửa (A-N01).

## Lỗi phát hiện và sửa trong lúc kiểm thử (trung thực)

Lần chạy đầu của phiên A được **35 PASS, 3 FAIL** (P04, W01, W02). Nguyên nhân và cách sửa:

1. **W01 / W02: thực thể BHT nằm trong Layout.**
   - Bản vẽ mẫu được lưu khi đang ở tab Layout1 (TILEMODE = 0). Mọi thực thể BHT tạo bằng `entmake` (điểm, nhãn, ký hiệu, ký hiệu ảnh), cùng ảnh chèn bằng `-IMAGE`, đều rơi vào **paper space**.
   - Chẩn đoán bằng các phiên phụ (dbg1–dbg3): ví dụ `BHT_NHAN` model = 0, layout1 = 1734. Bản vẽ kiểm thử của 0.3.2 cũng bị như vậy, với 3059 thực thể BHT trong Layout1.
   - Đây là **lỗi có từ các bản trước**, không phải lỗi mới.
   - Cách sửa:
     - mọi thực thể BHT tạo bằng `(410 . "Model")`;
     - `-IMAGE` / `DRAWORDER` tạm bật TILEMODE = 1 rồi trả lại;
     - thêm `BHTVEMODEL` và cảnh báo trong BHTKT.
   - Đã kiểm lại ở A-M01, L-L05 → L-L10, L2.
2. **W01: ảnh "khác" bị nhận nhầm là IRT** vì đường dẫn chứa thư mục tên `irt` (mẫu `*\IRT*` so trên cả đường dẫn). Sửa: chỉ so mẫu với tên layer, tên ảnh và tên file, không xét thư mục.
3. **P04: thư mục cũ vẫn được ưu tiên hơn thư mục người dùng chỉ định** khi thư mục cũ còn tồn tại. Sửa: `BHTTHUMUCANH` tìm trước trong thư mục người dùng chỉ định.
4. **Lỗi kịch bản kiểm thử** (không phải lỗi BHT), đã sửa kịch bản:
   - `test_L` gọi `length` trên selection set;
   - `t-lbl-states` dùng biến toàn cục `s` trùng với biến `S` của phiên L2/B, vì AutoLISP không phân biệt hoa thường.

Sau khi sửa, toàn bộ các phiên được **chạy lại từ đầu** trên file cuối cùng (SHA-256 ở trên). Kết quả bên dưới là của lần chạy cuối.

## Kiểm tra tĩnh (`tests/scripts/static_check.py`)

```
Ngoac cuoi file (phai = 0): 0
So defun: 358
defun trung: []
defun long nhau: []
Goi nhung khong dinh nghia / khong phai ham AutoLISP: ['eval', 'set']
Ham trich dan ('ham) khong dinh nghia: []
Bien setq chua khai bao cuc bo (co the la bien pham vi dong co chu dich):
   ('bht:pt-owner-map', ['pid'])
   ('bht:ck-add', ['errs', 'lines', 'warns'])
   ('bht:st-chk', ['fail', 'pass'])
```

- `eval`, `set`: hàm AutoLISP chuẩn (danh sách hàm dựng sẵn của công cụ kiểm tra chưa có hai hàm này).
- 3 cảnh báo biến setq: giống hệt 0.3.2, là cố ý (biến vòng `foreach` / biến động của hàm đếm).
- 59 lệnh `c:`. So với 0.3.2: thêm `BHTSAPNHAN`, `BHTNHANTUDONG`, `BHTTHUTUVE`, `BHTVEMODEL`; không mất lệnh nào.

## Chi tiết từng phiên (lần chạy cuối)

### Phiên S0 — bản vẽ trống: nạp, phiên bản, BHTTEST, DCL tĩnh

Phiên S0: Drawing1.dwg \| ACADVER=24.3 \| LISPSYS=1 \| CDATE=20260927.142835

| Mã | Kết quả | Nội dung | Chi tiết (rút gọn) |
|---|---|---|---|
| T00 | **PASS** | nạp BHT-0.3.3 (đường dẫn có dấu); *bht-version* = 0.3.3 | 0.3.3 / 2026-09-27 |
| T01 | **PASS** | thông báo APPLOAD đúng nguyên văn | BHT 0.3.3 đã nạp thành công. |
| T02 | **PASS** | BHTTEST tự kiểm tra hàm (0 FAIL, >= 42) | 42 pass, 0 fail |
| T03 | **PASS** | DCL tĩnh: mọi nút gọi lệnh có thật, khóa duy nhất, nút nào cũng có trong mẫu, không sót @nhãn@, { } cân bằng (42 nút) | nút=42 lỗi=nil thiếu=nil {=90 }=90 sót=nil |
| T04 | **PASS** | lệnh mới 0.3.3 được định nghĩa |  |
| T05 | **BLOCKED** | mở bảng DCL BHT (load_dialog / new_dialog / start_dialog) | Core Console không có DCL - kiểm tra thủ công theo CHECKLIST |
| T06 | **PASS** | chạy lệnh không tương tác trên bản vẽ trống: BHTTEST, BHTKT, BHTTRANGTHAI, BHTHELP |  |

### Phiên A — bản sao sample-route.dwg (đang ở tab Layout1): tính năng mới 0.3.3, lưu SAVEAS 2018

Phiên A: A_in.dwg \| ACADVER=24.3 \| LISPSYS=1 \| CDATE=20260927.142953

| Mã | Kết quả | Nội dung | Chi tiết (rút gọn) |
|---|---|---|---|
| T00 | **PASS** | nạp BHT-0.3.3 | 0.3.3 |
| R01 | **PASS** | nhập 526 điểm RTK (CSV trực tiếp = mặc định) | ((ADDED . 526) (SAME . 0) (CONFLICT . 0) (DUPCONTENT . 0) (ADOPTED . 0) (INVALID . 0) (DUPFILE . 0)) |
| R02 | **PASS** | tọa độ + chuỗi gốc 526/526 không đổi (X=E, Y=N, Z) | (526 0) |
| D01 | **PASS** | nhập lại cùng dữ liệu bằng TSV: 0 điểm thêm, không trùng, cảnh báo 'không cần nhập cả CSV và TSV'; dataset ghi định dạng CSV+TSV | (((ADDED . 0) (SAME . 526) (CONFLICT . 0) (DUPCONTENT . 0) (ADOPTED . 0) (INVALID . 0) (DUPFILE . 0)) CSV+TSV) |
| L01 | **PASS** | tạo nhãn tự động cho 526 điểm (tên+mô tả+cao độ), không trùng, trạng thái TU_DONG | ((POINTS . 526) (CREATED . 1574) (UPDATED . 0) (UNCHANGED . 0) (DELETED . 0) (LAIDOUT . 526) (MANUAL . 0) (COST . 21.0914)) \| trạng thái (tự động tay cũ)=(1574 0 0) \| 1016 ms |
| L02 | **PASS** | chữ nhãn = CSV nguyên văn | (1574 nil) |
| L03 | **PASS** | 526 điểm thật: chồng lấn vị trí 0.3.2 (trước) -> sau BHTNHANTUDONG (trả về tự động + bố trí lại) giảm; không trùng nhãn | TRƯỚC (vị trí 0.3.2): 941 / 1574 nhãn còn chồng lấn (cặp nhãn-nhãn 1306, nhãn đè ký hiệu/điểm 216) \|\| SAU: 26 / 1574 nhãn còn chồng lấn (cặp nhãn-nhãn 5, nhãn đè ký hiệu/điểm 19) \| 2656 ms \| trạng thái sau khi đặt về vị trí 0.3.2 (0 1574 0) |
| L04 | **PASS** | chạy lại BHTNHANDIEM: không tạo/xóa/dời nhãn nào | ((POINTS . 526) (CREATED . 0) (UPDATED . 0) (UNCHANGED . 1574) (DELETED . 0) (LAIDOUT . 0) (MANUAL . 0) (COST . 0.0)) |
| L05 | **PASS** | nhãn người dùng dời tay: nhận ra TAY, giữ nguyên vị trí khi cập nhật (đổi cao chữ, bố trí lại TẤT CẢ) | ([đã ẩn tọa độ] [đã ẩn tọa độ] [đã ẩn tọa độ] [đã ẩn tọa độ] [đã ẩn tọa độ] 1) |
| L06 | **PASS** | trả nhãn đã dời về tự động (BHTNHANTUDONG cho 1 điểm): trạng thái TU_DONG, rời vị trí tay | ((1 ((POINTS . 526) (CREATED . 0) (UPDATED . 3) (UNCHANGED . 1571) (DELETED . 0) (LAIDOUT . 1) (MANUAL . 0) (COST . 0.0))) [đã ẩn tọa độ]) |
| L07 | **PASS** | bố trí lại chỉ trong phạm vi (5 ID): nhãn ngoài phạm vi không đổi vị trí | (5 0) |
| L08 | **PASS** | khu dày đặc giả lập 60 điểm lưới 1,2 m: chồng lấn giảm so với vị trí 0.3.2 (KHÔNG khẳng định hết chồng lấn) | TRƯỚC (0.3.2): 160 / 160 nhãn còn chồng lấn (cặp nhãn-nhãn 1351, nhãn đè ký hiệu/điểm 123) \|\| SAU: 141 / 160 nhãn còn chồng lấn (cặp nhãn-nhãn 143, nhãn đè ký hiệu/điểm 25) \|\| lần tạo đầu: 141 / 160 nhãn còn chồng lấn (cặp nhãn-nhãn 143, nhãn đè ký hiệu/đi… |
| L09 | **PASS** | ĐIỂM RTK KHÔNG BỊ DI CHUYỂN sau mọi thao tác nhãn (526 POINT so tọa độ) | 526 điểm, lệch 0 |
| O01 | **PASS** | phát hiện điểm đã thuộc hồ sơ + bộ điểm trùng khớp hồ sơ có sẵn | ((T OBJ-T1) ((OBJ-T1) nil) ((OBJ-T1) (OBJ-T1)) (nil nil)) |
| O02 | **PASS** | tạo hồ sơ với điểm đã thuộc hồ sơ khác (không xác nhận) bị từ chối | (nil điểm đã thuộc đối tượng khác: BOT19-R-000021) |
| O03 | **PASS** | BHTDOITUONG chọn lại điểm đã có hồ sơ: mặc định (Enter) = HỦY, không tạo hồ sơ mới; M nhưng không xác nhận -> không tạo | (0 1 1) |
| O04 | **PASS** | BHTDOITUONG > T: thêm điểm đã chọn vào hồ sơ có sẵn (không tạo mới) | (BOT19-R-000020 BOT19-R-000021 BOT19-R-000023) |
| O05 | **PASS** | điểm chưa có hồ sơ -> tạo mới bình thường; M + xác nhận C -> hồ sơ mới dùng chung điểm (chủ động) | ((OBJ-T1 OBJ-T3 OBJ-T4 OBJ-T5) ((OBJ-T1 OBJ-T5) (OBJ-T5))) |
| L10 | **PASS** | chế độ ưu tiên hồ sơ: điểm thuộc hồ sơ chỉ còn nhãn TÊN; điểm khác đủ nhãn; tắt -> nhãn phụ trở lại | ((13 nil nil) (294 H = 1.728) 12 12) |
| K01 | **PASS** | BHTKYHIEU lần đầu: tạo ký hiệu cho 4 hồ sơ (+ nhãn), không đụng INSERT cùng block không có XData BHT | ((CREATED . 4) (UPDATED . 0) (UNCHANGED . 0) (REMOVED . 0) (DUPLICATES . 0) (MANUAL . 0) (NOPOS . 0) (TOTAL . 4)) |
| K02 | **PASS** | sửa hồ sơ -> cập nhật ký hiệu: giữ vị trí/góc/tỷ lệ người dùng đặt, nhãn đổi chữ nhưng giữ chỗ | ([đã ẩn tọa độ] OBJ-T1 CT-01 ((CREATED . 0) (UPDATED . 1) (UNCHANGED . 0) (REMOVED . 0) (DUPLICATES . 0) (MANUAL . 2) (NOPOS . 0) (TOTAL . 4))) |
| K03 | **PASS** | thêm điểm vào hồ sơ (ký hiệu tự động) -> ký hiệu dời tới trung bình điểm mới, cùng 1 thực thể (không xóa-vẽ lại) | ([đã ẩn tọa độ] [đã ẩn tọa độ]) |
| K04 | **PASS** | xóa hồ sơ -> chỉ ký hiệu + nhãn của hồ sơ đó bị gỡ; ký hiệu khác giữ nguyên thực thể | ((CREATED . 0) (UPDATED . 0) (UNCHANGED . 3) (REMOVED . 0) (DUPLICATES . 0) (MANUAL . 2) (NOPOS . 0) (TOTAL . 3)) |
| K05 | **PASS** | chạy lại BHTKYHIEU: không tạo / sửa / xóa gì (cập nhật theo ID, không xóa-vẽ lại) | ((CREATED . 0) (UPDATED . 0) (UNCHANGED . 3) (REMOVED . 0) (DUPLICATES . 0) (MANUAL . 2) (NOPOS . 0) (TOTAL . 3)) |
| K06 | **PASS** | trả ký hiệu OBJ-T1 về tự động: vị trí = trung bình điểm RTK, góc 0, tỷ lệ cài đặt | ([đã ẩn tọa độ] 2) |
| P01 | **PASS** | nhập 205 ảnh: 203 ký hiệu (2 ảnh GPS 0,0 không có ký hiệu) | ((VALID . 203) (INVALID . 2) (CREATED . 203) (UPDATED . 0) (KEPT . 0) (DUPLICATES . 0) (REMOVED . 0) (LABELS-CREATED . 203) (LABELS-UPDATED . 0)) |
| P02 | **PASS** | nhập lại chỉ mục ảnh: không trùng ký hiệu | ((VALID . 203) (INVALID . 2) (CREATED . 0) (UPDATED . 0) (KEPT . 203) (DUPLICATES . 0) (REMOVED . 0) (LABELS-CREATED . 0) (LABELS-UPDATED . 0)) |
| P03 | **PASS** | đồng bộ lại hệ tọa độ ảnh (đổi KTT rồi đổi lại): 203 ký hiệu dời rồi về đúng chỗ, không trùng; RTK không đổi | (203 203) |
| P04 | **PASS** | thư mục ảnh chuyển chỗ: BHTTHUMUCANH chỉ tới thư mục mới -> 205/205 JPG tìm thấy, mở đúng file | ((205 0) C:/Users/Le Bao/BHT_TEST_V033/anh_da_doi/kmz_out\photos\origin_photo_0.jpg) |
| P05 | **PASS** | chọn ký hiệu ảnh -> đúng mã ảnh để xem (mức hàm; không mở trình xem) | === Ảnh BOT19-P-000010 === |
| P06 | **PASS** | nhập / đồng bộ ảnh KHÔNG tự chèn raster hàng loạt | 0 |
| P07 | **PASS** | chèn raster 1 ảnh + đường dẫn (LINE) từ ký hiệu ảnh tới raster | ((T <Entity name: 2146acf1cd0>) <Entity name: 2146acf1d70>) |
| P08 | **PASS** | dời raster -> đường dẫn cập nhật theo | (1 0) |
| M01 | **PASS** | bản vẽ đang ở tab Layout (TILEMODE=0): điểm/nhãn/ký hiệu/ảnh/raster BHT đều tạo trong MODEL; TILEMODE trả lại như cũ | (0 Layout1 0) |
| W01 | **PASS** | nhận diện: ảnh nền kiểu IRT (layer IRT_GOOGLE, file google_sat_*) là IRT; ảnh khác (dù nằm trong thư mục tên 'irt') KHÔNG bị coi là IRT; raster BHT riêng | (1 1 2) |
| W02 | **PASS** | thứ tự hiển thị (bảng SORTENTS): nhãn > ký hiệu/POINT/ký hiệu ảnh/đường dẫn > raster BHT > ... > ảnh nền IRT dưới cùng | SORTENTS 50952 mục \| nhãn (278277.0 281118.0) giữa (277468.0 278276.0) raster (277466.0 277467.0) IRT (148.0 148.0) \| ((IRT . 1) (RASTER . 2) (MID . 793) (LABELS . 1940) (OTHER-IMAGES . 1) (XREF . 1) (OUTSIDE . 0)) |
| W03 | **PASS** | ảnh IRT và ảnh khác: dữ liệu thực thể không bị sửa (chỉ thứ tự hiển thị) |  |
| N01 | **PASS** | thực thể ngoài BHT (kể cả TEXT cùng layer, INSERT cùng block BHT_KH_*, XData app khác) không bị xóa/sửa | (49634 0 0) |
| K07 | **PASS** | BHTKT: 0 lỗi | 0 lỗi, 1 cảnh báo |

### Phiên B — mở lại bản SAVEAS 2018 của phiên A

Phiên B: A_out_mo_lai.dwg \| ACADVER=24.3 \| LISPSYS=1 \| CDATE=20260927.143403

| Mã | Kết quả | Nội dung | Chi tiết (rút gọn) |
|---|---|---|---|
| B00 | **PASS** | nạp BHT-0.3.3 trên bản vẽ đã lưu (SAVEAS 2018) | A_out_mo_lai.dwg |
| B01 | **PASS** | sau khi mở lại: số điểm, nhãn, trạng thái nhãn (tự động/tay), ký hiệu ảnh, ảnh, hồ sơ, ký hiệu, raster, đường dẫn giữ nguyên | (586 (1733 1 0) 203 (OBJ-T1 OBJ-T4 OBJ-T5) 3) |
| B02 | **PASS** | vị trí mọi nhãn giữ nguyên sau lưu / mở lại | 1734 nhãn, lệch 0 |
| B03 | **PASS** | cập nhật nhãn sau mở lại: không tạo/xóa; nhãn dời tay vẫn giữ nguyên vị trí và trạng thái TAY | (((POINTS . 586) (CREATED . 0) (UPDATED . 0) (UNCHANGED . 1733) (DELETED . 0) (LAIDOUT . 0) (MANUAL . 1) (COST . 0.0)) [đã ẩn tọa độ]) |
| B04 | **PASS** | cập nhật ký hiệu sau mở lại: không tạo trùng; ký hiệu đặt tay (OBJ-T4) giữ vị trí | (((CREATED . 0) (UPDATED . 0) (UNCHANGED . 3) (REMOVED . 0) (DUPLICATES . 0) (MANUAL . 1) (NOPOS . 0) (TOTAL . 3)) [đã ẩn tọa độ]) |
| B05 | **PASS** | thứ tự hiển thị lưu trong bản vẽ (SORTENTS) còn đúng sau mở lại | ((278277.0 281118.0) (277468.0 278276.0) (277466.0 277467.0) (148.0 148.0)) |
| B06 | **PASS** | ảnh: 205 JPG tìm thấy; đồng bộ lại không tạo trùng ký hiệu | (((TOTAL . 205) (VALID . 203) (INVALID . 2) (JPG-FOUND . 205) (JPG-MISSING . 0) (MARKERS . 203) (MARKERS-MISSING . 0) (LINKED . 0) (UNLINKED . 205))) |
| B07 | **PASS** | BHTKT sau mở lại: 0 lỗi | 0 lỗi, 1 cảnh báo |

### Phiên L — mở bản sao bản vẽ đã làm bằng BHT 0.3.2 (test_A_saveas.dwg của 0.3.2), lưu SAVEAS 2018

Phiên L: L_in.dwg \| ACADVER=24.3 \| LISPSYS=1 \| CDATE=20260927.142855

| Mã | Kết quả | Nội dung | Chi tiết (rút gọn) |
|---|---|---|---|
| L00 | **PASS** | nạp BHT-0.3.3 trên bản vẽ 0.3.2 |  |
| L01 | **PASS** | cập nhật nhãn lần đầu bằng 0.3.3: không tạo/xóa, KHÔNG dời nhãn nào (nâng cấp XData: nhãn ở vị trí mặc định -> tự động, khác -> tay) | ((POINTS . 531) (CREATED . 0) (UPDATED . 0) (UNCHANGED . 2119) (DELETED . 0) (LAIDOUT . 0) (MANUAL . 0) (COST . 0.0)) \| (tự động tay cũ)=(2119 0 0) \| nhãn bị dời 0 |
| L02 | **PASS** | điểm RTK, bản ghi hồ sơ/ảnh/dataset giữ nguyên sau khi mở + cập nhật nhãn | (0 208) |
| L03 | **PASS** | ký hiệu 0.3.2: nhận ra theo object_id, không vẽ trùng, không dời | ((CREATED . 0) (UPDATED . 1) (UNCHANGED . 0) (REMOVED . 0) (DUPLICATES . 0) (MANUAL . 0) (NOPOS . 0) (TOTAL . 1)) |
| L04 | **PASS** | ảnh 0.3.2: đồng bộ không tạo trùng ký hiệu; 205 bản ghi | (((VALID . 203) (INVALID . 2) (CREATED . 0) (UPDATED . 0) (KEPT . 203) (DUPLICATES . 0) (REMOVED . 0) (LABELS-CREATED . 0) (LABELS-UPDATED . 0)) ((TOTAL . 205) (VALID . 203) (INVALID . 2) (JPG-FOUND . 205) (JPG-MISSING . 0) (MARKERS . 203) (MARKERS-MISSING . 0… |
| L05 | **PASS** | BHTKT: phát hiện thực thể BHT nằm trong Layout (bản vẽ 0.3.2 làm khi đang ở tab Layout) và gợi ý BHTVEMODEL | 3059 thực thể \| 0 lỗi, 2 cảnh báo |
| L06 | **PASS** | BHTVEMODEL: chuyển về Model, tọa độ điểm/nhãn và XData giữ nguyên, số lượng không đổi; chỉ raster bị bỏ qua (báo chèn lại) | ((3058 1) 1 0) |
| L07 | **PASS** | sau khi chuyển: trạng thái nhãn giữ nguyên, cập nhật nhãn không tạo/xóa | ((2119 0 0) (2119 0 0)) |
| L08 | **PASS** | BHTSAPNHAN tất cả trên bản vẽ 0.3.2: chồng lấn giảm; nhãn tay (nếu có) giữ nguyên; điểm RTK không dời | TRƯỚC: 1480 / 2119 nhãn còn chồng lấn (cặp nhãn-nhãn 2153, nhãn đè ký hiệu/điểm 538) \|\| SAU: 133 / 2119 nhãn còn chồng lấn (cặp nhãn-nhãn 37, nhãn đè ký hiệu/điểm 77) \| nhãn tay 0 |
| L09 | **PASS** | BHTTHUTUVE trên bản vẽ 0.3.2 (sau khi chuyển về Model): nhãn nằm trên ký hiệu/điểm | (((IRT . 0) (RASTER . 0) (MID . 735) (LABELS . 2323) (OTHER-IMAGES . 0) (XREF . 1) (OUTSIDE . 1)) (284288.0 286610.0) (283553.0 284287.0)) |
| L10 | **PASS** | BHTKT sau nâng cấp: 0 lỗi | 0 lỗi, 2 cảnh báo |

### Phiên L2 — mở lại bản vẽ 0.3.2 đã nâng cấp ở phiên L

Phiên L2: L_out_mo_lai.dwg \| ACADVER=24.3 \| LISPSYS=1 \| CDATE=20260927.143410

| Mã | Kết quả | Nội dung | Chi tiết (rút gọn) |
|---|---|---|---|
| L2-01 | **PASS** | mở lại bản vẽ 0.3.2 đã nâng cấp (SAVEAS 2018): điểm, nhãn (vị trí + trạng thái), ảnh, hồ sơ, bản ghi giữ nguyên; tất cả trong Model | (531 (2119 0 0) 0 1) |
| L2-02 | **PASS** | BHTKT: 0 lỗi | 0 lỗi, 2 cảnh báo |

### Phiên R — hồi quy: chạy lại nguyên kịch bản hồi quy của 0.3.2 (0.2.0/0.3.1) trên 0.3.3

Phiên R: R_in.dwg \| ACADVER=24.3 \| LISPSYS=1 \| CDATE=20260927.143456

| Mã | Kết quả | Nội dung | Chi tiết (rút gọn) |
|---|---|---|---|
| A01 | **PASS** | nạp BHT 0.3.3 từ đường dẫn có dấu | 0.3.3 |
| A02 | **PASS** | BHTTEST hàm thuần | 42 pass, 0 fail |
| A03 | **PASS** | nhập 526 điểm lần đầu | ((ADDED . 526) (SAME . 0) (CONFLICT . 0) (DUPCONTENT . 0) (ADOPTED . 0) (INVALID . 0) (DUPFILE . 0)) |
| A04 | **PASS** | nhập lại cùng dataset không tạo trùng | ((ADDED . 0) (SAME . 526) (CONFLICT . 0) (DUPCONTENT . 0) (ADOPTED . 0) (INVALID . 0) (DUPFILE . 0)) |
| A05 | **PASS** | cùng CSV dưới dataset khác bị chặn (trùng nội dung) | ((ADDED . 0) (SAME . 0) (CONFLICT . 0) (DUPCONTENT . 526) (ADOPTED . 0) (INVALID . 0) (DUPFILE . 0)) |
| A06 | **PASS** | dòng thay đổi = xung đột, không ghi đè | ((ADDED . 0) (SAME . 525) (CONFLICT . 1) (DUPCONTENT . 0) (ADOPTED . 0) (INVALID . 0) (DUPFILE . 0)) |
| A07 | **PASS** | 526 điểm, X=Đông Y=Bắc Z, ID theo dòng | 526 điểm; P1 XYZ=[đã ẩn tọa độ]; P5 Z=[đã ẩn tọa độ] |
| A08 | **PASS** | 526/526 điểm giữ nguyên chuỗi gốc + tọa độ | sai lệch 0 |
| A09 | **PASS** | tiếng Việt/dấu phẩy/ngoặc kép/mô tả dài/dòng lỗi/nhận điểm v0.1 | ((ADDED . 2) (SAME . 0) (CONFLICT . 0) (DUPCONTENT . 0) (ADOPTED . 1) (INVALID . 1) (DUPFILE . 0)) \| VN1 desc=[biển "cấm", đỗ xe] len VN5=423 VN4=[bb.cn,phan,lan] ent1=<Entity name: 1b3d1fc2340> leg1=<Entity name: 1b3d1fc2340> eqlong=T |
| A10 | **PASS** | nâng cấp v0.1: gán ID điểm cũ + tạo hồ sơ từ BHT_ASSET | (1 1) pt=(VN-R-000001) |
| A11 | **PASS** | hồ sơ đối tượng: nhiều điểm, số trụ/mặt tách riêng, chặn trùng ID/điểm/thiếu điểm | ID OBJ-BANG đã tồn tại / điểm đã thuộc đối tượng khác: BOT19-R-000035 / không tìm thấy điểm: KHONG-CO |
| A12 | **PASS** | 205 ảnh (203 GPS + 2 ảnh 0,0 được giữ), nhập lại không trùng, vị trí chụp | ((ADDED . 205) (SAME . 0) (CONFLICT . 0) (INVALID . 0) (VALIDGPS . 203) (INVALIDGPS . 2) (SYNC (VALID . 203) (INVALID . 2) (CREATED . 203) (UPDATED . 0) (KEPT . 0) (DUPLICATES . 0) (REMOVED . 0) (LABELS-CREATED . 203) (LABELS-UPDATED . 0))) \| P1 E,N=[đã ẩn tọa độ] |
| A13 | **PASS** | ghép ảnh chỉ tạo đề xuất, không tự liên kết | ((SUGGESTED . 93) (AMBIGUOUS . 74) (NONE . 36) (SKIPPED . 2)) |
| A14 | **PASS** | gắn tay ảnh GPS 0,0; hai chiều đồng bộ; từ chối đối tượng không có | không có đối tượng KHONG-CO |
| A15 | **PASS** | duyệt đề xuất điểm lẻ -> tạo đối tượng mới + liên kết | BOT19-P-000001 -> P:BOT19-R-000514 |
| A16a | **PASS** | từ chối proxy TDT làm tuyến | 146 proxy; đối tượng proxy/TDT (ACAD_PROXY_ENTITY) - KHÔNG dùng để tính lý trình. Hãy xuất/vẽ Polyline tham chiếu thường. |
| A16b | **PASS** | từ chối LINE; nhận LWPOLYLINE | loại LINE không được hỗ trợ; chỉ nhận LWPOLYLINE/POLYLINE thường. |
| A16c | **PASS** | tuyến chưa có mốc -> Km chưa xác định | CHUA_CO_MOC |
| A16d | **PASS** | nội suy giữa mốc + phía trái | ((STATUS . NOI_SUY) (STATION . 39250.0) (OFFSET . 10.0) (SIDE . TRAI) (ROUTE . TUYEN1) (DIST . 250.0) (RATIO . 1.0) (LOAI . TIM_DUONG) (NOTE . nội suy giữa mốc Km39+000.00 và Km39+500.00, hệ số 1.00000)) |
| A16e | **PASS** | không nội suy xuyên điểm gãy Km + phía phải | ((STATUS . NOI_SUY) (STATION . 39850.0) (OFFSET . 5.0) (SIDE . PHAI) (ROUTE . TUYEN1) (DIST . 750.0) (RATIO . 1.0) (LOAI . TIM_DUONG) (NOTE . nội suy giữa mốc Km39+600.00 và Km40+100.00, hệ số 1.00000)) |
| A16f | **PASS** | ngoài phạm vi mốc -> chưa xác định; xa tuyến -> XA_TUYEN | CHUA_XAC_DINH / XA_TUYEN |
| A16g | **PASS** | chặn 2 mốc cùng vị trí | đã có mốc tại vị trí này (xóa mốc cũ trước) |
| A17 | **PASS** | lưu lý trình/offset/nguồn Km vào hồ sơ đối tượng | (3 4) \| RT1 Km39+250.00 nội suy giữa mốc Km39+000.00 và Km39+500.00, hệ số 1.00000 |
| A18 | **PASS** | nạp 15 đoạn / 3 gói từ bảng xlsx | 15 đoạn; DOAN02=An Thạnh - cầu Rạch Nổ |
| A19 | **PASS** | phân đoạn theo Km+phía; chồng lấn -> NHIEU_DOAN; gán tay được giữ | A=T B=T C=T ((AUTO . 3) (AMBIGUOUS . 0) (OUTSIDE . 0) (UNDETERMINED . 4) (MANUAL . 0)) |
| A20 | **PASS** | vẽ ký hiệu, vẽ lại không nhân đôi | đối tượng=7 ký hiệu=7 |
| A21 | **PASS** | xuất 4 file CSV; tổng hợp đếm mỗi đối tượng 1 lần | ((TOTAL-OBJECTS . 7) (SUMMARY . 8) (PHOTOS . 205) (OBJECTS . 7) (POINTS . 534)) |
| A22 | **PASS** | BHTKT: 0 lỗi; phát hiện điểm bị dịch; hết lỗi khi trả lại | lỗi 0/1/0, cảnh báo 4 |
| A23 | **PASS** | chạy lệnh không tương tác BHT/BHTTEST/BHTKT/BHTLYTRINH | nil |

## Chưa kiểm / cần nghiệm thu tay

| Mục | Trạng thái | Lý do |
|---|---|---|
| Bảng DCL `BHT` (mở, bấm nút) | BLOCKED | Core Console không có DCL. Đã kiểm tĩnh mẫu DCL (S0-T03) |
| Chọn điểm / ký hiệu bằng chuột (`BHTDOITUONG`, `BHTKYHIEU` > R, `BHTSAPNHAN` > V, `BHTNHANTUDONG`, `BHTCHENANH` > C) | SKIP | Không chọn tương tác được. Logic phía sau đã kiểm qua hàm; `BHTDOITUONG` kiểm với câu trả lời giả lập |
| Trình xem ảnh Windows | SKIP | Không có giao diện; chỉ kiểm giải đường dẫn JPG (A-P04, A-P05) |
| Hiển thị thứ tự vẽ trên màn hình | SKIP | Chỉ kiểm bảng SORTENTS (A-W02, B-B05, L-L09) |
| Giải nén KMZ 349 MB (`BHTKMZ`) | SKIP (không chạy lại) | Mã không đổi so với 0.3.2 (đã kiểm ở 0.3.2, phiên C) |

## Tệp chứng cứ

`tests/evidence/`:
- `result_*.txt`: kết quả từng mục;
- `test_*.console.txt`: nhật ký Core Console, mã UTF-16;
- `state_A.txt`, `state_L.txt`: trạng thái trước khi lưu, dùng để so ở phiên mở lại;
- `day_dac.csv`: dữ liệu giả khu dày;
- `static_check.txt`.

Cách chạy lại: `tests/README_TESTS.md`.
