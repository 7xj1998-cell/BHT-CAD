# BHT 0.4.0 — Danh sách nghiệm thu thủ công (AutoCAD 2024 đầy đủ)

Các mục dưới đây **chưa kiểm được trong AutoCAD Core Console**: Core Console không có giao diện, hộp thoại DCL, không chọn đối tượng bằng chuột, không có trình xem ảnh, không hiển thị. Phần dữ liệu phía sau các lệnh này đã được kiểm bằng Core Console (xem TEST_REPORT.md).

Làm trên **bản sao** bản vẽ, với `LISPSYS = 1`. Mỗi mục ghi Đạt / Không đạt và ghi chú.

## A. Nạp và bảng điều khiển

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| A1 | `APPLOAD` → `BHT-0.4.0.lsp` | Dòng lệnh hiện `BHT 0.4.0 đã nạp thành công.` | |
| A2 | Gõ `BHT` | Bảng mở, chữ tiếng Việt đúng, có dòng "Phiên bản 0.4.0", có 42 nút | |
| A3 | Kiểm tra nút theo từng bước | "Nhập CSV RTK (mặc định)" ở bước 1; "Nhập TSV (trao đổi)"; bước 2 có "Sắp xếp nhãn" và "Trả nhãn về tự động"; bước 7 có "Sắp thứ tự hiển thị"; nhóm **Bảo trì dữ liệu cũ** có "Nâng cấp dữ liệu V0.1" và "Chuyển BHT từ Layout về Model" | |
| A4 | Bấm lần lượt từng nút | Mỗi nút chạy đúng lệnh; xong lệnh thì bảng mở lại | |

## B. Nhãn điểm RTK

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| B1 | Mở **bản sao** bản vẽ đã làm bằng 0.3.2 (có 526 điểm và nhãn), nạp 0.4.0, gõ `BHTNHANDIEM` rồi Enter | Không nhãn nào bị dời; không có nhãn trùng; điểm RTK đứng yên | |
| B2 | `BHTSAPNHAN` → `V`, quét vùng có nhiều điểm | Nhãn trong vùng được sắp lại; lệnh báo chồng lấn trước / sau; nhãn ngoài vùng giữ nguyên; **điểm không di chuyển** | |
| B3 | Kéo tay (grip) một nhãn tên sang chỗ khác, rồi `BHTNHANDIEM` → `C` đổi cao chữ | Nhãn vừa kéo giữ đúng chỗ, chỉ đổi cỡ chữ; `BHTINFO` trên điểm ghi "(dời tay)" | |
| B4 | `BHTSAPNHAN` → `T` | Nhãn dời tay ở B3 vẫn giữ nguyên | |
| B5 | `BHTNHANTUDONG`, chọn điểm ở B3 | Nhãn quay về vị trí tự động | |
| B6 | `BHTNHANDIEM` → `4` (ưu tiên hồ sơ) trên bản vẽ có hồ sơ | Điểm thuộc hồ sơ chỉ còn nhãn tên; bấm `4` lần nữa thì nhãn phụ trở lại | |
| B7 | Mở bản vẽ, **đang ở tab Layout**, gõ `BHTNHAP` nhập vài điểm | Điểm và nhãn nằm trong **Model**, không nằm trên giấy Layout | |

## C. Hồ sơ đối tượng và ký hiệu

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| C1 | `BHTDOITUONG`, chọn điểm cọc tiêu chưa thuộc hồ sơ, nhập ID / nhóm / số trụ / tình trạng | Hồ sơ được tạo; lệnh hỏi "Chèn ký hiệu … ngay? [C/K]"; trả lời C thì ký hiệu xuất hiện | |
| C2 | `BHTDOITUONG` chọn lại đúng điểm đó | Hiện tóm tắt hồ sơ có sẵn và cảnh báo "bộ điểm TRÙNG KHỚP"; bấm **Enter** thì không tạo hồ sơ mới | |
| C3 | Làm lại C2, chọn `X`, rồi `S`, rồi `T` (chọn thêm 1 điểm) | X: hiện hồ sơ. S: sửa trường. T: điểm được thêm vào hồ sơ có sẵn, ký hiệu dời theo | |
| C4 | Làm lại C2, chọn `M` rồi trả lời `K` | Không tạo hồ sơ; trả lời `C` thì tạo hồ sơ mới dùng chung điểm; `BHTKT` cảnh báo điểm dùng chung | |
| C5 | Kéo, xoay ký hiệu của một hồ sơ; `BHTSUADT` đổi mã hiệu | Ký hiệu giữ vị trí / góc; nhãn ký hiệu đổi chữ | |
| C6 | `BHTKYHIEU` → Enter hai lần | Lần 2 báo "tạo 0, cập nhật 0"; ký hiệu không nhân đôi | |
| C7 | `BHTXOADT` một hồ sơ, rồi `BHTKYHIEU` | Chỉ ký hiệu của hồ sơ đó mất; các ký hiệu khác và các block người dùng tự chèn không bị động | |
| C8 | `BHTKYHIEU` → `R`, chọn ký hiệu đã kéo ở C5 | Ký hiệu về vị trí tự động | |

