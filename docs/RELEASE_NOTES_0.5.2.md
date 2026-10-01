# BHT v0.5.2 — Phông Unicode và nhập biển báo

Ngày phát hành: 01/10/2026. Bản kế tiếp v0.5.1; DLL 0.5.2.0, Lisp BHT-0.5.2.lsp.

## Đổi phông mặc định

Dùng **VNRomancUpdate.shx**, bảng mã **Unicode**. Tệp trên máy có header `AutoCAD-86 unifont 1.0`; glyph `Ê` (U+00CA), `ê` (U+00EA), `Ế` (U+1EBE), `Ệ` (U+1EC6) riêng biệt. Chuyển sang TCVN3 sẽ tạo mã glyph không có trong phông này, nên BHT giữ Unicode NFC khi vẽ. Bộ cài kèm phông mới và giữ vnromanc.shx để hỗ trợ kiểu cũ.

Khi gõ TEXT trực tiếp với BHT_TCVN hoặc BHT_BIENBAO, chọn **Unicode** trong UniKey. Tên BHT_TCVN giữ nguyên để đọc bản vẽ cũ; tên kiểu không quyết định bảng mã, tệp phông mới quyết định.

Trong bản vẽ cũ, khi BHT tạo/cập nhật nhãn, kiểu BHT_TCVN/BHT_BIENBAO tự đổi phông; TEXT hiện có của kiểu đó được giải mã TCVN3 trước khi đổi. Giữ vị trí, góc quay và dữ liệu hồ sơ. Chạy cập nhật nhãn điểm và “Chèn/Cập nhật ký hiệu” trên Palette để dựng lại nhãn từ dữ liệu Unicode gốc. Mã TCVN3 của một số chữ hoa có dấu trùng chữ thường; nhãn liên kết lấy từ hồ sơ Unicode sẽ khôi phục đúng hoa/thường. TEXT rời không có dữ liệu gốc có thể cần sửa lại các chữ này. Kiểu chữ tùy chỉnh không bị đổi phông.

## Chọn và nhập biển báo

1. Trên thẻ Hồ sơ đối tượng, bấm **Thư viện block**. Hộp thoại giữ mã đang sửa; chọn ảnh để xem bản lớn và tên/nhóm biển. Tìm bằng mã hoặc tên có dấu/không dấu, lọc theo nhóm.
2. Với **P.127**, nhập tốc độ (km/h) ở bên phải. Gợi ý lấy từ mã P.127-80 hoặc mô tả gioihan80; mã có tốc độ cụ thể được ưu tiên. Chấp nhận số nguyên 5–130, có sẵn các giá trị thường dùng. Nhấp đúp P.127 đưa con trỏ tới ô tốc độ để kiểm tra trước khi chọn. Nếu để trống, dùng mã gốc P.127 (hình TDT mặc định 50).
3. Để nhập nhiều mặt, bật **Chọn nhiều mặt trên cùng trụ**. Nhấp đúp ảnh hoặc bấm **Thêm mặt**; dùng **Bỏ mặt**, **Lên**, **Xuống** để chỉnh danh sách. Giữ cả hai tấm có cùng mã. Danh sách có sẵn trong hồ sơ được nạp vào để sửa.
4. Bấm **Chọn biển** để điền Palette. Mặt đầu là mã biển chính; danh sách và số mặt được điền khi bật chế độ nhiều mặt. Bấm **Đóng** hủy toàn bộ thay đổi trong hộp thoại. Nếu tắt chế độ nhiều mặt, chỉ đổi mã chính, giữ danh sách mặt trong hồ sơ.
5. Kiểm tra số trụ, mô tả hiện trường, điểm RTK, phía đường và ảnh thực tế rồi **Lưu**; **Chèn/Cập nhật ký hiệu** đưa biển lên CAD. Mô tả khảo sát vẫn được giữ khi thêm tên biển.

Ảnh xem trước là thumbnail TDT gốc, không đổi chữ số theo ô tốc độ; số tốc độ được áp dụng vào block khi chèn. Nhiều mặt là dữ liệu hồ sơ/thống kê; ký hiệu CAD hiện thể hiện biển chính, chưa dựng chồng mọi mặt trên một cọc. Biển biến thể phức tạp tiếp tục dùng Block tùy chỉnh và ảnh hiện trường.

## Kiểm tra

- Build Core, Bridge và Palette: thành công; 122 kiểm tra Core đạt, 0 lỗi.
- AutoCAD Core Console: 13 kiểm tra ký hiệu, 24 kiểm tra phông đạt; nhập DWG TDT thật, hatch xuống dưới, chiều cao 1.8, tốc độ 40/80.
- Kiểm tra hộp thoại: 412 mục, 292 ảnh có sẵn; lọc nhóm/tên, ảnh xem trước, tốc độ gợi ý/ghi đè/sai, thêm/sắp nhiều mặt, hủy không ghi dữ liệu đều đạt.
- Font mới: kiểm tra glyph Unicode và đo chiều cao Ê/ê bằng AutoCAD thật; Ê lớn hơn ê.
- Bộ kiểm tra dùng profile AutoCAD riêng để tránh reactor khởi động TDT.

Nghiên cứu dựa trên tài nguyên TDT 9.1 cài trên máy, xem `NGHIEN_CUU_NHAP_BIEN_TDT_9_1.md`. Phiên TDT trực tiếp bị lỗi ProjectDH.arx khi khởi động; chưa xác nhận được toàn bộ thao tác bằng giao diện TDT. Chưa cài v0.5.2 vào phiên AutoCAD của người dùng.
