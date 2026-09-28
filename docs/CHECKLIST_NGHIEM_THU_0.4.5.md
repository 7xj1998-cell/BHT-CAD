# Checklist nghiệm thu thủ công BHT 0.4.5

Thực hiện trên bản sao DWG. Không dùng file khảo sát gốc để nghiệm thu.

## Cài đặt và phiên bản

- [ ] Đóng toàn bộ AutoCAD, chạy `INSTALL_BHT.cmd`, mở AutoCAD 2024.
- [ ] Gõ `BTH` hoặc `BHT`; Palette mở bên trái, tiêu đề hiện **BHT 0.4.5**.
- [ ] Với cách di động, APPLOAD duy nhất `BHT-0.4.5.lsp`; dòng lệnh hiện `BHT 0.4.5 đã nạp thành công.`
- [ ] Không có Palette/Lisp của 0.4.4 hoặc bản cũ cùng nạp.

## Palette và tiếng Việt

- [ ] Năm thẻ hiển thị đủ chữ Việt, không lỗi font và không có chữ mồ côi bị cắt.
- [ ] Vùng trạng thái dưới Palette không nhận caret/con trỏ nhập.
- [ ] Thẻ **Tuyến & báo cáo** mặc định chỉ hiện sáu thao tác chính; nút **Hiện công cụ nâng cao** mở/đóng đúng.
- [ ] `BHTKT` và `BHTTRANGTHAI` mở hộp thoại báo cáo lớn; nút sao chép và đóng hoạt động.
- [ ] `BHTDCL` mở được bảng dự phòng; 42 nút không bị cắt, thao tác đóng/mở không báo lỗi.

## Điểm, nhãn và ký hiệu

- [ ] POINT RTK hiện dấu X kích thước 1 đơn vị; tâm dấu X trùng đúng tọa độ điểm.
- [ ] Chụp tọa độ một số POINT trước/sau khi sắp nhãn; X/Y/Z không đổi và không bị làm tròn.
- [ ] Nhãn điểm không đè dấu X ở cụm điểm gần nhau; nhãn dời tay được giữ sau khi cập nhật.
- [ ] Cọc tiêu/Cột Km hiển thị đúng block; nhãn dạng `Cọc tiêu Km 48+500`, không lộ ID nội bộ.
- [ ] Biển báo có leader về điểm RTK, nằm ngoài tim theo phía đường và nhãn hiển thị mã biển + lý trình.

## TDTSolution 9.1 bản thường

- [ ] Khởi động bằng profile TDTSolution 9.1 đã nạp từ `C:\Program Files (x86)\TDT Solution 2022\`.
- [ ] Thẻ Hồ sơ gợi ý mã theo dạng `Mã — Tên biển`; chọn một mã có vector và chèn đúng mặt biển TDT.
- [ ] Chọn W.225: hình vector đúng nguồn TDT, tỷ lệ mặt/cột cân đối với bản vẽ.
- [ ] Gõ `BHTTUYENTDT`, chọn tim TDT đang hoạt động; BHT tạo Polyline xanh trên layer `BHT_TUYEN_TDT`.
- [ ] Chạy lại sau khi tim thay đổi; cùng Polyline tham chiếu được cập nhật, đối tượng TDT nguồn không đổi.
- [ ] Mở bản vẽ khi TDT chưa nạp; `BHTTUYENTDT` báo rõ tim đang là proxy và không tạo tuyến sai.

## Báo cáo Excel

- [ ] Nút **Xuất báo cáo biển báo Excel** tạo được `.xlsx` và mở được bằng Excel.
- [ ] Hai sheet **Tổng hợp** và **Danh sách biển** có tiếng Việt đúng dấu.
- [ ] Các cột STT, công trình, đoạn/gói, loại/mã/tên biển, phía, lý trình, tình trạng, số trụ/mặt, trạng thái kiểm tra và ghi chú đúng dữ liệu DWG.
- [ ] Lọc theo loại biển/tình trạng và đối chiếu số lượng với Palette.

## Kết thúc

- [ ] Chạy `BHTKT`: 0 lỗi; đọc và ghi lại mọi cảnh báo còn lại.
- [ ] SAVEAS bản thử, đóng/mở lại; hồ sơ, tuyến, block, nhãn, ảnh và báo cáo vẫn đọc đúng.
- [ ] Ghi rõ AutoCAD/TDT dùng để nghiệm thu, ngày kiểm tra và các mục chưa đạt.
