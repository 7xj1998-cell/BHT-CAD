# BHT 0.6.35 — Xoay đầu biển hàng loạt

Đã thêm lệnh `BHTHUONGBIEN` và nút **Xoay đồng loạt đầu biển theo hướng…** ở tab **Tuyến & báo cáo**.

- `T`: đầu biển bám chiều A→B tại từng vị trí trên tuyến; áp dụng cả hai bên đường và tuyến cong. Dùng `BHTROUTESTART` để chọn lại đầu tuyến/chiều nếu cần.
- `H`: chọn hai điểm A, B để tất cả biển cùng hướng đầu A→B. B phía trên A sẽ cho biển đứng hướng lên trên.
- `A`: tất cả biển phù hợp; `C`: chọn nhóm ký hiệu/nhãn/dấu gốc/điểm RTK trên CAD. Chỉ tác động hồ sơ biển đã đặt.

Giữ điểm chèn, tỷ lệ, tọa độ RTK và điểm gấp khúc; cập nhật nhãn và nối đường dẫn vào chân sau khi xoay. Hướng lưu trong DWG, giữ khi cập nhật. Một lệnh `U` hoàn tác cả lần xoay. Hồ sơ bị bỏ qua được báo theo ID.

Đã kèm các thay đổi 0.6.34 chưa bàn giao riêng: khôi phục 47 biển phụ, chọn đầu tuyến ngay khi tạo từ PL thường hoặc TDT 9.1, thêm dấu tròn đặc tại tâm X để còn thấy khi ẩn điểm. Các bản bàn giao trước được lưu trong thư mục **Old**.

Giữ CAP1 2D, nhập nội dung/số/giờ theo hồ sơ và chế độ bỏ riêng nền, giữ biểu tượng/viền. Xem [hướng dẫn](HUONG_DAN.md) và [kết quả kiểm tra](QA_0.6.35.md).
