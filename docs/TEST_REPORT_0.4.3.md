# Báo cáo kiểm thử BHT 0.4.3

Ngày kiểm thử: 2026-09-28  
AutoCAD Core Console: 2024 (`ACADVER=24.3`)  
Hệ Lisp: `LISPSYS=1`

## Kết quả

- Logic thuần .NET: **59 PASS, 0 FAIL**.
- Hồi quy Lisp / DWG / cầu nối .NET: **165 PASS, 0 FAIL, 1 BLOCKED**.
- Tổng kiểm thử tự động đạt: **224 PASS, 0 FAIL**.
- Mục BLOCKED là mở DCL trong AutoCAD Core Console; môi trường này không có giao diện. Cấu trúc DCL, 42 nút và hàm đích vẫn được kiểm tra tĩnh.
- Smoke test Palette WinForms: **5 tab, kích thước 420 × 820, 0 lỗi bố cục**.

## Phạm vi đã xác nhận

- Nạp Lisp 0.4.3 từ đường dẫn có dấu; 14 API `bht:api-*` đăng ký và gọi được từ .NET.
- Plugin, Lisp và assemblies cùng phiên bản 0.4.3; plugin từ chối Lisp khác phiên bản.
- 526 điểm RTK giữ nguyên tọa độ X/Y/Z; dấu X và 1.574 nhãn không di chuyển POINT.
- Block mặc định Cọc tiêu và Cột Km chứa đúng hình học/màu mới; block cũ trong bản vẽ được chuyển sang tên định nghĩa 0.4.3 khi đồng bộ.
- Nhãn ký hiệu hiển thị `Cọc tiêu Km 48+500`, không đưa ID hồ sơ nội bộ lên bản vẽ.
- Bộ đệm thông báo trả đúng tiếng Việt cho Palette và xóa sau khi đọc.
- Bốn tệp CSV có BOM UTF-8 và tiêu đề tiếng Việt có dấu.
- Mở/lưu lại bản vẽ, đọc bản vẽ BHT 0.3.2/0.3.3, ảnh TimeMark, tuyến/lý trình, thứ tự hiển thị và cầu nối C# đều qua hồi quy.
- Bộ cài phát hiện AutoCAD đang chạy và dừng trước khi thay bundle, tránh trộn DLL cũ với Lisp mới.

## Giới hạn kiểm thử

AutoCAD Core Console không thể xác nhận tương tác chuột hoặc cửa sổ DCL/Palette thật. Palette đã được dựng bằng WinForms harness với đúng DLL phát hành và kiểm tra cắt/chồng control; thao tác sử dụng cuối cùng sẽ được kiểm tra trong AutoCAD đầy đủ sau khi đóng mọi phiên AutoCAD cũ và cài 0.4.3.
