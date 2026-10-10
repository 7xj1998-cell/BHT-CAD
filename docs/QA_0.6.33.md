# Kiểm tra BHT 0.6.33

Đã build trên Windows x64 với .NET Framework và AutoCAD 2024 Core Console. Phiên bản Lisp/DLL/bundle đồng bộ 0.6.33 / 0.6.33.0. Kiểm tra trong đợt này gồm:

- Core: 233 PASS, 0 FAIL; số thập phân, đơn vị, giờ qua đêm, giới hạn tốc độ/chữ số lý trình, XML và CAP1.
- In trắng đen: 2.118 PASS trên 467 mẫu. Chỉ ẩn hatch nền; giữ hình học hatch biểu tượng, vùng trắng và nguồn màu. Viền tròn/tam giác/chữ nhật giữ đầy đủ; kiểm tra riêng viền không tô lấn vào giữa biển.
- Nội dung: 1.008 PASS trên toàn danh mục. Phát hiện 323 trường ở 125 mặt: 133 số, 9 giờ và 181 văn bản, ngoài các ô chuyên biệt. Đã thay từng giá trị trên CAD, kiểm tra XML và giữ mẫu nguồn. Bao gồm cả 19 mẫu có số trong TEXT/MTEXT.
- CAP1: 60 kiểm tra CAD và 6 kiểm tra RTK/Lisp; đủ mặt/chân, khoảng cách đáy, không chồng hình, nội dung riêng và nối chân sau xoay/di chuyển.
- Thư viện: 2.832 kiểm tra nạp nguồn, số entity, vòng hatch, thứ tự vẽ, tỷ lệ và bỏ nền. Hồi quy Lisp, TCVN3, UCS, đặt G/T, nâng cấp, xóa và hai chân đạt.
- Giao diện: 166 kiểm tra đạt; nhập số thập phân, từ chối sai đơn vị/giờ, lưu giờ qua đêm, bộ lọc cao tốc và nội dung/CAP1. Picker trong AutoCAD đạt.
- Kiểm tra bảo vệ bộ cài: 7 ca trong thư mục thử riêng; chặn nội dung bị đổi, thiếu file, file thực thi ngoài manifest và đường dẫn thoát gói; sao lưu/rollback đạt.

Đã đối chiếu 467 cặp hình màu/bỏ nền trên 8 bảng ảnh. Các mẫu được kiểm tra kỹ gồm W.207, R.415, I.448, biển tốc độ theo làn, biển cao tốc nhiều ô và biển cấm có vòng/gạch chéo ghép chung hatch. Xem [ảnh so sánh](BO_NEN_VIEN_0.6.33.png).

Ảnh so sánh được dựng từ DXF xuất bởi AutoCAD; không thay thế Plot Preview với CTB/STB của hồ sơ. Bật in lineweight để dùng nét khung 0,25 mm. Nội dung dài được thu hẹp theo ô mẫu; cần kiểm tra độ rõ ở tỷ lệ in thực tế. Địa danh nhập theo hồ sơ. CAP1 là bố trí trình bày 2D, chưa tính kết cấu/móng hoặc tự đối chiếu hồ sơ ngoài.
