# BHT 0.6.40

## 0.6.40 — 10/10/2026

- Sửa lỗi eInvalidLayer ở Hiển thị / zoom tuyến khi tuyến nằm trên layer hiện hành. Chỉ bật/tan băng layer khi cần; giữ layer hiện hành và trạng thái khóa. Làm sáng sau khi kết thúc transaction và Regen.
- Sửa Đặt tự do: thay lựa chọn Theo tuyến bằng Vuông góc với tuyến, dùng tiếp tuyến tại điểm RTK và chiều tuyến A→B; thống nhất với xoay hàng loạt. Nếu chưa liên kết tuyến, hỏi chọn tuyến. Thiếu hình học hoặc quá xa tuyến sẽ báo lỗi và giữ biển cũ, không tự trả góc 0°.
- Lưu liên kết hướng tuyến để Chèn / cập nhật tiếp tục giữ hướng vuông góc. Giữ quy ước block thư viện và block tự chọn; vị trí RTK không thay đổi.
Đóng AutoCAD và cài bản mới để nạp DLL 0.6.40. Vào Hồ sơ đối tượng → Đặt ký hiệu → Đặt tự do → Hướng ký hiệu: **Vuông góc với tuyến**. Chọn tuyến nếu được hỏi, sau đó đặt vị trí biển. Hướng đầu biển vuông góc về bên trái chiều A→B; đảo chiều tuyến để đổi phía.

Các biển đã đặt trước đó không tự xoay ngay khi cài. Để sửa cả nhóm, vào Tuyến & báo cáo → Xoay biển vuông góc với hướng… (`BHTHUONGBIEN`), chọn tuyến và phạm vi biển cần áp dụng. Tuyến tham chiếu phải đúng hình học thực tế để hướng xoay có ý nghĩa.