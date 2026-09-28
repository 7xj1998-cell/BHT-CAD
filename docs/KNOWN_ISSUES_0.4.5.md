# Giới hạn đã biết của BHT 0.4.5

## Giao diện không thể kiểm thử trong Core Console

AutoCAD Core Console không có UI nên không mở được DCL và không xác nhận thao tác chuột trong Palette. Kiểm tra tự động đã xác nhận cấu trúc DCL, lệnh đích và khả năng NETLOAD Palette; phần hiển thị thực tế phải nghiệm thu theo `CHECKLIST_NGHIEM_THU_0.4.5.md`.

## Tim TDTSolution 9.1

`BHTTUYENTDT` chỉ dùng với TDTSolution 9.1 bản thường đã nạp từ `C:\Program Files (x86)\TDT Solution 2022\`. Khi tim hiện là proxy `TDTDBALIGNMENT`, BHT sẽ từ chối. BHT không gọi `vlax-curve-*` trên proxy.

Luồng được hỗ trợ là: mở nguồn `ForRead` → `Entity.Explode` → tạo/cập nhật Polyline riêng `BHT_TUYEN_TDT` → tính lý trình trên Polyline BHT. Nếu không chạy TDT, tạo một Polyline tham chiếu đã kiểm tra và dùng `BHTTUYEN`.

## Catalog biển báo TDT

Catalog TDT có 412 mã nhưng bộ cài chỉ chứa năm DWG nguồn với 329 định nghĩa vector được kiểm kê. Một số mã có tên trong catalog nhưng không có block nguồn tương ứng; BHT báo rõ và không tự vẽ hình thay thế để tránh dùng sai biển.

Tài sản TDT không nằm trong release. Máy dùng chức năng này phải có bản TDT hợp lệ đã cài. Cache giải nén nằm trong LocalAppData và không sửa thư mục cài TDT.

## Cài đặt DLL

Phải đóng toàn bộ AutoCAD trước khi cài hoặc thay DLL. AutoCAD giữ DLL đã nạp trong bộ nhớ đến khi thoát; nạp Lisp 0.4.5 cùng DLL cũ có thể làm phiên bản hiển thị không thống nhất.
