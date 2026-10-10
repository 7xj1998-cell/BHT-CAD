# Thư viện ADSCivil trong BHT 0.6.31

## Phạm vi

Nguồn cục bộ: `C:\Program Files\BZS\ADSCivil NW 2026 For Autocad\TrafficSignal`. Đã đọc 469 DWG mặt biển ở thư mục gốc. Danh mục chọn biển hiển thị 467 mẫu; R.415 và W.239 là mã cũ được quy về R.415a và W.239a. Các biến thể có số, dấu phẩy, dấu gạch hoặc dấu nháy được giữ riêng.

Đã sao chép 1.630 tài nguyên: 817 DWG, 652 PNG, 145 JPG, 8 TXT, 6 XML và 2 JSON. Mỗi bản sao được đối chiếu SHA-256 với nguồn. Manifest nằm trong `SignLibrary/ADSCivil/BHT_ADS_MANIFEST.json`. Đây là bản sao phục vụ bộ cài cục bộ theo yêu cầu; không đưa tài nguyên nhà cung cấp vào Git.

817 DWG gồm mặt biển và cấu kiện/model. Danh mục BHT nạp các mặt biển thuộc nhóm P, DP, W, R, I, IE, S. Các model trụ, khung và giá đỡ được lưu trong gói; chưa chuyển thành hệ BIM/gantry ADSCivil trong BHT.

## Cơ chế nạp

`AdsSignLibrary.cs` đọc sáu danh mục TXT có BOM UTF-16 và bổ sung các DWG ngoài danh mục. BHT clone các entity sang block riêng, phục hồi DrawOrderTable ở mặt biển và các block lồng nhau. Cách nhập DWG qua Database.Insert làm mất thứ tự ở ModelSpace; nền R.415 từng che hình xe vì nguyên nhân này.

Mặt biển được chuẩn hóa cao 1,8 đơn vị CAD; biển phụ theo chiều lớn nhất. Trụ BHT cao 0,6 đơn vị, điểm chèn ở chân. Các bản màu, chỉ nét và ghép mặt dùng block riêng. S.505a có trọng lượng lấy hình xe từ ADSCivil rồi bố trí thêm số tấn trong khung BHT để giữ chức năng đã có.

Nguồn được tìm lần lượt: `BHT_ADS_ROOT` nếu được cấu hình; bản sao `SignLibrary/ADSCivil` gần DLL; thư mục ADSCivil đã cài. `BHT_SIGN_PROVIDER=TDT` hoặc `BUILTIN` dùng để kiểm tra nguồn dự phòng. `BHTTDTBLOCK` giữ tương thích với Lisp cũ; `BHTADSBLOCK` là tên API bổ sung.

P.122 cũ quy về R.122 STOP. I.428a/b/c quy về I.428. IE.456a/b/c cũ không có đối chiếu duy nhất với các biến thể ADSCivil có số; BHT dùng mặt TDT cũ nếu có, hoặc cho phép chọn mã ADSCivil cụ thể.

Tốc độ, khoảng cách, kích thước và giờ được điền vào text/attribute. I.439 giữ mặt ADSCivil và áp dụng tên cầu, lý trình, đường từ hồ sơ. Ảnh trong thư viện là PNG/JPG gốc; thông số nhập được áp dụng trong CAD. Attribute địa danh chưa có trường nhập tương ứng tiếp tục giữ giá trị mẫu gốc.

## Tài liệu cấu trúc đã nghiên cứu

- Sáu danh mục `BIEN_*.txt`: mã, tên và nhóm; có mã chứa dấu phẩy nên không thể tách CSV theo dấu phẩy đơn thuần.
- `TrafficSignalTemplate.xml`: mô tả `CDTrafficSignalTemplate` và các khóa liên kết model.
- `CAP1.xml`: 10 bố trí như một/hai trụ, hai/ba biển ngang/dọc, cụm tam giác, cổng và cần vươn.
- `traffic_default.json`: `bimModel`, `matbang`, `lstNameTraffic`, `mapAtt`. Có khóa rỗng lặp; bộ đọc JSON thông thường làm mất mục, cần giữ thứ tự cặp khóa khi phát triển bộ đọc.
- Thư mục Model và `COMPONENT_BBGT.txt`: cấu kiện và liên kết để phát triển khung/trụ theo tham số.

ARX/FAS là file đã biên dịch. Không tìm thấy mã nguồn C++ hay Lisp gốc trong thư mục đã khảo sát; nghiên cứu hiện tại dựa trên cấu hình đọc được và hình học DWG. BHT không nạp plugin ADSCivil hay chạy script của nhà cung cấp.

Hướng phát triển tiếp theo: ánh xạ các bố trí CAP1 vào trụ/khung BHT, thêm trường attribute theo nhóm biển và đối chiếu biển có địa danh với hồ sơ thực tế. Các chức năng đó chưa được triển khai trong 0.6.31.
