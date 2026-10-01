# Xử lý review BHT v0.5.3 trong v0.5.4

Ngày 01/10/2026. Đối chiếu report `BHT_053_REVIEW.md` của Claude với các biểu thức AutoLISP cấp ngoài cùng và kiểm thử trên AutoCAD 2024 Core Console. Bản report gốc giữ nguyên.

| Nhận xét trong report | Kết quả đối chiếu và xử lý |
| --- | --- |
| Bảng TCVN lặp ba lần | 266 mục gồm 134 chữ NFC và 132 biến thể ghép dấu NFD. Rút gọn dữ liệu bằng chuỗi chữ, danh sách mã và bước chuẩn hóa NFC; giữ đủ các đầu vào cũ. Bảy chữ Ă Â Ê Ô Ơ Ư Đ có mã hoa riêng, không được gộp vào mã thường. |
| NFC chỉ cần 62 cặp | Giữ toàn bộ 178 cặp cũ, gồm chữ hoa/thường và chữ có dấu ngoài tiếng Việt. Gom theo chữ cơ sở, sinh bảng khi nạp. Bổ sung xử lý chữ đã ghép một phần như ê + dấu sắc → ế và Â + dấu nặng → Ậ, cùng thứ tự dấu kết hợp đảo. |
| BHTKIEUDIEM dài 381 dòng | Biểu thức lệnh thực tế chỉ 13 dòng; các hàm nhãn phía sau là các defun độc lập. Không xóa hoặc di chuyển engine chỉ vì phép đếm sai. |
| BHTNHAPTSV/BHTNK dài 562 dòng | Lệnh NHAPTSV chỉ 7 dòng, alias NK chỉ 1 dòng. Thêm phân cách rõ giữa các lệnh nhập và engine nhãn tiếp theo. |
| Gộp các lệnh nhãn | BHTNHANDIEM đã có A/H/S/R. Đưa ẩn/hiện vào helper chung, để menu và BHTANNHAN cùng dùng một cách xử lý. Giữ lệnh sắp/reset và alias cũ để các script, Palette và thói quen người dùng tiếp tục hoạt động. |
| Gộp các lệnh hồ sơ đối tượng | BHTDOITUONG đã có menu X/S/T/M. Giữ các lệnh trực tiếp và toàn bộ 69 tên lệnh hiện có; xóa alias không khắc phục lỗi nghiệp vụ. |
| Khó kiểm tra thứ tự điểm trung gian | Tách so sánh XY/thứ tự đỉnh/cao độ của đường dẫn thành helper. Kiểm thử đảo hai điểm, kiểm tra bản ghi và đỉnh LWPOLYLINE thực tế, đồng bộ lặp không phát sinh thay đổi. |
| ID không tồn tại khi chèn tự do | Xác nhận trả LOI ở Lisp và cầu nối, không ghi thêm hồ sơ/entity. Chuẩn hóa cả ID nil/rỗng để tránh lỗi kiểu dữ liệu. Kiểm tra hồ sơ không có điểm RTK cũng trả LOI. |
| Gộp setq để giảm dòng | Không thay hàng loạt biểu thức chỉ vì thẩm mỹ; ưu tiên dữ liệu bảng mã và các helper có thể kiểm chứng tương đương. |

Lisp giảm từ 7.314 xuống 6.938 dòng (376 dòng, khoảng 5,1%; tính bằng splitlines). Dung lượng UTF-8 từ 357.928 xuống 353.641 byte. Không tuyên bố tăng tốc chạy chỉ dựa trên số dòng. Bảng kỳ vọng kiểm thử lấy từ dữ liệu v0.5.3, độc lập với cách sinh bảng mới.

## Xác minh

- Core/Bridge/Palette build thành công, DLL 0.5.4.0; 122 kiểm tra Core đạt.
- 28 kiểm tra Lisp ký hiệu đạt; 29 kiểm tra phông đạt, trong đó có kiểm tra đầy đủ 266 đầu vào TCVN và 178 cặp NFC cũ.
- 3 kiểm tra chèn tự do tương tác đạt: hủy không ghi hồ sơ, thêm/xóa điểm trung gian, góc UCS 45° + 30° → WCS 75°.
- 4 kiểm tra menu nhãn/alias đạt: A ẩn, alias hiện, H hiện, giữ dữ liệu RTK.
- Probe thư viện DWG đạt cho P.127-80/P.127-40/I.434a/R.415/W.207c, kiểm tra chiều cao và Hatch.
- WinForms picker có 412 thẻ/292 thumbnail; tìm kiếm, lọc nhóm, xem trước, tốc độ, nhiều mặt, sắp thứ tự và hủy đều đạt.

Đây là kiểm thử tự động trong bản vẽ/profile riêng. Chưa cài v0.5.4 vào phiên AutoCAD người dùng đang mở; thao tác chuột trong phiên làm việc thực tế vẫn cần nghiệm thu sau khi cài.
