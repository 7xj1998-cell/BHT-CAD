# BHT 0.6.13

Sửa tỷ lệ biển phụ khi ghép cùng trụ: biển ngang giữ tỷ lệ gốc và không còn bị ép bằng chiều cao biển chính. Hatch gạch chéo đỏ ở P.106c/R.404d nằm trên biểu tượng; nền trắng và chữ đen của biển TDT giữ màu khi in.

I.401/I.402 có nền trắng, viền đen. Bổ sung mẫu CAD IE.473 với nội dung GIẢM TỐC ĐỘ / SLOW DOWN. Trong Thư viện biển, R.E.9b/R.E.10b có ô nhập giờ áp dụng riêng theo HH:mm-HH:mm, hỗ trợ khoảng giờ qua đêm và lưu giờ theo từng mặt biển.

Đã đạt 159 kiểm tra lõi, 23 kiểm tra mới trong AutoCAD Core Console và bộ hồi quy biển/cọc/Palette trên bản sao 15doan.dwg. Đã xem bản in thử cho tỷ lệ biển phụ, hatch, viền I.401 và giờ ZONE.

Test trực tiếp phiên AutoCAD đang mở qua MCP chưa hoàn tất: phiên bị khóa khi nạp/chạy DLL và chưa có báo cáo test. Rà 414 mục thư viện TDT nhập được 317 mục; 97 mục còn thiếu nguồn CAD. Không coi các mục thiếu là đã đạt kiểm tra hình vẽ.

**Cài đặt:** lưu bản vẽ cần giữ, đóng AutoCAD, giải nén BHT-0.6.13.zip và chạy INSTALL_BHT.cmd. Mở lại AutoCAD để dùng DLL mới; không NETLOAD đè trong phiên đã nạp BHT cũ. Phiên bản hiện ở tiêu đề Palette phải là 0.6.13.

**Test đề nghị:** W.225 + S.501 (500 m), P.106c, R.404d, I.401, IE.473 và hai biển ZONE với giờ tự nhập. Cọc Km/H và nội dung cầu I.439 giữ các sửa của bản trước.
