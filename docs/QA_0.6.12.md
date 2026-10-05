# QA 0.6.12 — 05/10/2026

- Phạm vi: bỏ ba ô nhập nội dung I.439 trùng ở hồ sơ; giữ chuỗi Unicode đã lưu và tiếp tục sửa thông qua Thư viện biển. Không đổi thuật toán tính lý trình hay tự dựng tim.
- Build csc/.NET Framework 4.8 x64 với AutoCAD 2024: đạt; CoreTests 154 PASS, 0 FAIL.
- PickerProbe: 378 ảnh có thật, 0 thiếu; chọn/lọc/tốc độ/mét/nhiều mặt/I.439/kiểm tra đầu vào/hủy đạt.
- PaletteEditorProbe chạy trong AutoCAD Core Console: dựng BhtPaletteControl thật, không còn ba dòng nhập trùng, EditorFields giữ Cầu Nước Mục/Km38+580/ĐT.830; đạt. Probe standalone ngoài AutoCAD không dùng làm kết luận vì Dispose gọi thành phần native không hỗ trợ ngoài host.
- run_sign0611.ps1 (loader theo VERSION): đạt trên bản sao BHT/Ho so/15doan.dwg. 39 kiểm tra native, SIGN0610-FAIL=0, SIGN0611-FINAL-FAIL=0, DWG/PDF tạo thành công, source copy không đổi hash.
- Stage cuối: build/qa0611-835240fca9494e3bbb56659ec1e25daa; probe.txt-palette.txt ghi PASS.
- Kết quả dữ liệu thực tế đã kiểm tra trước thay đổi: 17 hồ sơ/790 điểm/334 ảnh; cập nhật ký hiệu, xuất CSV, lưu/mở lại giữ toàn vẹn. Thay đổi 0.6.12 chỉ chuyển bộ đệm nội dung biển từ TextBox sang chuỗi, đã kiểm tra bảo toàn tại EditorFields.
- Giới hạn: MCP báo Drawing1.dwg trống; không chỉnh phiên này. Cây giao diện xác nhận phiên người dùng 15doan.dwg vẫn có Palette 0.6.11. Không xác nhận test click/Palette trực tiếp qua MCP, không mở thêm phiên GUI và không thay đổi thiết lập bảo mật.