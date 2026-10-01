# Xử lý review bỏ DCL — BHT v0.5.5

Ngày 01/10/2026. Nguồn review: [review-remove-dcl.md](review-remove-dcl.md), nhắm vào v0.5.4. Giữ nguyên bản review để đối chiếu.

| Phạm vi review | Kết quả |
| --- | --- |
| Xóa giao diện DCL | Bỏ helper DCL, bảng nút và các lệnh BHTDCL/BHTUITEST. Palette .NET tiếp tục là giao diện chính. |
| Giữ bỏ dấu tiếng Việt | Giữ nguyên bht:fold-vi, dời lên cạnh bht:search-fold. Tìm biển không dấu và nhập tình trạng vẫn hoạt động. |
| Giữ trạng thái | Giữ bht:status-data, bht:stv, bht:status-notes, bht:status-lines và BHTTRANGTHAI. Kiểm tra lệnh trên bản vẽ trống và dữ liệu RTK không bị thay đổi. |
| Cập nhật thông báo | BHTHELP, BHTLOAD và thông báo lúc nạp không hướng dẫn gọi DCL. Khi Palette chưa nạp được, hướng dẫn kiểm tra DLL và thử lại. |
| Kiểm tra sau xóa | Cập nhật test S0/R, thêm test_REVIEW và runner dùng profile riêng; chạy lại SIGN/TCVN, S0, V5 và WinForms picker. |

## Các phụ thuộc report chưa liệt kê

- BHTTEST có gọi bht:ui-fill-line trong phần tự kiểm tra. Bỏ kiểm tra điền nhãn DCL, giữ kiểm tra bỏ dấu tìm kiếm; nếu bỏ qua chỗ này thì BHTTEST sẽ gọi hàm đã xóa.
- S0 vẫn kỳ vọng 16 hàm API trong khi phiên bản hiện hành có 17, gồm bht:api-sign-free. Cập nhật kỳ vọng theo danh sách đăng ký thật.
- V5 vẫn kỳ vọng chữ có dấu dùng Arial, trái với thay đổi đã được người dùng yêu cầu từ v0.5.2. Cập nhật kiểm tra dùng kiểu Unicode được chọn cho cả nhãn biển/cọc tiêu và kiểm tra chữ Cọc tiêu giữ nguyên.
- Hướng dẫn README/cài đặt/sử dụng còn quảng bá DCL; cập nhật để khớp bản phát hành. Tài liệu lịch sử và review gốc vẫn giữ nội dung cũ.

Lisp từ 6.938 xuống 6.684 dòng, giảm 254 dòng. Lệnh người dùng từ 69 xuống 67, chỉ bỏ hai lệnh DCL; các lệnh nghiệp vụ/alias khác giữ nguyên. Không thay thuật toán biển báo, nhãn, tuyến hoặc dữ liệu bản vẽ.

## Kết quả kiểm tra

- Build Core/Bridge/Palette DLL 0.5.5.0 thành công; 122 kiểm tra Core đạt.
- REVIEW: 10 PASS, 0 FAIL. Tự kiểm tra BHTTEST: 46 PASS, 0 FAIL.
- S0: 20 PASS, 0 FAIL. V5: 21 PASS, 0 FAIL.
- SIGN: 28 kiểm tra ký hiệu và 7 kiểm tra tương tác/menu nhãn đạt; TCVN: 29 kiểm tra phông đạt.
- Probe DWG kiểm tra Hatch, chiều cao và biến thể tốc độ đạt; WinForms picker 412 thẻ/292 thumbnail, chọn tốc độ/nhiều mặt/sắp thứ tự/hủy đạt.
- Kiểm tra metadata, chặn tái phát hành nội dung đổi dưới cùng phiên bản và chặn hạ phiên bản đạt; các phép thử tăng số phiên bản chạy trong bản sao riêng.
- TX chưa chạy: thiếu fixture tdt/tdt_copy.dwg. Không kết luận đã kiểm tra proxy TDT hay tim TDT đang nạp module trong đợt này.

Kiểm thử dùng Core Console/profile riêng, không cài bản mới vào phiên AutoCAD đang mở. Khi thiếu DLL Palette, các lệnh Lisp trực tiếp còn dùng được, nhưng không còn hộp thoại DCL dự phòng.
