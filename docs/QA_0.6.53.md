# QA BHT 0.6.53

## Đã kiểm tra trước đóng gói

- Build C# + CoreTests: 233 PASS, 0 FAIL.
- FAS biên dịch thành công; Core/Bridge qua Obfuscar, Palette giữ nguyên chính sách hiện hành.
- Runtime bootstrap với DLL đã bảo vệ trong đường dẫn có dấu/khoảng trắng, AutoCAD 2024 Core Console cô lập:
  - Chưa có bht:api-version -> SendStringToExecute nạp FAS -> callback -> API đúng phiên bản.
  - Thiếu file cùng bộ -> FileNotFoundException có đường dẫn cụ thể.
  - File Lisp báo lỗi -> callback trả lỗi nạp.
  - API trả 0.0.1 -> xác định không tương thích, khác tình trạng thiếu Lisp.
- Palette layout/editor workflow: 683 kiểm tra đạt.
- scripts/check-version.ps1: PASS 0.6.53 / 0.6.53.0.

## Giới hạn

Chưa tái hiện phiên AutoCAD giao diện trong ảnh của người dùng; chưa kết luận nguyên nhân autoload ban đầu. Kiểm tra bootstrap chạy bằng Core Console và gọi API .NET thật, không thay DLL trong CAD đang chạy. Đổi/đóng bản vẽ và thời hạn chờ được bảo vệ bằng document/generation, dispose callback và timer; chưa kiểm thử tương tác nhiều tài liệu trong AutoCAD đầy đủ.

Kiểm tra bộ cài/roundtrip runtime thực hiện sau đóng gói, lưu log tại build/v0.6.53. Không tự sửa bản vẽ người dùng.
