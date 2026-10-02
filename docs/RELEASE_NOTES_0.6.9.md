# BHT v0.6.9 — 2026-10-02

Đã sửa lỗi mất mũi tên khi chọn chiều tuyến và không đọc được cọc nằm trong đối tượng TDT.

## Thay đổi

- Mũi tên vàng có đầu đặc được giữ trong bước xác nhận và khi REGEN; dọn hình khi chấp nhận, hủy hoặc lỗi. Hiển thị được tại hai đầu tuyến và khi UCS xoay.
- Bộ đọc nhận nhãn Km trong đối tượng TDT gốc, block lồng nhau và từng thuộc tính. Nhãn trùng được loại bỏ; tuyến nguồn chỉ được mở để đọc.
- Khi nhận diện được vạch cọc TDT trên tim, BHT dùng vị trí vạch thay cho vị trí chữ. Điều này tránh sai lệch khoảng 0,75 m trên bản vẽ đã kiểm tra.
- Đã sửa lỗi `eDegenerateGeometry` khi cập nhật lại Polyline tham chiếu có cung, giữ nguyên handle và không tạo tuyến trùng.
- Đã chặn lý trình sai như `Km1+1000` bị đọc thành `Km1+100`.

## Kiểm tra

- AutoCAD 2024 Core Console với module TDT gốc: v0.6.8 đọc 0 cọc trên bản sao tuyến thực tế; v0.6.9 đọc đủ 371 cọc, từ Km0+000 đến Km4+538,98.
- 20 kiểm tra tuyến/cọc/mũi tên và 10 kiểm tra bộ đọc đạt. Giữ hai cảnh báo để xét duyệt; ca thử nạp 369 mốc hợp lệ và không tạo trùng khi nạp lại.
- Lưu và mở lại giữ đủ 371 cọc đọc được, 369 mốc đã nạp và handle tham chiếu. Đối tượng nguồn không đổi sau quét và đổi chiều; tệp bản vẽ gốc được đối chiếu SHA256.
- 139 kiểm tra Core đạt. Hồi quy REVIEW: 10, S0: 20, V5: 21, R5: 12 ca đạt.
- Kiểm tra biển báo, Unicode/TCVN3, cụm nhiều mặt qua API Palette và bộ chọn WinForms đạt; 376 mã có ảnh, không thiếu ảnh.
- Kiểm tra tự động dùng AutoCAD Core Console; chưa xác nhận toàn bộ thao tác chuột trên Palette với DLL phát hành cuối.

## Cài đặt và thử lại

1. Lưu công việc đang mở và đóng toàn bộ AutoCAD.
2. Giải nén đầy đủ `BHT-0.6.9.zip`, chạy `INSTALL_BHT.cmd`.
3. Mở bản vẽ bằng profile TDT 9.1 và kiểm tra bảng BHT hiển thị 0.6.9.
4. Trong **Tuyến & báo cáo**, chọn **Lấy / cập nhật tim từ TDT 9.1**, rồi **Chọn điểm đầu và chiều tuyến**.
5. Chọn **Đọc / kiểm tra cọc TDT**, xem cảnh báo trước khi xác nhận nạp Station Control.

DLL đã nạp không được thay trực tiếp trong phiên CAD đang mở; cần đóng và mở lại sau khi cài.
