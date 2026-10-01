# BHT 0.4.6-fix3 — ghi chú phát hành

Bản sửa lỗi tiếp theo 0.4.6-fix2 (giữ bảng màu xanh, bộ cài fix1).

## Giao diện Palette

- Thanh thẻ dọc bên phải có tên thẻ: **Tổng quan**, **Điểm RTK**, **Ảnh hiện trường**, **Hồ sơ đối tượng**,
  **Tuyến & báo cáo** (trước đây là ô trống). Rê chuột lên thẻ để xem mô tả.
- Khi lệnh gửi từ Palette báo lỗi, vùng trạng thái hiện “Lệnh … THẤT BẠI.” trên nền đỏ nhạt.

## Thông báo lỗi

- Lỗi / cảnh báo cần xử lý hiện cửa sổ **BHT** và vẫn in ở dòng lệnh. Hủy lệnh (Esc) không hiện cửa sổ.
- Tắt cửa sổ: `(setq *bht-popup* nil)`. Script `.scr` và Core Console không bao giờ hiện cửa sổ.
- Tim TDT dạng proxy: thông báo hướng dẫn mở lại AutoCAD bằng biểu tượng/profile TDTSolution 9.1
  (cắm khóa USB TDT nếu phần mềm yêu cầu) rồi chạy lại bước 1.

## Cài đặt

Đóng tất cả AutoCAD, chạy `INSTALL_BHT.cmd`. Bộ cài thay `BHT.bundle` cũ bằng 0.4.6-fix3
(cùng ProductCode/UpgradeCode). Mở Palette (`BTH`), kiểm tra tiêu đề hiện `BHT 0.4.6-fix3`.