## D. Thứ tự hiển thị

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| D1 | Bản vẽ có ảnh nền IRT (vệ tinh), raster BHT, nhãn, ký hiệu. Gõ `BHTTHUTUVE` | Nhãn nằm trên cùng, rồi ký hiệu / điểm, rồi raster BHT; ảnh nền IRT dưới cùng; lệnh báo số ảnh IRT nhận diện được | |
| D2 | Nếu tile IRT không được nhận ra (báo "ảnh IMAGE không nhận diện chắc chắn") | Chọn 1 tile, gõ `LIST`: ghi lại **layer** và **đường dẫn file** (dòng "Image file" / "Saved path"). Gõ `BHTTHUTUVE` → `C`, thêm mẫu layer / thư mục / tên file phù hợp; chạy lại thì cả lưới tile xuống dưới. **Gửi lại layer + đường dẫn tile thật** | |
| D4 | Bản vẽ có lưới nhiều tile IRT (vài trăm IMAGE) | `BHTTHUTUVE` chạy xong trong vài giây, báo đúng số tile; raster ảnh BHT KHÔNG bị tính là IRT | |
| D3 | Kiểm tra ảnh IRT sau D1 | Ảnh IRT không bị sửa, không bị xóa, không đổi vị trí | |

## E. Ảnh

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| E1 | `BHTANHNAP` lại cùng `BHT_PHOTO.tsv` | Không có ký hiệu ảnh trùng | |
| E2 | `BHTXEMANH`, chọn ký hiệu ảnh | Trình xem ảnh Windows mở đúng JPG | |
| E3 | `BHTCHENANH`, chọn 1 ký hiệu, rộng 8, đường dẫn = C | Raster hiện cạnh vị trí chụp, có đường thẳng nối từ ký hiệu ảnh tới raster | |
| E4 | Kéo raster sang chỗ khác, `BHTDONGBOANH` | Đường dẫn đi theo raster | |
| E5 | `BHTCHENANH` → `X` gỡ raster | Raster và đường dẫn mất; bản ghi ảnh và JPG còn nguyên | |
| E6 | Chép thư mục ảnh sang chỗ khác, `BHTTHUMUCANH` chỉ tới thư mục mới | Báo 205 tìm thấy; `BHTXEMANH` mở ảnh ở thư mục mới | |

## F. Bản vẽ cũ

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| F1 | Mở bản sao bản vẽ thật đã làm bằng 0.3.2, gõ `BHTKT` | 0 lỗi. Nếu có cảnh báo "thực thể BHT nằm trong Layout" thì làm F2 | |
| F2 | `BHTVEMODEL` → `C` | Thực thể BHT về Model, tọa độ không đổi; `BHTKT` hết cảnh báo đó (trừ raster: gỡ và chèn lại) | |
| F3 | Lưu, đóng, mở lại, `BHTTRANGTHAI` | Số liệu như trước khi đóng | |

## P. Palette .NET (BHT.Palette.dll) — CHƯA kiểm được trong Core Console (không có giao diện)

Chuẩn bị: bản sao bản vẽ có 526 điểm + 205 ảnh + vài hồ sơ; `APPLOAD BHT-0.4.0.lsp`; Unblock 3 DLL; `NETLOAD BHT.Palette.dll`.

