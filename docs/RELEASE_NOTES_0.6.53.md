# BHT 0.6.53

Sửa trường hợp Palette báo “Plugin / Lisp không cùng phiên bản” khi chưa gọi được Lisp.

BHT thử nạp FAS đúng phiên bản cạnh DLL sau khi CAD rảnh, rồi kiểm tra phiên bản/API. File thiếu hoặc lỗi nạp được báo riêng ở thanh trạng thái; F2 có thông tin dòng lệnh. Không tự nạp đè khi API báo rõ phiên bản khác.

Đóng tất cả AutoCAD, chạy bộ cài 0.6.53, mở lại bản vẽ và gõ BTH. Nếu CAD đang có lệnh, hoàn tất hoặc Esc trước khi kiểm tra. Nếu nạp bị hủy, mở lại bảng BHT để thử lại.

Không tự cập nhật hình học hoặc tỷ lệ biển khi mở bảng. Chưa xác định được nguyên nhân autoload không chạy trong phiên CAD đã chụp ảnh; sửa cơ chế phục hồi và thông báo từ tình trạng đó.
