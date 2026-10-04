# BHT 0.6.11

Bản sửa hướng ký hiệu, mẫu biển tên cầu và cách nhập lý trình cọc.

- **Chọn hướng trên CAD:** đầu đỏ cọc tiêu/cọc Km và mặt biển chỉ về phía đã chọn; hỗ trợ UCS xoay, không phụ thuộc ANGBASE/ANGDIR. Nhập góc WCS giữ ý nghĩa góc quay block.
- **I.439:** dùng lại hình mẫu TDT cũ, gồm khung đôi, nền xanh, phông Giaothong1 và chân trụ. Nội dung vẫn sửa được; dòng dưới có dạng KM38+723-ĐT.830. Viền trắng giữ màu khi in.
- **Cọc Km:** điểm chèn nằm giữa thanh đen ở đuôi, có hoặc không ghi số Km. Không có nhãn ngoài block.
- **Cọc tiêu:** chưa có lý trình thì không hiện nhãn chung; cọc có số Km/H vẫn hiện H9/39.
- **Lý trình:** nhập Km 46, H 1 tự ghi Km46+100 khi lưu, không cần nhập tay thêm. Cọc Km 39 tự ghi Km39+000. Nguồn lý trình được ghi rõ; liên kết RTK, ảnh và tuyến được giữ.

Đóng AutoCAD trước khi chạy INSTALL_BHT.cmd. Trong Hồ sơ đối tượng, bấm Lưu rồi Chèn/Cập nhật ký hiệu để áp dụng cho các ký hiệu cũ. Nếu hồ sơ hoặc nhóm đã gán block riêng, mẫu riêng vẫn được ưu tiên; bỏ gán để dùng mẫu BHT mặc định.

Bản phát hành được kiểm tra dữ liệu, giao diện thư viện, AutoCAD Core Console 2024 trên bản sao bản vẽ, lưu/mở lại DWG và xuất PDF bằng bộ in AutoCAD. Kết quả chi tiết ở docs/QA_0.6.11.md.
