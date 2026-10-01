# BHT 0.4.6-fix2 — ghi chú phát hành

Bản sửa lỗi của 0.4.6 (kèm bộ cài đã sửa ở 0.4.6-fix1).

## Sửa lỗi

- `BHTTUYENTDT` (Palette › Tuyến › “1. Lấy hoặc cập nhật tim từ TDT 9.1”) không còn báo
  `BHT lỗi: no function definition: FBOUNDP`. Lệnh tự nạp `BHT.Bridge.dll` cạnh file Lisp nếu cần.
- Tim TDT 9.1 tách thành nhiều đoạn khi Explode được nối thành một Polyline tham chiếu.
- Tiêu đề Palette hiện đúng `BHT 0.4.6-fix2`.

## Giao diện

- Bảng màu xanh lá `#065F46` / `#D1FAE5` (nền chung `#047857`).
- Nút “Dấu X 1u + sắp nhãn” đổi tên thành “Đặt dấu X (cỡ 1) + sắp lại nhãn”.

## Cài đặt

Đóng tất cả AutoCAD, chạy `INSTALL_BHT.cmd`. Bộ cài thay `BHT.bundle` 0.4.6 bằng 0.4.6-fix2
(cùng ProductCode/UpgradeCode). Lần đầu mở Palette sau khi cài, kiểm tra tiêu đề hiện `0.4.6-fix2`.
