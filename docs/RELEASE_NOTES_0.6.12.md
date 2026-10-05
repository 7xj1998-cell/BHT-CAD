# BHT 0.6.12

Chọn biển QCVN qua **Thư viện biển**. Với I.439, nhập tên cầu, lý trình ghi trên biển và tên đường ngay trong cửa sổ chọn biển. Hồ sơ đối tượng đã bỏ ba ô nhập trùng; dữ liệu cũ vẫn được giữ khi mở/sửa/lưu.

Lý trình ghi trên mặt biển là nội dung biển, có thể khác lý trình vị trí hồ sơ. Cọc Km/H đã biết số vẫn tự ghi lý trình khi lưu, không cần nhập tay thêm.

Khi chưa có tim tuyến, có thể dựng Polyline tham chiếu theo hướng tuyến rồi khai báo các mốc Km đã xác nhận bằng BHTMOCKM. BHT tính theo đường tham chiếu đó; độ chính xác phụ thuộc đường vẽ và các mốc. Bản này chưa tự dựng tuyến từ cọc hoặc tự suy ra thứ tự cọc.

Đóng AutoCAD trước khi chạy INSTALL_BHT.cmd. Phiên CAD đang mở vẫn dùng DLL đã nạp trước đó; cần mở lại để dùng 0.6.12.

Đã đạt 154 kiểm tra lõi, 39 kiểm tra hình học, các kiểm tra Lisp biển/hướng cọc và thử giao diện thư viện với 378 ảnh. Palette được kiểm tra trong môi trường AutoCAD trên bản sao 15doan.dwg; test trực tiếp phiên GUI đang mở qua MCP chưa hoàn tất vì kết nối trỏ sang Drawing1.dwg.