| # | Việc | Kết quả mong đợi | Đạt? |
|---|---|---|---|
| P1 | `NETLOAD` → `BHT.Palette.dll` | Báo `BHT.Palette 0.4.0.1 đã nạp…`; không lỗi; không hỏi nạp DLL Autodesk | |
| P2 | `BHTPALETTE` lần đầu | Palette "BHT — QUẢN LÝ HIỆN TRẠNG TUYẾN" gắn bên TRÁI, chữ tiếng Việt đúng, 5 thẻ A–E | |
| P3 | Kéo rộng/hẹp, kéo ra nổi, gắn lại; đóng AutoCAD, mở lại, NETLOAD, `BHTPALETTE` | Kích thước / vị trí được nhớ; `BHTPALETTE` lần nữa thì ẩn/hiện | |
| P4 | Thẻ A | Số điểm RTK (526) và số hồ sơ tách riêng; 205 ảnh; số đã ghép / chưa ghép; cảnh báo giống `BHTKT` | |
| P5 | Thẻ B: gõ tìm "coc tieu" (không dấu), chọn 1 dòng | Danh sách lọc đúng; bản vẽ phóng tới điểm, điểm được chọn; **không** nhảy lặp / nhấp nháy | |
| P6 | Trong bản vẽ bấm chọn 1 POINT RTK | Thẻ B hiện tên, mô tả gốc, X/Y/Z đúng như `BHTINFO`, hồ sơ liên kết, ảnh liên quan | |
| P7 | Chọn nhanh nhiều đối tượng liên tục / quét chọn cả vùng | AutoCAD không treo, palette không lặp sự kiện; cập nhật sau ~0,3 s | |
| P8 | Thẻ C: mở ảnh, bấm trước/sau | JPG hiện trong palette; trạng thái GPS (2 ảnh GPS 0,0 báo "không có GPS", không đặt ở gốc tọa độ) | |
| P9 | Bấm 1 ký hiệu ảnh (tam giác) trong bản vẽ | Thẻ C nhảy tới đúng ảnh đó | |
| P10 | Thẻ C: xem điểm RTK gần, chọn hồ sơ, bấm Ghép | Chỉ ghép khi bấm xác nhận; không có gì được chọn sẵn; `BHTINFO` hồ sơ thấy ảnh | |
| P11 | Thẻ D: chọn 1 POINT cọc tiêu, "Tạo từ điểm đang chọn" | Nhóm gợi ý COC_TIEU kèm căn cứ (mô tả); nhập số trụ / tình trạng / ghi chú, Lưu → hồ sơ mới; palette vẫn mở | |
| P12 | Lặp lại P11 với cùng điểm | Báo điểm đã thuộc hồ sơ …, mặc định **Hủy**; chỉ tạo khi tích dùng chung + xác nhận lần 2 | |
| P13 | "Chèn/Cập nhật ký hiệu" | Ký hiệu hồ sơ được chèn/cập nhật (như `BHTKYHIEU`), không tạo trùng; đối tượng không phải BHT không bị đụng | |
| P14 | Đang giữa một lệnh (vd đang `LINE`), bấm Lưu / Ghép / Thêm điểm trên palette | Palette từ chối, báo đang có lệnh; không lỗi *eLockViolation*, không mất dữ liệu | |
| P15 | Thẻ E: bấm từng nút | Lệnh Lisp tương ứng chạy ở dòng lệnh; xong lệnh palette báo "đã kết thúc - đã đọc lại dữ liệu" | |
| P16 | Mở 2 bản vẽ, chuyển qua lại | Palette đổi dữ liệu theo bản vẽ hiện hành; chọn trong bản vẽ kia không làm lỗi | |
| P17 | Đóng bản vẽ đang hiển thị trên palette | Palette về trạng thái trống / bản vẽ còn lại, AutoCAD không lỗi | |
| P18 | Palette đang có tiêu điểm (con trỏ ở ô tìm), gõ lệnh vào dòng lệnh / nhấn Esc | Không mất phím; không kẹt tiêu điểm; không vòng lặp chọn | |
| P19 | Chưa `APPLOAD` Lisp, chỉ NETLOAD rồi mở palette | Palette báo "Lisp BHT 0.4.0 CHƯA nạp", các nút ký hiệu/nhãn/kiểm tra bị khóa; đọc dữ liệu vẫn được | |
| P20 | Sửa hồ sơ trên palette → `BHTINFO` trong Lisp; sửa bằng Lisp (`BHTSUADT`) → palette | Hai bên thấy cùng dữ liệu (palette tự làm mới) | |
| P21 | Lưu, đóng, mở lại bản vẽ | Hồ sơ / ảnh tạo từ palette còn nguyên | |
