# QA 0.6.55 — Mốc 1 đang thực hiện

## Đã chạy trước đóng gói

- Build Core/Bridge/Palette; 233 CoreTests đạt.
- Build công khai không nhúng preview; 233 CoreTests đạt.
- Parse toàn bộ PowerShell trong scripts và tests tích hợp/phát hành: đạt.
- Kiểm tra chuẩn hóa RELEASE_STATE: version 0.6.54 và contentHash giữ nguyên; chỉ đường dẫn thành tên tệp.
- Rà tests/IntegrationTests *.ps1/*.lsp: không còn đường dẫn C:/Users/Le Bao hoặc C:\Users\Le Bao.

## Kiểm tra sau đóng gói

Chạy tests/ReleaseTests/public-runtime.ps1 và single-file-installer.ps1 trên gói cuối; log tại build/v0.6.55. Không coi riêng kết quả Core là nghiệm thu đầy đủ.

## Chưa chạy / giới hạn

- Các phiên fixture lịch sử sau đổi biến môi trường chưa chạy lại đầy đủ; thiếu bộ dữ liệu chuẩn được bàn giao độc lập.
- Chưa kiểm thử máy sạch, người dùng độc lập, chuyển 3 bản vẽ/hủy LOAD trong CAD giao diện.
- Public-runtime chỉ kiểm tra nạp, hồ sơ biển và tọa độ điểm qua lưu/mở; chưa đủ các loại cọc/đèn/tuyến/mốc.
- Chưa đo 100/1.000/5.000 điểm theo tiêu chí mới; thuộc Mốc 2.
- Chưa xác minh các phiên bản AutoCAD ngoài 2024.
- Tài liệu cũ chưa chuyển toàn bộ vào archive vì cần cập nhật các liên kết trước.
