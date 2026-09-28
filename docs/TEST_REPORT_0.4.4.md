# Báo cáo kiểm thử BHT 0.4.4

Ngày kiểm thử: 2026-09-28
AutoCAD Core Console: 2024 (`ACADVER=24.3`)
Hệ Lisp: `LISPSYS=1`

## Kết quả

- Logic thuần .NET: **59 PASS, 0 FAIL**.
- Hồi quy Lisp / DWG / cầu nối .NET: **169 PASS, 0 FAIL, 1 BLOCKED**.
- Tổng kiểm thử tự động đạt: **228 PASS, 0 FAIL**.
- Mục BLOCKED là cửa sổ DCL trong AutoCAD Core Console; môi trường này không có giao diện. Cấu trúc DCL, 42 nút và hàm đích vẫn được kiểm tra tĩnh.

## Phạm vi đã xác nhận

- Nạp Lisp 0.4.4 từ đường dẫn có dấu; phiên bản Lisp, Core, Bridge và Palette cùng là 0.4.4.
- Tạo đủ 19 block biển báo trong một file Lisp; ánh xạ đúng mã và biến thể từ W.207, W.209, W.239, W.245, R.412, I.414, I.423, I.428, I.434 và nhóm P.
- Block biển báo không có `ATTDEF`, text âm/rỗng hoặc `LINE` dài 0; hồ sơ `BIEN_BAO` tự chọn block theo `ma_hieu`.
- Gallery DWG/PNG được tạo bằng chính Lisp phát hành và mở được trong AutoCAD Core Console.
- Script kiểm tra TDT tách đúng năm DWG `AC1021`, tạo danh mục 412 biển và CSV UTF-8 BOM giữ tiếng Việt có dấu.
- 526 điểm RTK giữ nguyên tọa độ X/Y/Z; 1.574 nhãn tự động còn 0 chồng lấn trong bộ dữ liệu thật.
- Nhập 205 ảnh, tạo 203 ký hiệu GPS hợp lệ, không chèn raster hàng loạt và không tạo ký hiệu trùng.
- Mở/lưu lại bản vẽ, đọc bản vẽ BHT 0.3.2/0.3.3, tuyến/lý trình, thứ tự hiển thị và cầu nối C# đều qua hồi quy.
- Block Cọc tiêu/Cột Km, nhãn `Cọc tiêu Km 48+500`, bộ đệm thông báo Palette và CSV tiếng Việt tiếp tục qua hồi quy.

## Giới hạn kiểm thử

Core Console không kiểm tra được thao tác chuột và cửa sổ Palette/DCL thật. Tài sản vector của TDT chỉ được kiểm tra từ bản cài đặt cục bộ và không nằm trong gói phát hành BHT. Bản phát hành dùng block BHT tự chứa; block TDT tùy chọn cần được người dùng xuất bằng `WBLOCK` rồi nạp qua `BHTBLOCK`.
