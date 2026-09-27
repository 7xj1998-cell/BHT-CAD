# Báo cáo kiểm thử BHT 0.4.2

Ngày kiểm thử: 2026-09-27. Môi trường: Windows, AutoCAD 2024, .NET Framework 4.8, `LISPSYS=1`.

## Kết quả

| Nhóm | Kết quả | Nội dung chính |
|---|---:|---|
| BHT.CoreTests | 59 PASS, 0 FAIL | mã hóa bản ghi, hồ sơ, ảnh, tìm kiếm, phiên bản, phân tích/định dạng lý trình nhập tay |
| Core Console S0/P | 17 PASS, 0 FAIL, 1 BLOCKED | nạp Lisp từ đường dẫn có dấu, 13 API, dấu X 1 đơn vị, nạp DWG thành block tùy chọn, lệnh BTH trong môi trường không UI |
| Hồi quy A/B/L/R/L2/N/N2/NL/T | 144 PASS, 0 FAIL | dữ liệu mới, DWG 0.3.2/0.3.3, lưu/mở lại, C#↔Lisp, ảnh và lưới IRT |
| WinForms layout smoke | PASS | dựng đủ 5 thẻ ở kích thước Palette 420×820; thẻ Ảnh và Hồ sơ không có điều khiển bị che, phần ảnh rỗng và ô/nút lý trình hiện đầy đủ |

Tổng kiểm thử chức năng: **220 PASS, 0 FAIL, 1 BLOCKED**, cộng một lượt kiểm tra bố cục WinForms PASS. Mục bị chặn là `load_dialog` trong AutoCAD Core Console vì Core Console không có giao diện; đây không phải lỗi của mã Lisp.

## Phạm vi đã xác nhận

- `BHT-0.4.2.lsp` giữ hợp đồng dữ liệu `BHT_V02` và đọc được bản vẽ cũ.
- Assemblies có `FileVersion=0.4.2.0`; gói không chứa DLL Autodesk.
- `PDMODE=3`, `PDSIZE=1`; bố trí lại bộ hồi quy 526 điểm còn **0/1574** nhãn chồng lấn.
- DWG ngoài được nạp thành block tùy chọn, giữ hệ số đơn vị và không để lại INSERT tạm.
- Chuỗi lý trình `Km39+050.5`, `39+050,5` và `39050.5` đều cho kết quả `Km39+050.50`; dữ liệu sai bị từ chối.
- Application Bundle khai báo Lisp 0.4.2 và ba DLL đúng phiên bản; `ProductCode` riêng cho bản này.

Kiểm thử tự động không thể xác nhận thao tác chuột, hộp chọn tệp và hình ảnh thực tế trong Palette. Bản phát hành này cần được nghiệm thu tiếp bằng dữ liệu dự án trên một bản sao DWG trước khi dùng cho bản duy nhất.
