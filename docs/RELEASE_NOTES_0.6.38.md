# BHT 0.6.38

## 0.6.38 — 10/10/2026

- Chọn một dòng trong Dữ liệu tuyến để chọn và làm sáng hình học tương ứng trên CAD. Đổi dòng, đổi tab hoặc đóng bản vẽ sẽ bỏ làm sáng tuyến cũ. Hiển thị / zoom tuyến vẫn mở lớp ẩn và thu toàn bộ tuyến vào khung nhìn.
- Thêm Sửa tuyến, Chọn lại tuyến và Xóa tuyến ngay dưới bảng. Sửa được ID, loại tuyến, khoảng cách tối đa và phạm vi ngoại suy. Đổi ID cập nhật cả liên kết lý trình và hướng biển.
- Các nút điểm đầu, đảo chiều, đọc cọc, thêm/xóa mốc và chẩn đoán dùng tuyến đang chọn trong bảng.
- Xóa chỉ bỏ khai báo và liên kết tuyến; giữ Polyline, RTK và hướng biển hiện tại. Thay Polyline giữ đường cũ nhưng bỏ mốc Km và thông tin nguồn TDT cũ để tránh tính lý trình theo sai hình học. Sửa/xóa có thể Undo.
- Chặn tạo tuyến trùng ID và ngoại suy âm, gồm cả luồng nhập TDT. Đổi tên chỉ ghi lại hồ sơ liên quan; sửa thuộc tính không quét lại điểm RTK.

## Quản lý tuyến 0.6.38

Mở **Tuyến & báo cáo → Dữ liệu tuyến**. Bấm vào dòng để chọn và làm sáng tuyến trên CAD; nhấp đúp hoặc bấm **Hiển thị / zoom tuyến** để nhìn toàn tuyến.

- **Sửa tuyến…** (`BHTSUATUYEN`): đổi ID, loại, khoảng cách tối đa và ngoại suy. Nhập tại dòng lệnh CAD; Enter giữ giá trị cũ. Sau đó chạy Cập nhật lý trình.
- **Chọn lại tuyến…** (`BHTCHONLAITUYEN`): chọn Polyline thay thế, xác nhận C rồi chọn điểm đầu/chiều tuyến. Mốc Km cũ bị bỏ; cần nạp lại mốc trước khi tính lý trình. Tim TDT gốc dùng Lấy / cập nhật tim từ TDT 9.1.
- **Xóa tuyến…** (`BHTXOATUYEN`): xác nhận C để bỏ khai báo; Enter/K hủy. Giữ đường vẽ, điểm RTK và góc biển. Các hồ sơ liên quan chuyển sang chưa có tuyến. Undo khôi phục thao tác.

Khi có nhiều tuyến, các nút điểm đầu, đảo chiều và mốc Km dùng dòng đang chọn. Không chọn dòng thì lệnh sẽ hỏi ID tuyến như trước. Cập nhật lý trình vẫn chạy trên toàn bộ hồ sơ theo cơ chế chọn tuyến hiện có.

Đóng tất cả AutoCAD trước khi cài 0.6.38, sau đó mở lại để nạp DLL mới. Không NETLOAD chồng DLL mới vào phiên đã nạp BHT cũ.