# BHT 0.6.5 — ghi chú bàn giao

Bản này phát triển tiếp từ v0.6.3, tăng thành v0.6.5 vì v0.6.4 đã được dùng cho gói MSI/VLX trước đó. Gói hiện tại dùng loader Lisp, 12 module, ba DLL và trình cài Application Bundle.

## Cách thao tác

- Hồ sơ đối tượng chia thành: thông tin hồ sơ → ký hiệu CAD → vị trí/ảnh hiện trường.
- “Chèn/Cập nhật ký hiệu” lưu những trường đang sửa trước khi vẽ. Với một trụ hai tấm, nhập hai mã ở “Các mặt biển”; thứ tự đầu là biển trên. Lặp cùng mã vẫn tạo hai tấm. Nếu chỉ tăng số mặt, chương trình lặp mặt chính cho đủ số tấm, tối đa 20.
- “Đặt tự do…” mở bảng riêng, áp dụng mọi nhóm. Chọn đường dẫn thẳng/gấp khúc/chọn điểm trung gian, hướng theo tuyến/chọn CAD/nhập góc. Chọn các góc trung gian rồi Enter, chọn vị trí cuối; Esc hủy. Góc nhập là WCS; góc chọn trên CAD được đổi từ UCS sang WCS.
- Cọc tiêu: chân đuôi có ô trắng là điểm chèn; đầu đỏ hướng theo block, nhãn đặt trên đầu và quay theo block. Dữ liệu RTK giữ nguyên.
- Giá trị mét: chọn biển rồi sửa “Giá trị thực tế (m)” trong thư viện. Các mã hỗ trợ: S.501, S.502, S.509a, P.117–P.120. Ví dụ: S.509a@4.5, S.502@150. Số trên ảnh chỉ là mẫu; CAD dùng số đã nhập.
- Ảnh có đủ cho 376 mã hợp lệ của danh mục TDT đã kiểm tra. Bỏ 36 tiêu đề/mục trùng của XML cũ khỏi bảng chọn. Ảnh bổ sung nằm trong Images và Contents/Images, không cần TDT để đọc các ảnh này.
- Máy không có TDT dùng 19 biển nội bộ; S.501, S.502, S.509a và P.119 vẫn đổi được giá trị mét. Các hình khác cần nguồn vector TDT hoặc block tùy chỉnh. Không thay giá trị mét chưa hỗ trợ bằng số mặc định.
- Bỏ các lệnh nâng cấp BHTNANGCAP, BHTVEMODEL và BHTROUTE đời cũ. Dùng BHTTUYEN và các lệnh tuyến hiện hành.

## Kiểm chứng

- Core: 132 ca đạt.
- AutoCAD Core Console: cụm hai mặt, mặt lặp, thứ tự, số mét và số bị tách đoạn, Hatch/outline, gốc/nhãn cọc tiêu, đặt tự do cho nhóm khác, tọa độ UCS, hủy và đồng bộ lặp đều đạt.
- WinForms: 376/376 ảnh thật; tìm kiếm/lọc nhóm, chọn nhiều mặt, sửa mét, xác thực góc và hộp đặt tự do đạt. Khi tắt TDT: 19/19 ảnh và biển nội bộ đạt.
- REVIEW 10, S0 20, V5 21 ca đạt; kiểm tra bộ cài 7 ca đạt.
- Đã mở AutoCAD 2024 GUI với bản vẽ thử riêng, đọc được Palette/Lisp/DLL v0.6.5. Chưa xác minh chuỗi thao tác chuột thực tế: công cụ chụp cửa sổ báo timeout, các chỉ mục tab không điều khiển được. Không tính lần mở này là kiểm thử tương tác GUI hoàn chỉnh.
- TX chưa chạy vì thiếu bản vẽ thử chứa proxy TDT. Không sửa bản vẽ dự án thật.

## Cài đặt

Đóng CAD, giải nén đầy đủ BHT-0.6.5.zip, chạy INSTALL_BHT.cmd. Mở CAD, gõ BTH/BHT. Không chồng DLL mới vào phiên CAD đang nạp DLL cũ.
