# BHT v0.5.4 — Sửa lỗi và xử lý review v0.5.3

Ngày 01/10/2026. DLL 0.5.4.0; Lisp BHT-0.5.4.lsp.

- Sửa chuẩn hóa chữ có dấu được ghép một phần, ví dụ ê + dấu sắc → ế, Â + dấu nặng → Ậ. Phông mặc định tiếp tục là VNRomancUpdate.shx Unicode; kiểu tùy chỉnh vnromanc.shx tiếp tục dùng TCVN3.
- Rút gọn hai bảng mã, giữ toàn bộ đầu vào cũ và mã riêng của các chữ hoa Ă Â Ê Ô Ơ Ư Đ.
- Dùng chung xử lý ẩn/hiện nhãn giữa BHTNHANDIEM và BHTANNHAN; giữ đủ 69 lệnh và các alias.
- Chèn biển tự do trả LOI rõ ràng khi ID nil/rỗng/không tồn tại hoặc hồ sơ thiếu điểm RTK. Đường dẫn giữ đúng thứ tự điểm trung gian sau đồng bộ.
- Bổ sung kiểm thử hồi quy và [kết quả đối chiếu từng nhận xét của Claude](REVIEW_RESOLUTION_0.5.4.md).

Build và 122 kiểm tra Core đạt. AutoCAD Core Console đạt 28 kiểm tra ký hiệu, 29 kiểm tra phông, 3 kiểm tra chèn tương tác và 4 kiểm tra menu nhãn; probe thư viện DWG và WinForms picker đạt. Công cụ kiểm tra phiên bản và chặn tái phát hành nội dung đổi dưới phiên bản cũ tiếp tục được kiểm tra.

Giải nén BHT-0.5.4.zip, đóng AutoCAD, chạy INSTALL_BHT.cmd rồi mở lại. Cách chèn hướng/điểm trung gian vẫn theo [hướng dẫn v0.5.3](RELEASE_NOTES_0.5.3.md). Bản này chưa tự cài vào AutoCAD đang mở.
