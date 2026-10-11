# Checklist nghiệm thu Mốc 1 — AutoCAD 2024

Chỉ đánh dấu đạt khi có log/biên bản. Core Console không thay thế nghiệm thu giao diện hoặc máy sạch.

| Hạng mục | Trạng thái | Bằng chứng/còn thiếu |
|---|---|---|
| Release công khai, bộ cài, ZIP, checksum | Chưa đạt | Cần gói không chứa tài nguyên vendor; Releases mới nhất 0.6.13 |
| FAS trong/ngoài Support Path, đường dẫn có dấu | Đạt ở Core Console | docs/QA_0.6.54.md |
| Cài máy sạch, mở Palette thật | Chưa chạy | Chưa có môi trường sạch được xác nhận |
| Chuyển 3 bản vẽ, đóng khi nạp, hủy LOAD | Chưa chạy đủ | Cần biên bản CAD giao diện |
| Lưu/mở lại đủ loại đối tượng | Một phần | Runtime test có biển; cần đủ nhóm còn lại |
| Thiếu FAS, LOAD lỗi, mismatch | Đạt ở bootstrap Core Console | run_bootstrap653.ps1; chưa đủ tình huống UI/thiếu DLL |
| AutoCAD 2024 | Đã chạy Core Console | Không suy ra các bản CAD khác |
| CoreTests | 233 đạt ở 0.6.54 | Phải chạy lại cho bản phát hành tiếp |
| Người khác cài và dùng | Chưa chạy | Chờ người nghiệm thu độc lập |
| GPL-3.0-only | Đã chốt | LICENSE và COPYING_SCOPE.md |
| Sai số/tốc độ | Đã chốt tiêu chí | ROADMAP.md; đo ở Mốc 2 |

Mốc 1 chưa hoàn tất. Không chuyển mốc khi các điều kiện bắt buộc chưa đạt.
