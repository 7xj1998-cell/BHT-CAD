# BHT 0.6.14 — 07/10/2026

Đã sửa bán kính tìm ảnh/điểm trên Palette bị cắt phần thập phân. Giá trị 0,5 m hoặc 2,5 m được giữ đúng; giá trị không hợp lệ dùng mặc định 10 m.

Đã chặn kích thước chia chuỗi bằng 0 hoặc âm, tránh lặp vô hạn. Phép chiếu điểm lên tuyến giữ các đoạn ngắn khác 0 và tính đủ chiều dài tích luỹ. Tên cache block TDT trong Lisp đã đồng bộ với Bridge để nhận đúng block của hình học hiện tại.

Đã bỏ 5 hàm Lisp nội bộ và 1 hàm Palette không còn được tham chiếu trong mã, bộ kiểm thử hoặc tài liệu. Nhật ký thay đổi trùng ở đầu mã Lisp đã rút gọn; các ghi chú giải thích quy tắc dữ liệu và hành vi AutoCAD được giữ lại.

Kiểm tra đã đạt:

- Build đầy đủ Core, Bridge và Palette cho AutoCAD 2024; 166 kiểm thử Core, 0 lỗi.
- Kiểm thử biển, đặt ký hiệu, UCS xoay, huỷ thao tác, bảo toàn điểm RTK và Unicode/TCVN trong AutoCAD Core Console.
- Kiểm thử bộ chọn biển và tuỳ chọn đặt ký hiệu.
- 7 kiểm tra bộ cài: gói hợp lệ, sửa file, thiếu file, file ngoài manifest, đường dẫn vượt phạm vi, sao lưu và khôi phục khi thay thế thất bại.

Một số kỳ vọng cũ của bộ kiểm thử đã cập nhật theo thay đổi có sẵn từ 0.6.13: tên block V0613, kích thước lớn nhất của biển phụ và hatch đỏ trên biểu tượng. Việc cập nhật không thay đổi tài nguyên TDT gốc.

Chưa kiểm thử toàn bộ thao tác trong phiên AutoCAD giao diện đang mở. Kết quả trên không xác nhận mọi mục thư viện TDT đều có nguồn CAD hoặc hình vẽ đạt yêu cầu.

Cài đặt: lưu bản vẽ, đóng AutoCAD, giải nén đầy đủ BHT-0.6.14.zip rồi chạy INSTALL_BHT.cmd. Mở lại AutoCAD, gõ BHT hoặc BTH; tiêu đề Palette hiển thị 0.6.14.