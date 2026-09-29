# Checklist nghiệm thu thủ công BHT 0.4.6

Thực hiện trên bản sao DWG, không dùng file khảo sát gốc.

## Cài đặt và giao diện

- [ ] Đóng AutoCAD, chạy `INSTALL_BHT.cmd`, mở AutoCAD 2024 và gõ `BTH`.
- [ ] Tiêu đề hiện **BHT 0.4.6**; APPLOAD di động báo `BHT 0.4.6 đã nạp thành công.`
- [ ] Palette có nền than–xanh; nút chữ vàng, thông tin cyan và trạng thái dễ đọc.
- [ ] Năm thẻ nằm dọc sát mép phải; chữ không cắt khi thu hẹp hoặc kéo rộng Palette.
- [ ] Các nhãn biểu mẫu nằm bên trái, ô nhập và danh sách kéo đến gần mép phải.
- [ ] Vùng trạng thái dưới cùng không nhận con trỏ nhập.
- [ ] `BHTDCL` mở được giao diện dự phòng, tiếng Việt đúng dấu và 42 nút hoạt động.

## Điểm và nhãn

- [ ] POINT RTK là dấu X 1 unit, tâm trùng DXF 10.
- [ ] Bản vẽ mới tạo kiểu `BHT_RTK`; tên, mô tả và cao độ thẳng hàng theo cụm.
- [ ] Mở DWG 0.3.2/0.4.5 rồi cập nhật nhãn: font và vị trí nhãn cũ không tự đổi.
- [ ] Chụp X/Y/Z trước và sau `BHTSAPNHAN`; tọa độ không đổi, không bị làm tròn.
- [ ] Nhãn dời tay vẫn giữ vị trí sau cập nhật và SAVEAS/mở lại.

## TDT, biển báo và báo cáo

- [ ] Khởi động profile TDT 9.1 bản thường từ `C:\Program Files (x86)\TDT Solution 2022\`.
- [ ] `BHTTUYENTDT` tạo/cập nhật Polyline `BHT_TUYEN_TDT` mà không sửa tim TDT nguồn.
- [ ] Gợi ý biển hiện `Mã — Tên biển`; block TDT có tỷ lệ và leader đúng.
- [ ] Báo cáo `.xlsx` mở trong Excel, đủ tiếng Việt và hai sheet tổng hợp/danh sách.
- [ ] `BHTKT` báo 0 lỗi; ghi lại mọi cảnh báo còn lại.
