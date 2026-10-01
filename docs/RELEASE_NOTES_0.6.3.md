# BHT 0.6.3 — 01/10/2026

Palette chỉ mở khi gọi BTH/BHT, đóng hoặc đổi bản vẽ thì ngắt timer/theo dõi dữ liệu. Lisp không tự NETLOAD giao diện; bundle đăng ký lệnh để người dùng gọi. Di động: APPLOAD, BHTLOAD, BTH.

Tô màu biển là lựa chọn theo DWG, nằm cạnh Chèn biển tự do; bật/tắt cập nhật các biển BHT đang có, áp dụng cả biển chèn sau, không đổi Hatch ngoài BHT. API không tự tạo ký hiệu cho hồ sơ chưa chèn. Các lựa chọn riêng từng hồ sơ cũ giữ trong dữ liệu nhưng không dùng.

Nhãn ở dưới và giữa khung block, góc bằng biển, kể cả waypoint/góc lớn hơn 90°. Cỡ chữ 15% chiều cao toàn block, khoảng cách dưới 8%, áp dụng tỉ lệ INSERT. Đã bỏ ô cỡ nhãn. Nhãn biển cũ bố trí lại khi đồng bộ. VNRomancUpdate.shx/Unicode giữ nguyên.

Tiêu đề hồ sơ mới ngắn; gợi ý phân nhóm chuyển tooltip. “Cho phép dùng chung điểm RTK” cho phép tạo thêm hồ sơ dùng điểm đã thuộc hồ sơ khác, vẫn hỏi xác nhận, giữ hồ sơ cũ.

Kiểm thử:
- Build ba DLL 0.6.3.0; Core 127 PASS, 0 FAIL.
- CAD Core Console SIGN/native font/free placement/global fill/layout: đạt; WinForms picker/con lăn/tìm kiếm/nhiều mặt: đạt.
- Offline không TDT/native text: đạt.
- REVIEW 10, S0 20, V5 21 PASS. Phát hiện và sửa gọi BHTSIGNBOUNDS chưa đăng ký trong đường fallback Lisp. TX bị chặn vì thiếu bản vẽ proxy mẫu.
- AutoCAD thật: đọc được Start với Palette 0.6.2 đang tự khôi phục. Chưa kiểm chứng thao tác GUI 0.6.3: capture FrameArrived timeout, click báo coordinate input geometry is unavailable. Không có số đo giảm lag.
- TDT có chuỗi lựa chọn dưới biển/cao chữ/tỉ lệ block; chưa xác nhận trị số mặc định. Tỷ lệ BHT nêu trên chưa được nghiệm thu tương đương TDT.

Đóng AutoCAD trước khi cài gói mới; mở lại và gọi BTH/BHT. Không dùng DLL mới trong phiên đã nạp DLL cũ.
