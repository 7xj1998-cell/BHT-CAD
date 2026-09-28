# Rà soát block BHT 0.4.4

Ngày rà soát: 2026-09-28

## 1. Ảnh KMZ của tuyến

Nguồn kiểm tra là KMZ `Workspace của Bảo Lê.kmz`, gồm 205 vị trí và 205 ảnh. Toàn bộ ảnh được chia thành 11 contact sheet để xem thủ công. Các nhóm biển xuất hiện nhiều hoặc có ý nghĩa trực tiếp với hồ sơ tuyến gồm:

| Nhóm nhận diện | Số lần quan sát gần đúng | Block BHT 0.4.4 |
|---|---:|---|
| W.207, giao với đường không ưu tiên | 19 | `BHT_KH_BB_W207_V044` |
| R.412, phân làn theo phương tiện | 8 | `BHT_KH_BB_R412_V044` |
| W.239a + S.509a, cáp điện và chiều cao an toàn | 7 | `BHT_KH_BB_W239A_V044` |
| W.245a, đi chậm | 5 | `BHT_KH_BB_W245A_V044` |
| I.414, chỉ hướng đường | 5 | `BHT_KH_BB_I414_V044` |
| W.209, tín hiệu đèn | 3 | `BHT_KH_BB_W209_V044` |
| I.428a, cửa hàng xăng dầu | 3 | `BHT_KH_BB_I428A_V044` |
| Các biển còn lại nhìn rõ trong ảnh | rải rác | W.201, W.225, I.423a, I.434a, P.115, P.119, P.124a, P.125 và P.127 |

Các con số trên dùng để quyết định thứ tự ưu tiên dựng block, không phải thống kê nghiệm thu biển báo. Ảnh bị che, chụp xiên hoặc có nhiều biển ghép được xem cùng vị trí thực địa trước khi gán mã.

## 2. Kiểm tra thư viện TDT trên máy

Máy đang kiểm tra không có thư mục cài đặt mang đúng tên `TDT Solution 9.1`. Hai bản được phát hiện là `TDT Solution 2022` và `TDT Solution 7.1`; thư viện biển báo nằm trong:

`C:\Program Files (x86)\TDT Solution 2022\Data\Bien bao`

Kết quả đọc chỉ mục:

- `Bienbao.xml`: 412 dòng danh mục và mô tả tiếng Việt.
- 297 ảnh BMP xem trước.
- `bienbao.set`: container phiên bản 1, sáu mục; năm mục có dữ liệu DWG `AC1021`, một mục rỗng.
- Năm DWG chứa 329 định nghĩa block có mã: 65 biển cấm, 83 biển cảnh báo, 64 biển hiệu lệnh, 90 biển chỉ dẫn và 27 biển phụ.
- Các block thường gặp W.207A, W.209, W.239, W.245A, R.412A, I.423A, I.428, I.434A, P.115, P.119, P.124A, P.125 và P.127 đều đọc được bằng AutoCAD 2024.
- Hình học bên trong dùng các thực thể AutoCAD thông thường như `LINE`, `LWPOLYLINE`, `POLYLINE`, `CIRCLE`, `ARC`, `SPLINE`, `HATCH`, `TEXT` và `ATTDEF`; không cần đối tượng TDT để hiển thị hình học của các block đã kiểm.

Script [audit_tdt_library.ps1](../scripts/audit_tdt_library.ps1) tách bản sao năm DWG vào `build/tdt-library-audit/extracted` và tạo `tdt_bien_bao_catalog.csv` UTF-8 BOM. Script chỉ đọc thư mục cài đặt. Các DWG/BMP của TDT không được đưa vào gói BHT.

Thư viện này có thể dùng làm nguồn block cục bộ, nhưng chưa nên sao chép nguyên gói vào bản vẽ BHT: một số biển dùng `ATTDEF` để nhập trị số; các bảng chỉ hướng dùng nhiều thuộc tính; kiểu chữ `Giaothong1/Giaothong2` cần đường dẫn support của TDT; điểm chèn và kích thước chưa đồng nhất với quy ước BHT. Quy trình nhập sau này phải tách từng block, đổi tên, đưa điểm chèn về chân cột, chuẩn hóa đơn vị, thay thuộc tính động bằng dữ liệu hồ sơ và loại bỏ phụ thuộc font.

## 3. Kết luận cho BHT 0.4.4

BHT 0.4.4 giữ 19 block tự chứa trong một file Lisp để chạy được cả khi máy không cài TDT. TDT là nguồn đối chiếu và nguồn DWG tùy chọn trên máy có bản quyền. Người dùng có thể `WBLOCK` một ký hiệu cần dùng từ TDT rồi nạp bằng `BHTBLOCK`; BHT lưu đường dẫn nguồn và hệ số đơn vị nhưng không sửa DWG gốc.

Mọi block tích hợp có điểm chèn tại chân cột `(0,0)`, không có `ATTDEF`, text có chiều cao dương và không có đoạn thẳng dài 0. Mã không nhận diện dùng block tổng quát. Hồ sơ `BIEN_BAO` tự chọn block từ trường `ma_hieu`; `BHTBBDANHMUC` hiển thị danh mục đang hỗ trợ.

Xem nhanh hình học trong [ảnh gallery](BLOCK_GALLERY_0.4.4.png) hoặc mở [bản vẽ gallery](BLOCK_GALLERY_0.4.4.dwg) bằng AutoCAD.
