# BHT 5.0 — cập nhật biển báo ngày 01/10/2026

Đã sửa trong mã nguồn `BHT-CAD-0.4.1`. Gói cập nhật có đủ ba DLL và Lisp BHT-5.0.

## Các thay đổi

1. Đẩy Hatch xuống dưới nét và chữ, xử lý cả block lồng nhau. Giữ thứ tự tương đối giữa các Hatch để bảo toàn lớp màu nền và hình biểu tượng.
2. Chuẩn hóa mặt biển TDT theo chiều cao bounding box: 1,8 đơn vị CAD, giữ tỷ lệ dài/rộng; đặt đáy mặt biển trên trụ cao 0,6 đơn vị. Bản vẽ dùng mét tương ứng mặt biển cao 1,8 m. `kh_scale` vẫn là hệ số phóng toàn bộ ký hiệu.
3. Hỗ trợ `P.127-40`, `P.127-60`, `P.127-80`, `P.127-100`, `P.127-120`… Số trong mã được ưu tiên; nếu mã là `P.127` thì đọc mô tả `gioihan80`, `giới hạn 80`, `tốc độ: 80`. Đổi cả Text và Attribute số trong bản clone riêng, không sửa nguồn TDT hay biến thể khác. Không có số được khai báo thì giữ giá trị mặc định của TDT.
4. Thêm ô **Block tùy chỉnh**, nút **Chọn block CAD**, nút **Bỏ gán**. Bấm Lưu để gán vào riêng hồ sơ. Có thể chọn tên block hiện có từ danh sách. Thứ tự ưu tiên: block riêng của hồ sơ → block tùy chỉnh chung theo nhóm → thư viện. Liên kết ảnh thực địa tiếp tục được giữ khi cập nhật hồ sơ; bấm ảnh trong hồ sơ để mở đúng ảnh đã gắn.
5. Nút **Thư viện block** mở `SignPickerForm`: tìm mã/tên có hoặc không dấu, lọc năm nhóm, nhấp đúp để chọn. Tự điền mã và tên biển; giữ mô tả khảo sát cũ bằng cách ghép thêm tên biển. Thư viện trên máy có 412 mục, trong đó 292 mục khớp file BMP; mục thiếu ảnh hiện “Chưa có ảnh TDT”. Không thay bằng ảnh của một biến thể khác. Lệnh BHTBLOCK vẫn có trong phần công cụ nâng cao.
6. Biển báo, cọc tiêu và cột Km tính góc theo tiếp tuyến và chiều tăng lý trình V5: phải +90°, trái -90°. Cọc giữ đúng vị trí RTK. Không có tuyến thì dùng góc 0. Ký hiệu được xoay/di chuyển/phóng thủ công tiếp tục giữ phép biến đổi của người dùng khi đồng bộ.

## Sử dụng bản cập nhật

- Đóng AutoCAD để dỡ các DLL cũ, giải nén gói cập nhật và dùng bộ cài đi kèm như bản BHT 5.0 hiện tại.
- Mở lại bản vẽ, nạp BHT-5.0.lsp nếu chưa tự nạp; mở BTH/BHT.
- Chọn hồ sơ, bấm **Chèn/Cập nhật ký hiệu**, hoặc chạy BHTKYHIEU để cập nhật hàng loạt.
- Các wrapper mới dùng tên `BHT_TDT_V51_…` để không tái sử dụng định nghĩa cũ bị lỗi. Block cũ được giữ trong DWG; đồng bộ thay tham chiếu có XData BHT_KH sang định nghĩa mới.
- Để xoay tự động, hồ sơ phải có tuyến và hướng tuyến đúng. Phép biến đổi đã sửa tay được giữ theo cơ chế V5 hiện có.
- Block tự vẽ dùng kích thước gốc của định nghĩa block, nhân `kh_scale`; chuẩn hóa 1,8 chỉ áp dụng mặt biển từ TDT.

## Kết quả kiểm tra

- Biên dịch .NET Framework 4.8 / AutoCAD 2024: Core, Bridge, Palette thành công.
- CoreTests: 115 PASS, 0 FAIL, gồm nhận tốc độ có dấu/không dấu, ưu tiên mã nhập, không nhầm kích thước khảo sát, lưu/xóa block riêng và bảo toàn ảnh.
- Core Console với DWG thật của TDT: P.127-40, P.127-80, P.127 mặc định, I.434a, R.415, W.207c nạp thành công; chiều cao mặt biển = 1,8; Hatch nằm dưới nét/chữ. Text/Attribute tốc độ là đúng 40 và 80, các biến thể tồn tại độc lập.
- 13 kiểm tra Lisp: trái/phải, đảo hướng tuyến, cọc không dịch khỏi RTK, không tuyến, ưu tiên/lưu block riêng, nhận mô tả tốc độ, đồng bộ lặp không tạo bản trùng và giữ góc sửa tay: đều PASS.
- Kiểm tra WinForms: tạo 412 thẻ, nạp 292 thumbnail, tìm tốc độ và lọc nhóm thành công. Đã render ảnh hộp chọn để kiểm tra bố cục.
- Chưa thao tác chọn block/nhấp đúp thư viện trong phiên AutoCAD tương tác đang dùng của người dùng.

Chạy lại kiểm tra: `tests/IntegrationTests/run_signs.ps1 -AcadDir "D:\AutoCAD 2024"`.
Bản sao các file trước khi sửa nằm ở `build/backup-signs-20261001`.
