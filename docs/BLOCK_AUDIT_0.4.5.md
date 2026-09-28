# Rà soát block và thư viện TDT — BHT 0.4.5

Ngày rà soát: 2026-09-29

## Nguồn được dùng

- TDTSolution 9.1 bản thường: `C:\Program Files (x86)\TDT Solution 2022\`.
- Catalog: `Data\Bien bao\Bienbao.xml` và `bienbao.set`.
- Module nhận diện: `AlignmentDb.dbx`, `RoadSignsUI.arx`.
- Không dùng TDT 9.1 Pro và không sửa file trong thư mục cài đặt.

## Kết quả kiểm kê

- Catalog đọc được **412 mã biển** kèm mô tả.
- Gói cài có **5 DWG nguồn**: biển cấm, nguy hiểm, hiệu lệnh, chỉ dẫn và biển phụ.
- Năm DWG chứa **329 định nghĩa vector** đã biết. Mã chỉ có trong catalog nhưng thiếu vector nguồn không được BHT tự vẽ giả.
- `TdtSignLibrary` chỉ clone block được chọn vào DWG hiện hành. Dữ liệu giải nén được lưu trong cache LocalAppData; release BHT không chứa DWG/block có bản quyền của TDT.

## Quy tắc hiển thị BHT

- Wrapper có tên `BHT_TDT_<MA>` để tránh đụng tên block nguồn.
- Mặt biển dùng scale `0.2`; cột cao `0.6` đơn vị.
- Điểm RTK giữ nguyên tại tọa độ khảo sát. Biển được đặt lệch ra ngoài tim theo phía tuyến và nối leader về điểm RTK.
- Nhãn chỉ thể hiện mã biển và lý trình. ID hồ sơ được giữ trong XData để tra cứu.
- Block Cọc tiêu/Cột Km và thư viện Lisp tích hợp tiếp tục là nguồn dự phòng cho nhóm không dùng TDT hoặc mẫu riêng.

## Bằng chứng kiểm thử

Phiên D trên AutoCAD Core Console đạt **7 PASS, 0 FAIL**: phát hiện đúng bản TDT thường, đọc 412 mã, clone W.225, kiểm scale/cột, nạp lại không trùng và từ chối Polyline thường trong `BHTTUYENTDT`.
