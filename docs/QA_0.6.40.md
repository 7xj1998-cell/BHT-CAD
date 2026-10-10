# Kiểm tra 0.6.40 — 10/10/2026

- Tái hiện lỗi trên DLL 0.6.39: khi đặt layer tuyến làm layer hiện hành, ShowRoute ném eInvalidLayer tại LayerTableRecord.set_IsFrozen. Cùng bài kiểm thử đạt trên 0.6.40.
- Core: 233 PASS. Bảng tuyến/zoom: 16 PASS trên bản sao đầy đủ 15doan, gồm current layer, layer tắt/đóng băng, entity ẩn trên layer khóa, giữ khóa và layer hiện hành, khung nhìn xoay, tuyến mất hình học và vòng đời highlight.
- Xoay hàng loạt: 25 PASS. Đặt riêng: 7 kiểm tra mới PASS sau 16 kiểm tra nền, gồm hồ sơ chưa liên kết tuyến, tiếp tuyến đông/bắc, hủy đặt không thay đổi, ngoài khoảng cho phép không thay đổi, block tự chọn trục X, cập nhật sau đảo tuyến và giữ RTK.
- Kiểm thử AutoCAD CoreConsole riêng; chưa nạp DLL mới vào phiên CAD người dùng. Không chỉnh tim TDT hoặc đường PL đang mở.
- Giao diện và nội dung: 665 kiểm tra PASS, gồm lựa chọn đặt theo tuyến phát đúng ROUTE_PERP và nhãn Vuông góc với tuyến.
