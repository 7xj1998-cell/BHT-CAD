# BHT v0.6.10 — 2026-10-04

- Tách R.415a/R.415b và W.239a/W.239b trong thư viện. W.239a hiển thị biểu tượng điện; W.239b có ô nhập chiều cao tĩnh không. Mã cũ R.415 và W.239 được hiểu là biến thể a khi cập nhật ký hiệu.
- Sửa ảnh W.239a và thay hình CAD sai của W.205c, W.207a, W.239a/b, R.415a/b bằng vector riêng. Giữ nền dưới biểu tượng; trắng trên biển dùng màu trắng cố định để in đúng.
- Biển I.439 có ô nhập tên cầu, lý trình và tên đường ngay trong bảng chọn, có ảnh xem trước theo nội dung nhập. Các giá trị được lưu cùng hồ sơ; chữ CAD vừa khung. Trong cụm nhiều mặt, các mặt I.439 dùng chung nội dung của hồ sơ.
- Cọc tiêu có tùy chọn ghi số Km và H. Ví dụ Km 39, H 9 hiển thị H9/39 nằm ngang cạnh đầu cọc. Cọc Km có tùy chọn nhập số Km và hiển thị số trong block; các cọc có số khác nhau dùng block riêng.

## Phân biệt mã biển

R.415 là tên nhóm: R.415a chỉ dẫn gộp làn theo phương tiện; R.415b báo kết thúc. Ảnh cũ có xe khách/xe con xếp trong một làn và vạch chéo đỏ là hình kết thúc làn dành riêng cho nhóm xe trong nhóm R.413, không phải mẫu R.415a. W.239a cảnh báo đường cáp điện phía trên; W.239b thể hiện chiều cao tĩnh không thực tế. Đối chiếu mục C.39, D.15 và D.16 trong [QCVN 41:2024/BGTVT](https://datafiles.chinhphu.vn/cpp/files/vbpq/2024/11/51-bgtvt-kem.pdf).

## Kiểm tra

- Core: 143 ca đạt; bảng chọn WinForms: 378 mục đều có ảnh, kiểm tra nhập/sửa/đóng bảng, biến thể mã cũ và nội dung I.439.
- AutoCAD 2024 Core Console trên bản sao 15doan: kiểm tra màu và thứ tự hatch, biểu tượng, chế độ không tô màu, giá trị chiều cao thực tế, tên cầu, số Km, H9/39 và cập nhật lặp lại. Lưu rồi mở lại giữ đủ nội dung.
- Bộ kiểm tra biển, đặt tự do, ghép nhiều mặt và chữ TCVN3 đều đạt; bộ cài đạt 7 kiểm tra trong thư mục thử riêng.
- Đã xuất bản in màu bằng bộ máy in của AutoCAD và kiểm tra hình thực tế. Công cụ chụp cửa sổ CAD không lấy được ảnh trong phiên này; nghiệm thu hình dựa trên bản in AutoCAD.
- Không sửa bản vẽ khảo sát và tài nguyên TDT gốc. Không đổi thiết lập bảo mật CAD. Các chức năng mới dùng block mặc định; block tùy chỉnh đã gán vẫn được ưu tiên.

## Cài và cập nhật

Đóng toàn bộ AutoCAD, giải nén đầy đủ BHT-0.6.10.zip, chạy INSTALL_BHT.cmd rồi mở lại CAD. Kiểm tra tiêu đề BHT hiển thị 0.6.10. Với ký hiệu đã chèn, mở hồ sơ và bấm Lưu/cập nhật ký hiệu để lấy hình mới. BHT giữ vị trí/góc đã đặt thủ công.

Trong Hồ sơ đối tượng, nhóm Cọc tiêu/Cột Km có lựa chọn **Ghi số Km trên ký hiệu**. Nhập số Km nguyên từ 0 đến 99999; cọc tiêu nhập thêm H từ 0 đến 9. Bỏ chọn để trở về ký hiệu không ghi số. Lý trình tuyến và số ghi trên cọc được lưu riêng.
