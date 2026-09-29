# Giới hạn đã biết của BHT 0.4.6

## Giao diện cần nghiệm thu trong AutoCAD đầy đủ

AutoCAD Core Console không có UI nên không thể xác nhận trực quan Palette tối, thanh tab phải,
DCL và thao tác chuột. Kiểm tra tự động đã xác nhận build/NETLOAD Palette, cấu trúc DCL và đích
của 42 nút. Thực hiện `CHECKLIST_NGHIEM_THU_0.4.6.md` trên bản sao DWG.

## Điểm và nhãn

BHT giảm chồng lấn nhưng không cam kết loại bỏ toàn bộ ở vùng điểm quá dày. Có thể giảm chiều cao
chữ, chỉ hiện tên, bật ưu tiên hồ sơ hoặc dời nhãn bằng tay. Nhãn dời tay được giữ khi cập nhật.
Kiểu `BHT_RTK` chỉ được đặt mặc định ở lần nhập đầu trên bản vẽ mới; bản vẽ legacy giữ kiểu cũ.

## Tim TDTSolution 9.1

`BHTTUYENTDT` chỉ dùng với TDTSolution 9.1 bản thường đã nạp từ
`C:\Program Files (x86)\TDT Solution 2022\`. Khi tim còn là proxy `TDTDBALIGNMENT`, BHT từ chối.
BHT không gọi `vlax-curve-*` trên proxy. Luồng hỗ trợ là mở nguồn `ForRead`, `Entity.Explode`, tạo
Polyline riêng `BHT_TUYEN_TDT`, rồi tính lý trình trên Polyline BHT.

## Catalog biển báo TDT

Catalog TDT có 412 mã nhưng không phải mọi mã đều có block vector nguồn. BHT báo rõ khi thiếu và
không tự vẽ hình thay thế. Tài sản TDT không nằm trong release; chức năng này cần bản TDT hợp lệ.

## Cài đặt DLL

Phải đóng toàn bộ AutoCAD trước khi cài. AutoCAD giữ DLL đã nạp đến khi thoát; nạp Lisp 0.4.6 với
DLL phiên bản cũ có thể làm tiêu đề và chức năng không đồng bộ.
