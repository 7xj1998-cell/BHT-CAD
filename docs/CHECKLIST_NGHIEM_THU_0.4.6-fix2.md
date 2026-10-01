# Checklist nghiệm thu thủ công BHT 0.4.6-fix2 (AutoCAD 2024 đầy đủ, trên BẢN SAO DWG)

AutoCAD Core Console không có giao diện nên các mục sau phải kiểm tra bằng mắt.

## Palette (gõ `BTH`)

- [ ] Tiêu đề Palette: `BHT 0.4.6-fix2 — QUẢN LÝ HIỆN TRẠNG TUYẾN` (không còn 0.4.4).
- [ ] Dòng trạng thái: `BHT Lisp 0.4.6-fix2 đã nạp`; thẻ Tổng quan: `PLUGIN: BHT.Palette 0.4.6.2`.
- [ ] Nền Palette xanh lá `#047857`; không còn nền đen/than.
- [ ] Nút: nền `#065F46`, chữ `#D1FAE5`, viền sáng; rê chuột đậm hơn.
- [ ] Thanh thẻ dọc bên phải: thẻ thường nền `#065F46` chữ sáng; thẻ đang chọn nền `#D1FAE5` chữ `#065F46`; không còn ô đen, không còn mục xanh dương.
- [ ] Danh sách RTK / Hồ sơ: nền `#D1FAE5`, chữ `#065F46`, tiêu đề cột nền `#065F46` chữ sáng, dòng chọn nền `#065F46` chữ sáng.
- [ ] Danh sách ảnh, điểm, ảnh của hồ sơ: dòng chọn nền `#065F46` chữ sáng.
- [ ] Ô thông tin (chỉ đọc) nền `#D1FAE5`; ô nhập nền `#ECFDF5`; chữ `#065F46`.
- [ ] Hộp chọn (combo) và ô đánh dấu “Hiện công cụ nâng cao” đọc rõ.
- [ ] Dòng TDT ở thẻ Tuyến đọc rõ trên nền xanh.
- [ ] Vùng trạng thái: bình thường nền `#D1FAE5`; lỗi nền đỏ nhạt; cảnh báo nền vàng nhạt.
- [ ] Bố cục (vị trí, kích thước nút, thứ tự thẻ) như 0.4.6.
- [ ] Thẻ RTK có nút “Đặt dấu X (cỡ 1) + sắp lại nhãn”; bấm: PDMODE=3, PDSIZE=1, nhãn được sắp lại, POINT không di chuyển.

## Tim TDT 9.1 (mở AutoCAD bằng profile TDT 9.1, cắm khóa)

- [ ] Thẻ Tuyến › “1. Lấy hoặc cập nhật tim từ TDT 9.1” › chọn tim TDT: không còn `no function definition: FBOUNDP`.
- [ ] Tạo Polyline xanh trên layer `BHT_TUYEN_TDT` trùng toàn bộ tim (không chỉ một đoạn).
- [ ] Tim TDT gốc không bị sửa (UNDO/so sánh thuộc tính), điểm RTK không di chuyển.
- [ ] Chạy lại lệnh trên cùng tim: thông báo “đã cập nhật”, không tạo tuyến trùng.
- [ ] Chọn Polyline thường: thông báo “không phải tim tuyến TDTSolution 9.1”.
