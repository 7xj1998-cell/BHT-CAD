# BHT 0.6.54

Sửa lỗi không nạp Lisp “bad argument type: stringp T”.

Nguyên nhân: AutoLISP OR trả T khi findfile tìm thấy FAS/LSP trong Support Path; hàm lấy thư mục sau đó nhận boolean thay vì chuỗi. Kiểm thử 0.6.53 trước đây chạy FAS ngoài Support Path nên bỏ sót nhánh này.

Bản mới giữ đường dẫn findfile trực tiếp, ưu tiên FAS rồi LSP. Không thay thuật toán biển, tỷ lệ, tuyến hoặc hồ sơ.

Đóng tất cả AutoCAD, cài 0.6.54, mở lại bản vẽ và gõ BTH. Tổng quan phải hiển thị “BHT Lisp 0.6.54 đã nạp”.
