# BHT 0.6.44

BHT không tự dựng lại ký hiệu khi mở hoặc chuyển bản vẽ. Muốn áp dụng mẫu mới, chọn hồ sơ rồi bấm Chèn / cập nhật.

Tệp crash ngày 10/10/2026 ghi ngoại lệ 0xc0000005 tại acdb24.dll + 0x89470, tên hàm xuất AcDbImpLock::slowIsMyLock. Quét địa chỉ trên stack có generateQueuedGraphics và transactionManager; đây không phải stack đã giải mã đầy đủ và chưa chứng minh BHT là nguyên nhân duy nhất.

Bản trước đăng ký Idle để tự cập nhật ký hiệu sau khi đổi phiên bản. Bản này bỏ đường chạy đó, giữ cập nhật theo thao tác người dùng và bản sửa chữ S.509a.

Đóng phiên CAD đang lỗi, cài bản mới rồi mở lại CAD. Nếu CAD đưa ra phục hồi bản vẽ, lưu bản phục hồi thành một tệp khác trước khi tiếp tục. Bộ cài không thay DLL đang chạy trong phiên CAD cũ.
