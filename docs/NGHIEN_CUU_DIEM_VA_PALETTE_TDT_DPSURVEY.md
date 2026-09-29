# Nghiên cứu trình bày điểm và palette TDT 9.1 / DPSurvey

## Phạm vi

Nghiên cứu chỉ đọc trên các bản cài hợp lệ của người dùng:

- TDTSolution 9.1 bản thường: `C:\Program Files (x86)\TDT Solution 2022\`.
- DPSurvey 3.3: `C:\Program Files (x86)\DPSurvey\`.

Không sửa, chép đè hoặc nạp lại tệp trong hai thư mục cài đặt. Không đọc hình học
`TDTDBALIGNMENT` bằng `vlax-curve`. Điểm RTK trong DWG không bị di chuyển hoặc làm tròn.

## Điều rút ra từ TDT 9.1

- `Data\iniSymbol.cfg` lưu `Symbol ScaleX=1`, `Symbol ScaleY=1`, `Symbol Rotate=0`:
  ký hiệu gốc giữ tỷ lệ 1:1, tỷ lệ trình bày được xử lý riêng khi chèn.
- Cấu hình cũng tách `TextHei` và `DeltaY`; dữ liệu điểm và cách trình bày chữ là hai lớp riêng.
- Thư viện điểm có các mẫu theo tỷ lệ 1/500, 1/1000, 1/2000 và 1/5000. BHT không sao chép
  các mẫu đó vào dữ liệu RTK; dấu X vẫn có tâm đúng DXF 10 và kích thước tuyệt đối 1 unit.

## Điều rút ra từ DPSurvey

Các lớp `ClsSurveyPoint`, `PointSurvey`, `PropertiesSurveyPoint` và màn hình `frmRaidiem`
cho thấy một kiểu điểm gồm các thuộc tính độc lập:

- kích thước điểm đo;
- cao và rộng chữ;
- khoảng cách chữ với điểm;
- góc nghiêng và khóa góc quay;
- màu chữ;
- bật/tắt tên điểm, mã điểm và cao độ.

Điểm mạnh cần áp dụng cho BHT là coi tên, mô tả và cao độ là **một cụm nhãn** có cùng
điểm neo. Khi né va chạm, cả cụm di chuyển cùng nhau; không rải ba dòng riêng lẻ.

## Phương án đã áp dụng

1. Bản vẽ mới, ở lần nhập RTK đầu tiên, lưu rõ kiểu chữ `BHT_RTK` (Arial, width factor 0,85).
   Chữ gọn hơn ở cụm điểm dày nhưng vẫn dùng Unicode tiếng Việt.
2. Bản vẽ cũ không có khóa kiểu chữ tiếp tục dùng `BHT_ARIAL`. Cập nhật phần mềm không làm
   nhãn legacy đổi font hoặc đổi vị trí.
3. Mỗi điểm vẫn dùng một hộp bao cho toàn bộ cụm tên–mô tả–cao độ; khoảng dòng an toàn 1,5H
   và 64 vị trí ứng viên được giữ vì kiểm thử legacy cho kết quả ổn định hơn cấu hình quá chặt.
4. Palette dùng nền than, mặt điều khiển xanh đen, chữ thao tác vàng chanh và thông tin phụ
   xanh cyan. Thanh chọn `Tổng quan / RTK / Ảnh / Hồ sơ / Tuyến` chuyển sang cạnh phải,
   đúng bố cục palette hẹp trong ảnh tham chiếu.

## Kết quả kiểm thử liên quan

- Build x64 với AutoCAD 2024: `BHT.Core`, `BHT.Bridge` và `BHT.Palette` đều biên dịch thành công.
- Core tests: **62 PASS, 0 FAIL**.
- Integration trên AutoCAD Core Console: **172 PASS, 0 FAIL, 1 BLOCKED**. Mục BLOCKED là mở DCL
  do Core Console không có giao diện; cấu trúc DCL và đích của 42 nút vẫn được kiểm tra tĩnh.
- Bản vẽ mới 526 điểm: 1.574 nhãn được tạo, tọa độ X/Y/Z giữ nguyên; 28 nhãn còn va chạm
  sau tự động so với 620 nhãn ở vị trí legacy.
- Lưới dày 60 điểm: 21/160 nhãn còn va chạm so với 160/160 ở vị trí legacy.
- Bản vẽ BHT 0.3.2: 11/11 kiểm thử nâng cấp PASS; nhãn cũ không bị dời ở lần cập nhật đầu.
- Core Console không hiển thị WinForms/DCL. Màu sắc, tab phải, co giãn chiều rộng và thao tác
  chuột cần được nghiệm thu trong AutoCAD đầy đủ.

## Checklist nghiệm thu giao diện

- Mở `BTH`; năm tab nằm thành thanh dọc sát mép phải, chữ không bị cắt.
- Thu hẹp và kéo rộng palette; nội dung không chui dưới thanh tab.
- Kiểm tra nền tối, chữ nhập màu sáng, nút hành động vàng và trạng thái lỗi/cảnh báo dễ đọc.
- Ở thẻ RTK, chạy **Dấu X 1u + sắp nhãn** trên bản sao DWG; dấu X vẫn đúng tâm và nhãn
  không che các điểm lân cận.
- Mở một DWG 0.3.2/0.4.5: nhãn đã dời tay và nhãn legacy giữ nguyên sau **Cập nhật nhãn**.
